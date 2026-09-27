----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_wbsl
-- description: Wishbone B4 Slave wrapper
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart_wbsl is
    generic (
        FIFO_DEPTH : positive := 8;
        DATA_WIDTH : positive := 8
    );
    port (
        -- Wishbone B4 pipelined slave
        clk_i   : in  std_logic;
        rst_i   : in  std_logic;
        dat_i   : in  std_logic_vector(31 downto 0);
        cyc_i   : in  std_logic;
        stb_i   : in  std_logic;
        we_i    : in  std_logic;
        sel_i   : in  std_logic_vector(3 downto 0);
        adr_i   : in  std_logic_vector(1 downto 0);
        ack_o   : out std_logic;
        stall_o : out std_logic;
        dat_o   : out std_logic_vector(31 downto 0);

        -- Serial line
        rx_i : in  std_logic;
        tx_o : out std_logic
    );
end entity uart_wbsl;

architecture rtl of uart_wbsl is

    signal csrs_inst_baud_div : std_logic_vector(UART_BAUD_WIDTH-1 downto 0);
    signal csrs_inst_en       : std_logic;
    signal csrs_inst_tx_valid : std_logic;
    signal csrs_inst_tx_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal csrs_inst_rx_ready : std_logic;

    signal uart_inst_tx_ready : std_logic;
    signal uart_inst_rx_ready : std_logic;
    signal uart_inst_tx_valid : std_logic;
    signal uart_inst_rx_valid : std_logic;
    signal uart_inst_tx_busy  : std_logic;
    signal uart_inst_rx_busy  : std_logic;
    signal uart_inst_data     : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    csrs_inst: entity work.uart_csrs generic map (
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i   => clk_i,
        rst_i   => rst_i,

        cyc_i   => cyc_i,
        stb_i   => stb_i,
        we_i    => we_i,
        sel_i   => sel_i,
        adr_i   => adr_i,
        dat_i   => dat_i,
        dat_o   => dat_o,
        ack_o   => ack_o,
        stall_o => stall_o,

        baud_div_o => csrs_inst_baud_div,
        en_o       => csrs_inst_en,

        tx_ready_i => uart_inst_tx_ready,
        rx_ready_i => uart_inst_rx_ready,
        tx_valid_i => uart_inst_tx_valid,
        rx_valid_i => uart_inst_rx_valid,
        tx_busy_i  => uart_inst_tx_busy,
        rx_busy_i  => uart_inst_rx_busy,

        tx_valid_o => csrs_inst_tx_valid,
        tx_data_o  => csrs_inst_tx_data,
        rx_ready_o => csrs_inst_rx_ready,
        rx_data_i  => uart_inst_data
    );

    uart_inst: entity work.uart generic map (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i      => clk_i,
        rst_i      => rst_i,
        baud_div_i => csrs_inst_baud_div,
        en_i       => csrs_inst_en,
        tx_ready_o => uart_inst_tx_ready,
        rx_ready_o => uart_inst_rx_ready,
        tx_valid_o => uart_inst_tx_valid,
        rx_valid_o => uart_inst_rx_valid,
        tx_busy_o  => uart_inst_tx_busy,
        rx_busy_o  => uart_inst_rx_busy,
        valid_i    => csrs_inst_tx_valid,
        data_i     => csrs_inst_tx_data,
        ready_i    => csrs_inst_rx_ready,
        data_o     => uart_inst_data,
        rx_i       => rx_i,
        tx_o       => tx_o
    );

end architecture rtl;
