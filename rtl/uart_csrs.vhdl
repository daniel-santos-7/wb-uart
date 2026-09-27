----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_csrs
-- description: Control and Status Registers (CSRs) with Wishbone interface
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart_csrs is
    generic (
        DATA_WIDTH : positive := 8
    );
    port (
        clk_i   : in  std_logic;
        rst_i   : in  std_logic;

        -- Wishbone B4 pipelined slave
        cyc_i   : in  std_logic;
        stb_i   : in  std_logic;
        we_i    : in  std_logic;
        sel_i   : in  std_logic_vector(3 downto 0); -- Honored on BRDV and TXRX writes
        adr_i   : in  std_logic_vector(1 downto 0);
        dat_i   : in  std_logic_vector(31 downto 0);
        dat_o   : out std_logic_vector(31 downto 0);
        ack_o   : out std_logic;
        stall_o : out std_logic;

        -- Core configuration
        baud_div_o : out std_logic_vector(UART_BAUD_WIDTH-1 downto 0);
        en_o       : out std_logic; -- '0' while BRDV = 0

        -- Core status
        tx_ready_i : in  std_logic;
        rx_ready_i : in  std_logic;
        tx_valid_i : in  std_logic;
        rx_valid_i : in  std_logic;
        tx_busy_i  : in  std_logic;
        rx_busy_i  : in  std_logic;

        -- FIFO access
        tx_valid_o : out std_logic; -- TX FIFO push
        tx_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        rx_ready_o : out std_logic; -- RX FIFO pop
        rx_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity uart_csrs;

architecture rtl of uart_csrs is

    signal baud_div_reg : std_logic_vector(UART_BAUD_WIDTH-1 downto 0);

    signal rd_en : std_logic;
    signal wr_en : std_logic;

    signal status  : std_logic_vector(5 downto 0);
    signal ack_reg : std_logic;
    signal dat_reg : std_logic_vector(31 downto 0);

begin

    rd_en <= stb_i and cyc_i and not we_i;
    wr_en <= stb_i and cyc_i and we_i;

    baud_div_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                baud_div_reg <= BRDV_OFF;
            elsif wr_en = '1' and adr_i = ADDR_BRDV then
                if sel_i(0) = '1' then
                    baud_div_reg(7 downto 0) <= dat_i(7 downto 0);
                end if;
                if sel_i(1) = '1' then
                    baud_div_reg(UART_BAUD_WIDTH-1 downto 8) <= dat_i(UART_BAUD_WIDTH-1 downto 8);
                end if;
            end if;
        end if;
    end process baud_div_proc;

    status(STAT_TX_READY_BIT) <= tx_ready_i;
    status(STAT_RX_READY_BIT) <= rx_ready_i;
    status(STAT_TX_VALID_BIT) <= tx_valid_i;
    status(STAT_RX_VALID_BIT) <= rx_valid_i;
    status(STAT_TX_BUSY_BIT)  <= tx_busy_i;
    status(STAT_RX_BUSY_BIT)  <= rx_busy_i;

    ack_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                ack_reg <= '0';
            else
                ack_reg <= stb_i and cyc_i;
            end if;
        end if;
    end process ack_proc;

    rd_mux_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rd_en = '1' then
                case adr_i is
                    when ADDR_STAT =>
                        dat_reg(5 downto 0)   <= status;
                        dat_reg(31 downto 6)  <= (others => '0');
                    when ADDR_CTRL =>
                        dat_reg <= (1 downto 0 => '1', others => '0');
                    when ADDR_BRDV =>
                        dat_reg <= (31 downto UART_BAUD_WIDTH => '0') & baud_div_reg;
                    when ADDR_TXRX =>
                        dat_reg(DATA_WIDTH-1 downto 0) <= rx_data_i;
                        dat_reg(31 downto DATA_WIDTH)  <= (others => '0');
                    when others =>
                        dat_reg <= (others => '0');
                end case;
            end if;
        end if;
    end process rd_mux_proc;

    ack_o      <= ack_reg;
    stall_o    <= '0'; -- Pipelined masters only
    baud_div_o <= baud_div_reg;
    en_o       <= '0' when baud_div_reg = BRDV_OFF else '1';
    dat_o      <= dat_reg;
    tx_data_o  <= dat_i(DATA_WIDTH-1 downto 0);
    tx_valid_o <= '1' when wr_en = '1' and adr_i = ADDR_TXRX and sel_i(0) = '1' else '0';
    rx_ready_o <= '1' when rd_en = '1' and adr_i = ADDR_TXRX else '0';

end architecture rtl;
