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
        STAGES  : positive  := 2;
        RST_VAL : std_logic := '1' -- RX line idle level
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        rx_i  : in  std_logic; -- Asynchronous
        rx_o  : out std_logic  -- STAGES cycles of latency
    );
end entity rx_sync;

architecture rtl of rx_sync is

    signal sync_reg : std_logic_vector(STAGES-1 downto 0);

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
