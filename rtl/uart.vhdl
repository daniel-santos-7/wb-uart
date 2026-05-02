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
        tx_fifo_wr_i      : in  std_logic;
        tx_fifo_wr_data_i : in  std_logic_vector(7 downto 0);
        rx_fifo_rd_i      : in  std_logic;
        rx_fifo_rd_data_o : out std_logic_vector(7 downto 0);

        -- Line Interface
        rx      : in  std_logic;
        tx      : out std_logic
    );
end entity uart;

architecture rtl of uart is

    signal rx_fifo_wr      : std_logic;
    signal rx_fifo_wr_en   : std_logic;
    signal rx_fifo_rd      : std_logic;
    signal rx_fifo_rd_en   : std_logic;
    signal rx_fifo_wr_data : std_logic_vector(7 downto 0);
    signal rx_fifo_rd_data : std_logic_vector(7 downto 0);

    signal rx_wr      : std_logic;
    signal rx_wr_en   : std_logic;
    signal rx_busy    : std_logic;
    signal rx_wr_data : std_logic_vector(7 downto 0);

    signal tx_fifo_wr      : std_logic;
    signal tx_fifo_wr_en   : std_logic;
    signal tx_fifo_rd      : std_logic;
    signal tx_fifo_rd_en   : std_logic;
    signal tx_fifo_wr_data : std_logic_vector(7 downto 0);
    signal tx_fifo_rd_data : std_logic_vector(7 downto 0);

    signal tx_rd      : std_logic;
    signal tx_rd_en   : std_logic;
    signal tx_busy    : std_logic;
    signal tx_rd_data : std_logic_vector(7 downto 0);

    signal rx_sync_reg : std_logic_vector(1 downto 0);

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

    -- RX Path Connections
    rx_fifo_wr      <= rx_wr;
    rx_fifo_wr_data <= rx_wr_data;
    rx_wr_en        <= rx_fifo_wr_en;
    rx_fifo_rd      <= rx_fifo_rd_i;
    rx_fifo_rd_data_o <= rx_fifo_rd_data;

    rx_fifo_inst: fifo generic map (
        FIFO_DEPTH => 8,
        DATA_WIDTH => 8
    ) port map (
        clk_i => clk,
        rst_i => reset,
        vld_i => rx_fifo_wr,
        rdy_i => rx_fifo_rd,
        dat_i => rx_fifo_wr_data,
        vld_o => rx_fifo_rd_en,
        rdy_o => rx_fifo_wr_en,
        dat_o => rx_fifo_rd_data
    );

    receiver_inst: uart_rx port map (
        clk_i   => clk,
        rst_i   => reset,
        rx_i    => rx_sync_reg(0),
        ready_i => rx_wr_en,
        div_i   => baud_div_i,
        busy_o  => rx_busy,
        valid_o => rx_wr,
        data_o  => rx_wr_data
    );

    -- TX Path Connections
    tx_fifo_wr      <= tx_fifo_wr_i;
    tx_fifo_wr_data <= tx_fifo_wr_data_i;

    tx_fifo_inst: fifo generic map (
        FIFO_DEPTH => 8,
        DATA_WIDTH => 8
    ) port map (
        clk_i => clk,
        rst_i => reset,
        vld_i => tx_fifo_wr,
        rdy_i => tx_fifo_rd,
        dat_i => tx_fifo_wr_data,
        vld_o => tx_fifo_rd_en,
        rdy_o => tx_fifo_wr_en,
        dat_o => tx_fifo_rd_data
    );

    tx_fifo_rd <= tx_rd;
    tx_rd_en   <= tx_fifo_rd_en;
    tx_rd_data <= tx_fifo_rd_data;

    transmitter_inst: uart_tx port map (
        clk_i   => clk,
        rst_i   => reset,
        div_i   => baud_div_i,
        ready_o => tx_rd,
        busy_o  => tx_busy,
        valid_i => tx_rd_en,
        data_i  => tx_rd_data,
        tx_o    => tx
    );

    ------------------------------ Outputs ------------------------------

    status_o(5 downto 4) <= tx_fifo_wr_en & rx_fifo_wr_en;
    status_o(3 downto 2) <= tx_fifo_rd_en & rx_fifo_rd_en;
    status_o(1 downto 0) <= tx_busy & rx_busy;

end architecture rtl;
