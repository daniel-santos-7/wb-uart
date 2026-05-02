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

    signal status   : std_logic_vector(5 downto 0);
    signal baud_div : std_logic_vector(15 downto 0);

    signal tx_fifo_wr      : std_logic;
    signal tx_fifo_wr_data : std_logic_vector(7 downto 0);
    signal rx_fifo_rd      : std_logic;
    signal rx_fifo_rd_data : std_logic_vector(7 downto 0);

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
        status_i   => status,
        
        tx_fifo_wr_o      => tx_fifo_wr,
        tx_fifo_wr_data_o => tx_fifo_wr_data,
        rx_fifo_rd_o      => rx_fifo_rd,
        rx_fifo_rd_data_i => rx_fifo_rd_data
    );

    ----------------------- Datapath Logic -----------------------------

    uart_inst: uart port map (
        clk               => clk_i,
        reset             => rst_i,
        baud_div_i        => baud_div,
        status_o          => status,
        tx_fifo_wr_i      => tx_fifo_wr,
        tx_fifo_wr_data_i => tx_fifo_wr_data,
        rx_fifo_rd_i      => rx_fifo_rd,
        rx_fifo_rd_data_o => rx_fifo_rd_data,
        rx                => rx,
        tx                => tx
    );

end architecture rtl;
