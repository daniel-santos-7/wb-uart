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
        FIFO_DEPTH : natural := 8; -- Number of slots in the TX/RX FIFOs
        DATA_WIDTH : natural := 8  -- UART data word size (5 to 8 bits)
    );
    port (
        -- Wishbone B4 Slave Interface
        clk_i : in  std_logic; -- System clock
        rst_i : in  std_logic; -- Synchronous reset (active high)
        dat_i : in  std_logic_vector(31 downto 0); -- Bus write data
        cyc_i : in  std_logic; -- Cycle strobe
        stb_i : in  std_logic; -- Slave strobe
        we_i  : in  std_logic; -- Write enable
        sel_i : in  std_logic_vector(3 downto 0); -- Byte enables (ignored, 32-bit registers)
        adr_i : in  std_logic_vector(1 downto 0); -- Register address
        ack_o : out std_logic; -- Acknowledge
        dat_o : out std_logic_vector(31 downto 0); -- Bus read data

        -- UART Line Interface
        rx    : in  std_logic; -- Serial input line
        tx    : out std_logic  -- Serial output line
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
    signal tx_fifo_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal rx_fifo_ready : std_logic;
    signal rx_fifo_data  : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    ----------------------- Control Logic (Bus Interface) ------------------

    csrs_inst: uart_csrs 
    generic map (
        DATA_WIDTH => DATA_WIDTH
    ) port map (
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

    ----------------------- Datapath Logic (Functional Core) ---------------

    uart_inst: uart 
    generic map (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    ) port map (
        clk_i         => clk_i,
        rst_i         => rst_i,
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
