----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_wbsl
-- description: Wishbone B4 Slave wrapper
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart_wbsl is
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        sel_i : in  std_logic_vector(3 downto 0);
        adr_i : in  std_logic_vector(1 downto 0);
        rx    : in  std_logic;
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0);
        tx    : out std_logic
    );
end entity uart_wbsl;

architecture rtl of uart_wbsl is

    signal baud_div : std_logic_vector(15 downto 0);

    signal tx_not_full : std_logic;
    signal rx_not_full : std_logic;
    signal tx_valid    : std_logic;
    signal rx_valid    : std_logic;
    signal tx_busy     : std_logic;
    signal rx_busy     : std_logic;

    signal tx_fifo_valid : std_logic;
    signal tx_fifo_data  : std_logic_vector(7 downto 0);
    signal rx_fifo_ready : std_logic;
    signal rx_fifo_data  : std_logic_vector(7 downto 0);

begin

    ----------------------- Control Logic ----------------------------

    csrs_inst: uart_csrs port map (
        clk_i   => clk_i,
        rst_i   => rst_i,

        cyc_i   => cyc_i,
        stb_i   => stb_i,
        we_i    => we_i,
        adr_i   => adr_i,
        dat_i   => dat_i,
        dat_o   => dat_o,
        ack_o   => ack_o,

        baud_div_o => baud_div,
        
        tx_not_full_i => tx_not_full,
        rx_not_full_i => rx_not_full,
        tx_valid_i    => tx_valid,
        rx_valid_i    => rx_valid,
        tx_busy_i     => tx_busy,
        rx_busy_i     => rx_busy,
        
        tx_valid_o => tx_fifo_valid,
        tx_data_o  => tx_fifo_data,
        rx_ready_o => rx_fifo_ready,
        rx_data_i  => rx_fifo_data
    );

    ----------------------- Datapath Logic -----------------------------

    uart_inst: uart port map (
        clk           => clk_i,
        reset         => rst_i,
        baud_div_i    => baud_div,
        tx_not_full_o => tx_not_full,
        rx_not_full_o => rx_not_full,
        tx_valid_o    => tx_valid,
        rx_valid_o    => rx_valid,
        tx_busy_o     => tx_busy,
        rx_busy_o     => rx_busy,
        valid_i       => tx_fifo_valid,
        data_i        => tx_fifo_data,
        ready_i       => rx_fifo_ready,
        data_o        => rx_fifo_data,
        rx            => rx,
        tx            => tx
    );

end architecture rtl;
