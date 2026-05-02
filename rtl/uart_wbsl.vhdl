----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_wbsl
-- description: Wishbone B4 Slave wrapper
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart_wbsl is
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
end entity uart_wbsl;

architecture rtl of uart_wbsl is

    signal rd_en : std_logic;
    signal wr_en : std_logic;

    signal rd_data : std_logic_vector(15 downto 0);

begin

    ----------------------- Control Logic ----------------------------

    rd_en <= stb_i and cyc_i and not we_i;
    wr_en <= stb_i and cyc_i and we_i;

    ----------------------- Datapath Logic -----------------------------

    uart_inst: uart port map (
        clk     => clk_i,
        reset   => rst_i,
        rd      => rd_en,
        rd_addr => adr_i,
        rd_data => rd_data,
        wr      => wr_en,
        wr_addr => adr_i,
        wr_data => dat_i(15 downto 0),
        rx      => rx,
        tx      => tx
    );

    ------------------------------ Outputs ------------------------------

    ack_o <= stb_i and cyc_i;
    dat_o <= x"0000" & rd_data;

end architecture rtl;