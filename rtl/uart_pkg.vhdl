----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_pkg
-- description: constants and utility functions package
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package uart_pkg is

    -- Global Constants
    constant UART_BAUD_WIDTH : natural := 16; -- Width of the baud rate divider register

    -- BRDV value that turns RX and TX off (also the reset value)
    constant BRDV_OFF : std_logic_vector(UART_BAUD_WIDTH-1 downto 0) := (others => '0');

    -- Register Address Map (2-bit address space)
    constant ADDR_STAT : std_logic_vector(1 downto 0) := b"00"; -- Status Register
    constant ADDR_CTRL : std_logic_vector(1 downto 0) := b"01"; -- Control Register
    constant ADDR_BRDV : std_logic_vector(1 downto 0) := b"10"; -- Baud Rate Divider
    constant ADDR_TXRX : std_logic_vector(1 downto 0) := b"11"; -- Data Transmit/Receive

    -- Status Register Bit Positions
    constant STAT_TX_READY_BIT    : natural := 5; -- '1' when TX FIFO has space
    constant STAT_RX_READY_BIT    : natural := 4; -- '1' when RX FIFO has space
    constant STAT_TX_VALID_BIT    : natural := 3; -- '1' when TX FIFO is not empty
    constant STAT_RX_VALID_BIT    : natural := 2; -- '1' when RX FIFO has received data
    constant STAT_TX_BUSY_BIT     : natural := 1; -- '1' when transmitter is active
    constant STAT_RX_BUSY_BIT     : natural := 0; -- '1' when receiver is active

    -- Utility Functions
    function clog2 (n : natural) return natural;

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
