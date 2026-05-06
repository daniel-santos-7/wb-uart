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
        FIFO_DEPTH : natural := 8; -- Number of slots in TX/RX FIFOs
        DATA_WIDTH : natural := 8  -- UART data word size (5 to 8 bits)
    );
    port (
        clk_i   : in  std_logic; -- System clock
        rst_i   : in  std_logic; -- Synchronous reset (active high)

        -- Control/Status Interface
        baud_div_i : in  std_logic_vector(15 downto 0); -- Configured baud rate divider
        
        -- Individual status flags for CSR module
        tx_not_full_o : out std_logic; -- '1' when TX FIFO has space
        rx_not_full_o : out std_logic; -- '1' when RX FIFO has space
        tx_valid_o    : out std_logic; -- '1' when TX FIFO is not empty
        rx_valid_o    : out std_logic; -- '1' when RX FIFO is not empty
        tx_busy_o     : out std_logic; -- '1' when serial transmitter is active
        rx_busy_o     : out std_logic; -- '1' when serial receiver is active
        
        -- Internal Bus/FIFO Interface (Data Flow)
        valid_i : in  std_logic; -- Push to TX FIFO
        data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Data to transmit
        ready_i : in  std_logic; -- Pop from RX FIFO
        data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0); -- Data from RX FIFO

        -- Physical Serial Interface
        rx      : in  std_logic; -- Asynchronous serial input
        tx      : out std_logic  -- Serial output line
    );
end entity uart;

architecture rtl of uart is

    -- Internal state signals
    signal rx_sync_reg : std_logic_vector(1 downto 0); -- Metastability filter for RX input

    -- RX Path internal signals
    signal rx_data_valid     : std_logic;
    signal rx_data           : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal rx_fifo_not_full  : std_logic;
    signal rx_fifo_valid     : std_logic;
    signal rx_busy           : std_logic;

    -- TX Path internal signals
    signal tx_fifo_not_full  : std_logic;
    signal tx_fifo_valid     : std_logic;
    signal tx_fifo_data      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal tx_ready          : std_logic;
    signal tx_busy           : std_logic;

begin

    ----------------------- Control Logic (Sync) -------------------------

    -- 2-stage synchronizer for external asynchronous RX input
    rx_sync_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rx_sync_reg <= (others => '1');
            else
                rx_sync_reg <= rx & rx_sync_reg(1);
            end if;
        end if;
    end process rx_sync_proc;

    ----------------------- Datapath Logic (RX Path) ---------------------

    -- Receiver buffer
    rx_fifo_inst: fifo generic map (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i   => clk_i,
        rst_i   => rst_i,
        valid_i => rx_data_valid,
        ready_i => ready_i,
        data_i  => rx_data,
        valid_o => rx_fifo_valid,
        ready_o => rx_fifo_not_full,
        data_o  => data_o
    );

    -- Deserializer engine
    receiver_inst: uart_rx 
    generic map (
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i      => clk_i,
        rst_i      => rst_i,
        rx_i       => rx_sync_reg(0), -- Stable synchronized signal
        ready_i    => rx_fifo_not_full,
        baud_div_i => baud_div_i,
        busy_o     => rx_busy,
        valid_o    => rx_data_valid,
        data_o     => rx_data
    );

    ----------------------- Datapath Logic (TX Path) ---------------------

    -- Transmitter buffer
    tx_fifo_inst: fifo generic map (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i   => clk_i,
        rst_i   => rst_i,
        valid_i => valid_i,
        ready_i => tx_ready,
        data_i  => data_i,
        valid_o => tx_fifo_valid,
        ready_o => tx_fifo_not_full,
        data_o  => tx_fifo_data
    );

    -- Serializer engine
    transmitter_inst: uart_tx 
    generic map (
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i      => clk_i,
        rst_i      => rst_i,
        baud_div_i => baud_div_i,
        ready_o    => tx_ready,
        busy_o     => tx_busy,
        valid_i    => tx_fifo_valid,
        data_i     => tx_fifo_data,
        tx_o       => tx
    );

    ------------------------------ Status Outputs ------------------------

    tx_not_full_o <= tx_fifo_not_full;
    rx_not_full_o <= rx_fifo_not_full;
    tx_valid_o    <= tx_fifo_valid;
    rx_valid_o    <= rx_fifo_valid;
    tx_busy_o     <= tx_busy;
    rx_busy_o     <= rx_busy;

end architecture rtl;
