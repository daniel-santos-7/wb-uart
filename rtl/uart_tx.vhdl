----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_tx
-- description: UART transmitter
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_tx is
    generic (
        DATA_WIDTH : positive := 8
    );
    port (
        clk_i      : in  std_logic;
        rst_i      : in  std_logic;
        valid_i    : in  std_logic;
        data_i     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        baud_div_i : in  std_logic_vector(UART_BAUD_WIDTH-1 downto 0);
        en_i       : in  std_logic; -- A frame in progress completes when cleared
        tx_o       : out std_logic;
        busy_o     : out std_logic;
        ready_o    : out std_logic  -- Low for the whole frame and while disabled
    );
end entity uart_tx;

architecture rtl of uart_tx is

    type state is (TX_IDLE, TX_READ, TX_START, TX_DATA, TX_STOP);

    signal state_reg : state;

    signal baud_cnt_en_reg : std_logic;
    signal tx_data_en_reg  : std_logic;
    signal ready_reg       : std_logic;
    signal tx_reg          : std_logic;

    signal baud_div_reg : unsigned(UART_BAUD_WIDTH-1 downto 0);
    signal baud_cnt_reg : unsigned(UART_BAUD_WIDTH-1 downto 0);
    signal tx_cnt_reg   : integer range 0 to DATA_WIDTH-1;

    signal data_reg : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal baud_cnt_done : std_logic;
    signal tx_cnt_done   : std_logic;

begin

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state_reg       <= TX_IDLE;
                ready_reg       <= '1';
                tx_reg          <= '1';
                baud_cnt_en_reg <= '0';
                tx_data_en_reg  <= '0';
            else
                case state_reg is
                    when TX_IDLE =>
                        if valid_i = '1' and en_i = '1' then
                            state_reg <= TX_READ;
                            ready_reg <= '0';
                        end if;

                    when TX_READ =>
                        state_reg       <= TX_START;
                        tx_reg          <= '0';
                        baud_cnt_en_reg <= '1';

                    when TX_START =>
                        if baud_cnt_done = '1' then
                            state_reg      <= TX_DATA;
                            tx_reg         <= data_reg(0);
                            tx_data_en_reg <= '1';
                        end if;

                    when TX_DATA =>
                        if baud_cnt_done = '1' then
                            if tx_cnt_done = '1' then
                                state_reg      <= TX_STOP;
                                tx_reg         <= '1';
                                tx_data_en_reg <= '0';
                            else
                                tx_reg <= data_reg(0);
                            end if;
                        end if;

                    when TX_STOP =>
                        if baud_cnt_done = '1' then
                            state_reg       <= TX_IDLE;
                            ready_reg       <= '1';
                            tx_reg          <= '1';
                            baud_cnt_en_reg <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;

    -- BRDV writes take effect at the next frame
    baud_div_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                baud_div_reg <= (others => '0');
            elsif ready_reg = '1' then
                baud_div_reg <= unsigned(baud_div_i);
            end if;
        end if;
    end process baud_div_proc;

    baud_cnt_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                baud_cnt_reg <= (others => '0');
            elsif baud_cnt_en_reg = '1' then
                if baud_cnt_done = '1' then
                    baud_cnt_reg <= (others => '0');
                else
                    baud_cnt_reg <= (baud_cnt_reg + 1);
                end if;
            end if;
        end if;
    end process baud_cnt_proc;

    baud_cnt_done <= '1' when baud_cnt_reg = (baud_div_reg - 1) else '0';

    tx_cnt_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                tx_cnt_reg <= 0;
            elsif baud_cnt_done = '1' and tx_data_en_reg = '1' then
                if tx_cnt_done = '1' then
                    tx_cnt_reg <= 0;
                else
                    tx_cnt_reg <= tx_cnt_reg + 1;
                end if;
            end if;
        end if;
    end process tx_cnt_proc;

    tx_cnt_done <= '1' when tx_cnt_reg = DATA_WIDTH-1 else '0';

    -- LSB first
    data_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                data_reg <= (others => '0');
            elsif valid_i = '1' and ready_reg = '1' then
                data_reg <= data_i;
            elsif baud_cnt_done = '1' and (tx_data_en_reg = '1' or state_reg = TX_START) then
                data_reg <= '0' & data_reg(DATA_WIDTH-1 downto 1);
            end if;
        end if;
    end process data_reg_proc;

    tx_o    <= tx_reg;
    busy_o  <= baud_cnt_en_reg;
    ready_o <= ready_reg and en_i;

end architecture rtl;
