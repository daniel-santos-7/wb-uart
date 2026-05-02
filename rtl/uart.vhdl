----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart
-- description: main UART logic (datapath only)
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;

        -- Control/Status Interface
        baud_div_i : in  std_logic_vector(15 downto 0);
        status_o   : out std_logic_vector(5 downto 0);
        
        -- FIFO Control Interface
        valid_i : in  std_logic;
        data_i  : in  std_logic_vector(7 downto 0);
        ready_i : in  std_logic;
        data_o  : out std_logic_vector(7 downto 0);

        -- Line Interface
        rx      : in  std_logic;
        tx      : out std_logic
    );
end entity uart;

architecture rtl of uart is

    -- Internal state signals
    signal rx_sync_reg : std_logic_vector(1 downto 0);

    -- RX Path signals
    signal rx_wr           : std_logic;
    signal rx_wr_data      : std_logic_vector(7 downto 0);
    signal rx_fifo_not_full : std_logic;
    signal rx_fifo_valid   : std_logic;
    signal rx_busy         : std_logic;

    -- TX Path signals
    signal tx_fifo_not_full : std_logic;
    signal tx_fifo_valid   : std_logic;
    signal tx_fifo_data    : std_logic_vector(7 downto 0);
    signal tx_fifo_rd      : std_logic;
    signal tx_busy         : std_logic;

begin

    ----------------------- Control Logic ----------------------------

    rx_sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_sync_reg <= (others => '1');
            else
                rx_sync_reg <= rx & rx_sync_reg(1);
            end if;
        end if;
    end process rx_sync_proc;

    ----------------------- Datapath Logic -----------------------------

    rx_fifo_inst: fifo generic map (
        FIFO_DEPTH => 8,
        DATA_WIDTH => 8
    ) port map (
        clk_i   => clk,
        rst_i   => reset,
        valid_i => rx_wr,
        ready_i => ready_i,
        data_i  => rx_wr_data,
        valid_o => rx_fifo_valid,
        ready_o => rx_fifo_not_full,
        data_o  => data_o
    );

    receiver_inst: uart_rx port map (
        clk_i   => clk,
        rst_i   => reset,
        rx_i    => rx_sync_reg(0),
        ready_i => rx_fifo_not_full,
        div_i   => baud_div_i,
        busy_o  => rx_busy,
        valid_o => rx_wr,
        data_o  => rx_wr_data
    );

    tx_fifo_inst: fifo generic map (
        FIFO_DEPTH => 8,
        DATA_WIDTH => 8
    ) port map (
        clk_i   => clk,
        rst_i   => reset,
        valid_i => valid_i,
        ready_i => tx_fifo_rd,
        data_i  => data_i,
        valid_o => tx_fifo_valid,
        ready_o => tx_fifo_not_full,
        data_o  => tx_fifo_data
    );

    transmitter_inst: uart_tx port map (
        clk_i   => clk,
        rst_i   => reset,
        div_i   => baud_div_i,
        ready_o => tx_fifo_rd,
        busy_o  => tx_busy,
        valid_i => tx_fifo_valid,
        data_i  => tx_fifo_data,
        tx_o    => tx
    );

    ------------------------------ Outputs ------------------------------

    status_o(5) <= tx_fifo_not_full;
    status_o(4) <= rx_fifo_not_full;
    status_o(3) <= tx_fifo_valid;
    status_o(2) <= rx_fifo_valid;
    status_o(1) <= tx_busy;
    status_o(0) <= rx_busy;

end architecture rtl;
