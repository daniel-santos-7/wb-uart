----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_tx
-- description: UART transmitter
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_tx is
    generic (
        DATA_WIDTH : natural := 8 -- UART data word size (5 to 8 bits)
    );
    port (
        clk_i      : in  std_logic; -- System clock
        rst_i      : in  std_logic; -- Synchronous reset (active high)
        valid_i    : in  std_logic; -- Input data is valid (handshake)
        data_i     : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Data word to transmit
        baud_div_i : in  std_logic_vector(15 downto 0); -- Baud rate divider value
        tx_o       : out std_logic; -- Serial output line
        busy_o     : out std_logic; -- High during active transmission
        ready_o    : out std_logic  -- Ready to accept new data from core
    );
end entity uart_tx;

architecture rtl of uart_tx is

    type state is (TX_IDLE, TX_READ, TX_START, TX_DATA, TX_STOP);

    signal state_reg : state; -- FSM current state

    signal baud_cnt_en_reg : std_logic; -- Baud rate counter enable
    signal tx_data_en_reg  : std_logic; -- Data bit counter enable
    signal ready_reg       : std_logic; -- Internal ready flag
    signal tx_reg          : std_logic; -- Registered serial output

    signal baud_cnt_reg : unsigned(15 downto 0); -- Clock cycle counter for bit timing
    signal tx_cnt_reg   : integer range 0 to DATA_WIDTH-1; -- Transmitted bit counter

    signal data_reg : std_logic_vector(DATA_WIDTH-1 downto 0); -- Transmit shift register

    signal baud_cnt_done : std_logic; -- High when one bit period has elapsed
    signal tx_cnt_done   : std_logic; -- High when all data bits are transmitted

begin

    ----------------------- Control Logic (FSM) --------------------------

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state_reg       <= TX_IDLE;
                ready_reg       <= '1';
                tx_reg          <= '1';
                baud_cnt_en_reg <= '0';
                tx_data_en_reg  <= '0';
            else
                case state_reg is
                    when TX_IDLE =>
                        if valid_i = '1' then
                            state_reg <= TX_READ;
                            ready_reg <= '0';
                        end if;

                    when TX_READ => -- Single cycle to capture data and setup start bit
                        state_reg       <= TX_START;
                        tx_reg          <= '0'; -- Start bit
                        baud_cnt_en_reg <= '1';

                    when TX_START =>
                        if baud_cnt_done = '1' then
                            state_reg      <= TX_DATA;
                            tx_reg         <= data_reg(0); -- First data bit (LSB)
                            tx_data_en_reg <= '1';
                        end if;

                    when TX_DATA =>
                        if baud_cnt_done = '1' then
                            if tx_cnt_done = '1' then
                                state_reg      <= TX_STOP;
                                tx_reg         <= '1'; -- Stop bit
                                tx_data_en_reg <= '0';
                            else
                                tx_reg <= data_reg(0); -- Next data bit
                            end if;
                        end if;

                    when TX_STOP =>
                        if baud_cnt_done = '1' then
                            state_reg       <= TX_IDLE;
                            ready_reg       <= '1';
                            tx_reg          <= '1';
                            baud_cnt_en_reg <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;

    ----------------------- Datapath Logic -----------------------------

    -- Baud rate timing counter
    baud_cnt_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                baud_cnt_reg <= (others => '0');
            elsif baud_cnt_en_reg = '1' then
                if baud_cnt_done = '1' then
                    baud_cnt_reg <= (others => '0');
                else
                    baud_cnt_reg <= (baud_cnt_reg + 1);
                end if;
            end if;
        end if;
    end process baud_cnt_proc;

    baud_cnt_done <= '1' when baud_cnt_reg = (unsigned(baud_div_i) - 1) else '0';

    -- Data bit counter
    tx_cnt_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                tx_cnt_reg <= 0;
            elsif baud_cnt_done = '1' and tx_data_en_reg = '1' then
                if tx_cnt_done = '1' then
                    tx_cnt_reg <= 0;
                else
                    tx_cnt_reg <= tx_cnt_reg + 1;
                end if;
            end if;
        end if;
    end process tx_cnt_proc;

    tx_cnt_done <= '1' when tx_cnt_reg = DATA_WIDTH-1 else '0';

    -- Parallel to Serial shift register
    data_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                data_reg <= (others => '0');
            elsif valid_i = '1' and ready_reg = '1' then
                data_reg <= data_i;
            elsif baud_cnt_done = '1' and (tx_data_en_reg = '1' or state_reg = TX_START) then
                data_reg <= '0' & data_reg(DATA_WIDTH-1 downto 1); -- Shift right (LSB first)
            end if;
        end if;
    end process data_reg_proc;

    ------------------------------ Outputs ------------------------------

    tx_o    <= tx_reg;
    busy_o  <= baud_cnt_en_reg;
    ready_o <= ready_reg;

end architecture rtl;
