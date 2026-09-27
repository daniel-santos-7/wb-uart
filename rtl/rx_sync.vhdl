----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: rx_sync
-- description: multi-stage synchronizer for the asynchronous RX line
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity rx_sync is
    generic (
        STAGES  : positive  := 2;  -- Number of flip-flops in the chain (>= 2)
        RST_VAL : std_logic := '1' -- Chain value after reset (RX line idle level)
    );
    port (
        clk_i : in  std_logic; -- Destination clock
        rst_i : in  std_logic; -- Synchronous reset (active high)
        rx_i  : in  std_logic; -- Asynchronous RX line
        rx_o  : out std_logic  -- Synchronized RX line, STAGES cycles of latency
    );
end entity rx_sync;

architecture rtl of rx_sync is

    signal sync_reg : std_logic_vector(STAGES-1 downto 0); -- sync_reg(0) samples rx_i

begin

    assert STAGES >= 2
        report "rx_sync: STAGES must be at least 2" severity failure;

    sync_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                sync_reg <= (others => RST_VAL);
            else
                sync_reg <= sync_reg(STAGES-2 downto 0) & rx_i;
            end if;
        end if;
    end process sync_proc;

    rx_o <= sync_reg(STAGES-1);

end architecture rtl;
