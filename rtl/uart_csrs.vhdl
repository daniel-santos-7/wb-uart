----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_csrs
-- description: Control and Status Registers (CSRs) with Wishbone interface
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_csrs is
    port (
        clk_i   : in  std_logic;
        rst_i   : in  std_logic;

        -- Wishbone Interface
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        adr_i : in  std_logic_vector(1 downto 0);
        dat_i : in  std_logic_vector(31 downto 0);
        dat_o : out std_logic_vector(31 downto 0);
        ack_o : out std_logic;

        -- Internal Control/Status
        baud_div_o : out std_logic_vector(15 downto 0);
        
        tx_not_full_i : in  std_logic;
        rx_not_full_i : in  std_logic;
        tx_valid_i    : in  std_logic;
        rx_valid_i    : in  std_logic;
        tx_busy_i     : in  std_logic;
        rx_busy_i     : in  std_logic;
        
        -- Internal Data Interface
        tx_valid_o : out std_logic;
        tx_data_o  : out std_logic_vector(7 downto 0);
        rx_ready_o : out std_logic;
        rx_data_i  : in  std_logic_vector(7 downto 0)
    );
end entity uart_csrs;

architecture rtl of uart_csrs is

    constant STAT_ADDR : std_logic_vector(1 downto 0) := b"00";
    constant CTRL_ADDR : std_logic_vector(1 downto 0) := b"01";
    constant BRDV_ADDR : std_logic_vector(1 downto 0) := b"10";
    constant TXRX_ADDR : std_logic_vector(1 downto 0) := b"11";

    signal baud_div_reg : std_logic_vector(15 downto 0);
    
    signal rd_en : std_logic;
    signal wr_en : std_logic;
    
    signal status_reg : std_logic_vector(5 downto 0);

begin

    ----------------------- Control Logic ----------------------------

    rd_en <= stb_i and cyc_i and not we_i;
    wr_en <= stb_i and cyc_i and we_i;

    baud_div_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                baud_div_reg <= (others => '1');
            elsif wr_en = '1' and adr_i = BRDV_ADDR then
                baud_div_reg <= dat_i(15 downto 0);
            end if;
        end if;
    end process baud_div_proc;

    ----------------------- Datapath Logic -----------------------------

    baud_div_o <= baud_div_reg;

    tx_valid_o <= '1' when wr_en = '1' and adr_i = TXRX_ADDR else '0';
    tx_data_o  <= dat_i(7 downto 0);
    rx_ready_o <= '1' when rd_en = '1' and adr_i = TXRX_ADDR else '0';
    
    status_reg <= tx_not_full_i & rx_not_full_i & tx_valid_i & rx_valid_i & tx_busy_i & rx_busy_i;

    ------------------------------ Outputs ------------------------------

    ack_o <= stb_i and cyc_i;

    rd_mux_proc: process(rd_en, adr_i, status_reg, baud_div_reg, rx_data_i)
    begin
        if rd_en = '1' then
            case adr_i is
                when STAT_ADDR =>
                    dat_o(5 downto 0)   <= status_reg;
                    dat_o(31 downto 6)  <= (others => '0');
                when CTRL_ADDR =>
                    dat_o <= (1 downto 0 => '1', others => '0');
                when BRDV_ADDR =>
                    dat_o <= x"0000" & baud_div_reg;
                when TXRX_ADDR =>
                    dat_o(7 downto 0)   <= rx_data_i;
                    dat_o(31 downto 8)  <= (others => '0');
                when others =>
                    dat_o <= (others => '0');
            end case;
        else
            dat_o <= (others => '0');
        end if;
    end process rd_mux_proc;

end architecture rtl;
