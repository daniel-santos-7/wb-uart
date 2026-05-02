----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart
-- description: main UART logic and register file
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;

        rd      : in  std_logic;
        rd_addr : in  std_logic_vector(1 downto 0);
        rd_data : out std_logic_vector(15 downto 0);

        wr      : in  std_logic;
        wr_addr : in  std_logic_vector(1 downto 0);
        wr_data : in  std_logic_vector(15 downto 0);

        rx      : in  std_logic;
        tx      : out std_logic
    );
end entity uart;

architecture rtl of uart is

    constant STAT_ADDR : std_logic_vector(1 downto 0) := b"00";
    constant CTRL_ADDR : std_logic_vector(1 downto 0) := b"01";
    constant BRDV_ADDR : std_logic_vector(1 downto 0) := b"10";
    constant TXRX_ADDR : std_logic_vector(1 downto 0) := b"11";

    signal status : std_logic_vector(5 downto 0);

    signal baud_div_reg : std_logic_vector(15 downto 0);

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

    baud_div_proc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                baud_div_reg <= (others => '1');
            elsif wr = '1' and wr_addr = BRDV_ADDR then
                baud_div_reg <= wr_data;
            end if;
        end if;
    end process baud_div_proc;

    ----------------------- Datapath Logic -----------------------------

    rx_fifo_rd <= '1' when rd = '1' and rd_addr = TXRX_ADDR else '0';

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

    rx_fifo_wr      <= rx_wr;
    rx_wr_en        <= rx_fifo_wr_en;
    rx_fifo_wr_data <= rx_wr_data;

    receiver_inst: uart_rx port map (
        clk_i   => clk,
        rst_i   => reset,
        rx_i    => rx_sync_reg(0),
        ready_i => rx_wr_en,
        div_i   => baud_div_reg,
        busy_o  => rx_busy,
        valid_o => rx_wr,
        data_o  => rx_wr_data
    );

    tx_fifo_wr      <= '1' when wr = '1' and wr_addr = TXRX_ADDR else '0';
    tx_fifo_wr_data <= wr_data(7 downto 0);

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
        div_i   => baud_div_reg,
        ready_o => tx_rd,
        busy_o  => tx_busy,
        valid_i => tx_rd_en,
        data_i  => tx_rd_data,
        tx_o    => tx
    );

    status(5 downto 4) <= tx_fifo_wr_en & rx_fifo_wr_en;
    status(3 downto 2) <= tx_fifo_rd_en & rx_fifo_rd_en;
    status(1 downto 0) <= tx_busy & rx_busy;

    ------------------------------ Outputs ------------------------------

    rd_reg: process(rd, rd_addr, status, baud_div_reg, rx_fifo_rd_data)
    begin
        if rd = '1' then
            case rd_addr is
                when STAT_ADDR =>
                    rd_data(5 downto 0)  <= status;
                    rd_data(15 downto 6) <= (others => '0');
                when CTRL_ADDR =>
                    rd_data <= (1 downto 0 => '1', others => '0');
                when BRDV_ADDR =>
                    rd_data <= baud_div_reg;
                when TXRX_ADDR =>
                    rd_data(7 downto 0)  <= rx_fifo_rd_data;
                    rd_data(15 downto 8) <= (others => '0');
                when others =>
                    rd_data <= (others => '0');
            end case;
        else
            rd_data <= (others => '0');
        end if;
    end process rd_reg;

end architecture rtl;
