----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_pkg
-- description: components and constants package
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package uart_pkg is

    -- Global Constants
    constant UART_BAUD_WIDTH : natural := 16; -- Width of the baud rate divider register

    -- Register Address Map (2-bit address space)
    constant ADDR_STAT : std_logic_vector(1 downto 0) := b"00"; -- Status Register
    constant ADDR_CTRL : std_logic_vector(1 downto 0) := b"01"; -- Control Register
    constant ADDR_BRDV : std_logic_vector(1 downto 0) := b"10"; -- Baud Rate Divider
    constant ADDR_TXRX : std_logic_vector(1 downto 0) := b"11"; -- Data Transmit/Receive

    -- Status Register Bit Positions
    constant STAT_TX_NOT_FULL_BIT : natural := 5; -- '1' when TX FIFO has space
    constant STAT_RX_NOT_FULL_BIT : natural := 4; -- '1' when RX FIFO has space
    constant STAT_TX_VALID_BIT    : natural := 3; -- '1' when TX FIFO is not empty
    constant STAT_RX_VALID_BIT    : natural := 2; -- '1' when RX FIFO has received data
    constant STAT_TX_BUSY_BIT     : natural := 1; -- '1' when transmitter is active
    constant STAT_RX_BUSY_BIT     : natural := 0; -- '1' when receiver is active

    -- Utility Functions
    function clog2 (n : natural) return natural;

    -- Components
    component fifo is
        generic (
            FIFO_DEPTH : natural := 8; -- Number of slots in the FIFO
            DATA_WIDTH : natural := 8  -- Width of each data slot
        );
        port (
            clk_i   : in  std_logic; -- System clock
            rst_i   : in  std_logic; -- Synchronous reset (active high)

            valid_i : in  std_logic; -- Input data valid
            ready_i : in  std_logic; -- Downstream ready to receive
            data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Data input

            valid_o : out std_logic; -- Output data valid
            ready_o : out std_logic; -- Upstream ready to accept
            data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)  -- Data output
        );
    end component fifo;

    component uart_tx is
        generic (
            DATA_WIDTH : natural := 8 -- Transmit word size
        );
        port (
            clk_i      : in  std_logic; -- System clock
            rst_i      : in  std_logic; -- Synchronous reset
            valid_i    : in  std_logic; -- Data to transmit is valid
            data_i     : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Data to transmit
            baud_div_i : in  std_logic_vector(15 downto 0); -- Baud rate divider
            tx_o       : out std_logic; -- Serial output line
            busy_o     : out std_logic; -- High during transmission
            ready_o    : out std_logic  -- Ready to accept new data
        );
    end component uart_tx;

    component uart_rx is
        generic (
            DATA_WIDTH : natural := 8 -- Receive word size
        );
        port (
            clk_i      : in  std_logic; -- System clock
            rst_i      : in  std_logic; -- Synchronous reset
            rx_i       : in  std_logic; -- Serial input line
            ready_i    : in  std_logic; -- Downstream ready to receive data
            baud_div_i : in  std_logic_vector(15 downto 0); -- Baud rate divider
            busy_o     : out std_logic; -- High during reception
            valid_o    : out std_logic; -- Received data is valid
            data_o     : out std_logic_vector(DATA_WIDTH-1 downto 0) -- Received data
        );
    end component uart_rx;

    component uart_csrs is
        generic (
            DATA_WIDTH : natural := 8
        );
        port (
            clk_i   : in  std_logic;
            rst_i   : in  std_logic;

            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            adr_i : in  std_logic_vector(1 downto 0);
            dat_i : in  std_logic_vector(31 downto 0);
            dat_o : out std_logic_vector(31 downto 0);
            ack_o : out std_logic;

            baud_div_o : out std_logic_vector(UART_BAUD_WIDTH-1 downto 0);
            
            tx_not_full_i : in  std_logic;
            rx_not_full_i : in  std_logic;
            tx_valid_i    : in  std_logic;
            rx_valid_i    : in  std_logic;
            tx_busy_i     : in  std_logic;
            rx_busy_i     : in  std_logic;
            
            tx_valid_o : out std_logic;
            tx_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            rx_ready_o : out std_logic;
            rx_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component uart_csrs;

    component uart is
        generic (
            FIFO_DEPTH : natural := 8;
            DATA_WIDTH : natural := 8
        );
        port (
            clk_i   : in  std_logic;
            rst_i   : in  std_logic;

            baud_div_i : in  std_logic_vector(UART_BAUD_WIDTH-1 downto 0);
            
            tx_not_full_o : out std_logic;
            rx_not_full_o : out std_logic;
            tx_valid_o    : out std_logic;
            rx_valid_o    : out std_logic;
            tx_busy_o     : out std_logic;
            rx_busy_o     : out std_logic;
            
            valid_i : in  std_logic;
            data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            ready_i : in  std_logic;
            data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);

            rx : in  std_logic;
            tx : out std_logic
        );
    end component uart;

    component uart_wbsl is
        generic (
            FIFO_DEPTH : natural := 8;
            DATA_WIDTH : natural := 8
        );
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
    end component uart_wbsl;

end package uart_pkg;

package body uart_pkg is

    function clog2 (n : natural) return natural is
        variable res : natural := 0;
        variable tmp : natural := n;
    begin
        if n <= 1 then return 1; end if;
        tmp := n - 1;
        while tmp > 0 loop
            tmp := tmp / 2;
            res := res + 1;
        end loop;
        return res;
    end function;

end package body uart_pkg;
