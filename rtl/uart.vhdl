----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart
-- description: main UART logic (datapath only)
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart is
    generic (
        FIFO_DEPTH : positive := 8;
        DATA_WIDTH : positive := 8
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;

        -- Configuration
        baud_div_i : in  std_logic_vector(UART_BAUD_WIDTH-1 downto 0);
        en_i       : in  std_logic;

        -- Status
        tx_ready_o : out std_logic;
        rx_ready_o : out std_logic;
        tx_valid_o : out std_logic;
        rx_valid_o : out std_logic;
        tx_busy_o  : out std_logic;
        rx_busy_o  : out std_logic;

        -- FIFO access
        valid_i : in  std_logic; -- TX FIFO push
        data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        ready_i : in  std_logic; -- RX FIFO pop
        data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Serial line
        rx_i : in  std_logic; -- Asynchronous
        tx_o : out std_logic
    );
end entity uart;

architecture rtl of uart is

    signal rx_sync_inst_rx : std_logic;

    signal rx_fifo_inst_valid  : std_logic;
    signal rx_fifo_inst_ready  : std_logic;
    signal receiver_inst_busy  : std_logic;
    signal receiver_inst_valid : std_logic;
    signal receiver_inst_data  : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal tx_fifo_inst_valid     : std_logic;
    signal tx_fifo_inst_ready     : std_logic;
    signal tx_fifo_inst_data      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal transmitter_inst_ready : std_logic;
    signal transmitter_inst_busy  : std_logic;

begin

    rx_sync_inst: entity work.rx_sync generic map (
        STAGES  => 2,
        RST_VAL => '1' -- Line idle level: no false start bit after reset
    ) port map (
        clk_i => clk_i,
        rst_i => rst_i,
        rx_i  => rx_i,
        rx_o  => rx_sync_inst_rx
    );

    rx_fifo_inst: entity work.fifo generic map (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i   => clk_i,
        rst_i   => rst_i,
        valid_i => receiver_inst_valid,
        ready_i => ready_i,
        data_i  => receiver_inst_data,
        valid_o => rx_fifo_inst_valid,
        ready_o => rx_fifo_inst_ready,
        data_o  => data_o
    );

    receiver_inst: entity work.uart_rx generic map (
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i      => clk_i,
        rst_i      => rst_i,
        rx_i       => rx_sync_inst_rx,
        ready_i    => rx_fifo_inst_ready,
        baud_div_i => baud_div_i,
        en_i       => en_i,
        busy_o     => receiver_inst_busy,
        valid_o    => receiver_inst_valid,
        data_o     => receiver_inst_data
    );

    tx_fifo_inst: entity work.fifo generic map (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i   => clk_i,
        rst_i   => rst_i,
        valid_i => valid_i,
        ready_i => transmitter_inst_ready,
        data_i  => data_i,
        valid_o => tx_fifo_inst_valid,
        ready_o => tx_fifo_inst_ready,
        data_o  => tx_fifo_inst_data
    );

    transmitter_inst: entity work.uart_tx generic map (
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i      => clk_i,
        rst_i      => rst_i,
        baud_div_i => baud_div_i,
        en_i       => en_i,
        ready_o    => transmitter_inst_ready,
        busy_o     => transmitter_inst_busy,
        valid_i    => tx_fifo_inst_valid,
        data_i     => tx_fifo_inst_data,
        tx_o       => tx_o
    );

    tx_ready_o <= tx_fifo_inst_ready;
    rx_ready_o <= rx_fifo_inst_ready;
    tx_valid_o <= tx_fifo_inst_valid;
    rx_valid_o <= rx_fifo_inst_valid;
    tx_busy_o  <= transmitter_inst_busy;
    rx_busy_o  <= receiver_inst_busy;

end architecture rtl;
