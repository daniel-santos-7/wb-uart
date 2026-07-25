----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_csrs
-- description: Control and Status Registers (CSRs) with Wishbone interface
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_csrs is
    generic (
        DATA_WIDTH : natural := 8 -- UART word size (propagated for data register padding)
    );
    port (
        clk_i   : in  std_logic; -- System clock
        rst_i   : in  std_logic; -- Synchronous reset (active high)

        -- Wishbone B4 Slave Interface
        cyc_i : in  std_logic; -- Cycle strobe
        stb_i : in  std_logic; -- Slave strobe
        we_i  : in  std_logic; -- Write enable
        adr_i : in  std_logic_vector(1 downto 0);  -- Register address
        dat_i : in  std_logic_vector(31 downto 0); -- Data from bus
        dat_o : out std_logic_vector(31 downto 0); -- Data to bus
        ack_o : out std_logic; -- Bus transaction acknowledge

        -- Internal Control/Status
        baud_div_o : out std_logic_vector(UART_BAUD_WIDTH-1 downto 0); -- Baud rate config

        -- Discrete status inputs from core
        tx_not_full_i : in  std_logic;
        rx_not_full_i : in  std_logic;
        tx_valid_i    : in  std_logic;
        rx_valid_i    : in  std_logic;
        tx_busy_i     : in  std_logic;
        rx_busy_i     : in  std_logic;

        -- Internal Handshake Interface
        tx_valid_o : out std_logic; -- Triggers TX FIFO write
        tx_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0); -- Data to transmit
        rx_ready_o : out std_logic; -- Triggers RX FIFO read
        rx_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0) -- Data received
    );
end entity uart_csrs;

architecture rtl of uart_csrs is

    signal baud_div_reg : std_logic_vector(UART_BAUD_WIDTH-1 downto 0); -- Stored divider

    signal rd_en : std_logic; -- Internal read cycle flag
    signal wr_en : std_logic; -- Internal write cycle flag

    signal status : std_logic_vector(5 downto 0); -- Assembled status word
    signal ack_reg    : std_logic; -- Registered acknowledge
    signal dat_reg  : std_logic_vector(31 downto 0); -- Registered read data

begin

    ----------------------- Bus Access Logic ----------------------------

    rd_en <= stb_i and cyc_i and not we_i;
    wr_en <= stb_i and cyc_i and we_i;

    -- Baud rate divider storage
    baud_div_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                baud_div_reg <= (others => '1');
            elsif wr_en = '1' and adr_i = ADDR_BRDV then
                baud_div_reg <= dat_i(UART_BAUD_WIDTH-1 downto 0);
            end if;
        end if;
    end process baud_div_proc;

    ----------------------- Datapath Logic -----------------------------

    -- Status assembly using constants from package
    status(STAT_TX_NOT_FULL_BIT) <= tx_not_full_i;
    status(STAT_RX_NOT_FULL_BIT) <= rx_not_full_i;
    status(STAT_TX_VALID_BIT)    <= tx_valid_i;
    status(STAT_RX_VALID_BIT)    <= rx_valid_i;
    status(STAT_TX_BUSY_BIT)     <= tx_busy_i;
    status(STAT_RX_BUSY_BIT)     <= rx_busy_i;

    ------------------------------ Outputs ------------------------------

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

    -- Registered read multiplexer
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

    ------------------------------ Outputs ------------------------------

    ack_o      <= ack_reg;
    baud_div_o <= baud_div_reg;
    dat_o      <= dat_reg;
    tx_data_o  <= dat_i(DATA_WIDTH-1 downto 0);
    tx_valid_o <= '1' when wr_en = '1' and adr_i = ADDR_TXRX else '0';
    rx_ready_o <= '1' when rd_en = '1' and adr_i = ADDR_TXRX else '0';

end architecture rtl;
