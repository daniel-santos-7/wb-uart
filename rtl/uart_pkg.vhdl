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

    -- BRDV byte writes (sel_i) handle 9 to 16 bits
    constant UART_BAUD_WIDTH : natural := 16;

    -- Turns RX and TX off; also the reset value
    constant BRDV_OFF : std_logic_vector(UART_BAUD_WIDTH-1 downto 0) := (others => '0');

    constant ADDR_STAT : std_logic_vector(1 downto 0) := b"00";
    constant ADDR_CTRL : std_logic_vector(1 downto 0) := b"01";
    constant ADDR_BRDV : std_logic_vector(1 downto 0) := b"10";
    constant ADDR_TXRX : std_logic_vector(1 downto 0) := b"11";

    constant STAT_TX_READY_BIT : natural := 5;
    constant STAT_RX_READY_BIT : natural := 4;
    constant STAT_TX_VALID_BIT : natural := 3;
    constant STAT_RX_VALID_BIT : natural := 2;
    constant STAT_TX_BUSY_BIT  : natural := 1;
    constant STAT_RX_BUSY_BIT  : natural := 0;

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
