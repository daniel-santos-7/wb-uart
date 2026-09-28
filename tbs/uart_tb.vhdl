----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_tb
-- description: system-level testbench
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;
use work.uart_tb_pkg.all;

entity uart_tb is
    generic (
        DATA_WIDTH : positive := 8
    );
end entity uart_tb;

architecture tb of uart_tb is

    signal clk_i : std_logic;
    signal rst_i : std_logic;

    signal wb_bus : wishbone_bus_t;

    signal rx_i : std_logic;
    signal tx_o : std_logic;

    signal clk_en : std_logic := '0';

    signal tx_off_req : std_logic := '0'; -- uart_rx_proc asks test_proc to write BRDV = 0

    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);

    constant test_data : byte_array := (
        x"AA",
        x"55",
        x"CA",
        x"FE"
    );

    -- Test bytes truncated or zero-extended to DATA_WIDTH
    function to_word (b : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(unsigned(b), DATA_WIDTH));
    end function to_word;

    -- Same word as seen on the 32-bit Wishbone data bus
    function to_bus (b : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(unsigned(to_word(b)), 32));
    end function to_bus;

begin

    ----------------------- Unit Under Test ----------------------------

    uut_inst: entity work.uart_wbsl generic map (
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i   => clk_i,
        rst_i   => rst_i,
        dat_i   => wb_bus.dat_o,
        cyc_i   => wb_bus.cyc_o,
        stb_i   => wb_bus.stb_o,
        we_i    => wb_bus.we_o,
        sel_i   => wb_bus.sel_o,
        adr_i   => wb_bus.adr_o,
        rx_i    => rx_i,
        ack_o   => wb_bus.ack_i,
        stall_o => wb_bus.stall_i,
        dat_o   => wb_bus.dat_i,
        tx_o    => tx_o
    );

    ----------------------- Clock Generation ---------------------------

    clk_i <= not clk_i after (CLK_PERIOD/2) when clk_en = '1' else '0';

    ----------------------- Stimulus Processes -------------------------

    uart_rx_proc: process
    begin
        clk_en <= '1';
        -- Written while BRDV = 0, sent once BRDV is configured (issue #3)
        uart_expect(tx_o, to_word(x"5A"));
        -- First frame keeps the old rate; BRDV is lowered mid-frame (issue #2)
        uart_expect(tx_o, to_word(test_data(0)));
        uart_expect(tx_o, to_word(test_data(1)), UART_230400_BAUD_RATE_PERIOD);
        -- BRDV = 0 written during this frame: it completes, then TX stays off (issue #3)
        tx_off_req <= '1';
        uart_expect(tx_o, to_word(test_data(2)), UART_230400_BAUD_RATE_PERIOD);
        wait for 20 * UART_230400_BAUD_RATE_PERIOD;
        if tx_o'stable(20 * UART_230400_BAUD_RATE_PERIOD) then
            report "tx_off check PASSED: line idle" severity note;
        else
            report "tx_off check FAILED: frame sent while BRDV = 0" severity error;
        end if;
        wait for 10 * CLK_PERIOD;
        clk_en <= '0';
        wait;
    end process uart_rx_proc;

    test_proc: process
        variable wb_data : std_logic_vector(31 downto 0) := (others => '0');
    begin
        rst_i <= '1';

        wb_init(wb_bus);
        rx_i <= '1';

        wait until rising_edge(clk_i);
        rst_i <= '0';

        -- Initial reads
        wb_read(b"00", wb_data, clk_i, wb_bus);
        wb_read(b"01", wb_data, clk_i, wb_bus);
        wb_read(b"10", wb_data, clk_i, wb_bus);
        wb_read(b"11", wb_data, clk_i, wb_bus);

        -- BRDV resets to 0: RX and TX off, the line is ignored and TX data stays queued (issue #3)
        wb_check(b"10", x"00000000", clk_i, wb_bus);

        -- BRDV = 1: a one-cycle glitch on the line is rejected in one cycle, RX does not hang (issue #3)
        wb_write(b"10", x"00000001", clk_i, wb_bus);
        rx_i <= '0';
        wait for CLK_PERIOD;
        rx_i <= '1';
        wait for 10 * CLK_PERIOD;
        wb_check(b"00", x"00000030", clk_i, wb_bus); -- TX_READY, RX_READY, nothing busy

        -- Byte enables: unselected BRDV bytes keep their value (issue #7)
        wb_write(b"10", x"00001234", clk_i, wb_bus);
        wb_write(b"10", x"FFFFABCD", clk_i, wb_bus, "0010");
        wb_check(b"10", x"0000AB34", clk_i, wb_bus);
        wb_write(b"10", x"00000000", clk_i, wb_bus, "0010");
        wb_check(b"10", x"00000034", clk_i, wb_bus);
        -- Merged value is 0 while dat_i is not: RX and TX must turn off (checked below)
        wb_write(b"10", x"0000FF00", clk_i, wb_bus, "0001");
        wb_check(b"10", x"00000000", clk_i, wb_bus);
        -- TXRX write without sel(0) is ignored: nothing is queued
        wb_write(b"11", x"000000EE", clk_i, wb_bus, "1110");
        wb_check(b"00", x"00000030", clk_i, wb_bus); -- TX_READY, RX_READY, TX FIFO empty
        -- Wider words need every lane they cover: a partial write is ignored
        if DATA_WIDTH > 8 then
            wb_write(b"11", x"0000FFEE", clk_i, wb_bus, "0001");
            wb_check(b"00", x"00000030", clk_i, wb_bus);
        end if;

        uart_transmit(rx_i, to_word(x"A5"));
        wb_write(b"11", to_bus(x"5A"), clk_i, wb_bus);
        wait for 100 * CLK_PERIOD;
        wb_check(b"00", x"00000038", clk_i, wb_bus); -- TX_READY, RX_READY, TX_VALID

        -- Setup baud rate
        wb_write(b"10", std_logic_vector(UART_115200_BAUD_RATE_DIVIDER), clk_i, wb_bus);

        -- Transmit data to UART line
        for i in test_data'range loop
            uart_transmit(rx_i, to_word(test_data(i)));
        end loop;

        -- Check received data via Wishbone
        for i in test_data'range loop
            wb_check(b"11", to_bus(test_data(i)), clk_i, wb_bus);
        end loop;

        -- Write data via Wishbone (to be checked by uart_rx_proc)
        for i in test_data'range loop
            wb_write(b"11", to_bus(test_data(i)), clk_i, wb_bus);
        end loop;

        -- Lower BRDV while the first frame is in progress (baud counter above the new divider)
        wait for 300 * CLK_PERIOD;
        wb_write(b"10", std_logic_vector(UART_230400_BAUD_RATE_DIVIDER), clk_i, wb_bus);

        -- Turn TX off in the middle of the third frame; the fourth byte stays queued
        wait until tx_off_req = '1';
        wait until tx_o = '0';
        wait for 50 * CLK_PERIOD;
        wb_write(b"10", x"00000000", clk_i, wb_bus);
        wait for (DATA_WIDTH + 4) * UART_230400_BAUD_RATE_PERIOD; -- Rest of the frame plus margin
        wb_check(b"00", x"00000038", clk_i, wb_bus); -- TX_READY, RX_READY, TX_VALID

        wait;
    end process test_proc;

end architecture tb;
