----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_tx
-- description: UART transmitter
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_tx is
    port (
        clk_i:   in  std_logic;
        rst_i:   in  std_logic;
        valid_i: in  std_logic;
        data_i:  in  std_logic_vector(7 downto 0);
        div_i:   in  std_logic_vector(15 downto 0);
        tx_o:    out std_logic;
        busy_o:  out std_logic;
        ready_o: out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is

    constant TX_COUNTER_MAX : unsigned(2 downto 0) := (others => '1');

    type state is (TX_IDLE, TX_READ, TX_START, TX_DATA, TX_STOP);

    signal state_reg : state;

    signal baud_cnt_en_reg : std_logic;
    signal tx_data_en_reg  : std_logic;
    signal ready_reg       : std_logic;
    signal tx_reg          : std_logic;

    signal baud_cnt_reg : unsigned(15 downto 0);
    signal tx_cnt_reg   : unsigned(2 downto 0);

    signal data_reg : std_logic_vector(7 downto 0);

    signal baud_cnt_done : std_logic;
    signal tx_cnt_done   : std_logic;

begin

    ----------------------- Control Logic (FSM) --------------------------

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state_reg <= TX_IDLE;
                ready_reg <= '1';
                tx_reg <= '1';
                baud_cnt_en_reg <= '0';
                tx_data_en_reg <= '0';
            else
                case state_reg is
                    when TX_IDLE =>
                        if valid_i = '1' then
                            state_reg <= TX_READ;
                            ready_reg <= '0';
                        end if;
                    when TX_READ =>
                        state_reg <= TX_START;
                        tx_reg <= '0';
                        baud_cnt_en_reg <= '1';
                    when TX_START =>
                        if baud_cnt_done = '1' then
                            state_reg <= TX_DATA;
                            tx_reg <= data_reg(0);
                            tx_data_en_reg <= '1';
                        end if;
                    when TX_DATA =>
                        if baud_cnt_done = '1' then
                            if tx_cnt_done = '1' then
                                state_reg <= TX_STOP;
                                tx_reg <= '1';
                                tx_data_en_reg <= '0';
                            else
                                tx_reg <= data_reg(0);
                            end if;
                        end if;
                    when TX_STOP =>
                        if baud_cnt_done = '1' then
                            state_reg <= TX_IDLE;
                            ready_reg <= '1';
                            tx_reg <= '1';
                            baud_cnt_en_reg <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;

    ----------------------- Datapath Logic -----------------------------

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

    baud_cnt_done <= '1' when baud_cnt_reg = (unsigned(div_i) - 1) else '0';

    tx_cnt_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                tx_cnt_reg <= (others => '0');
            elsif baud_cnt_done = '1' and tx_data_en_reg = '1' then
                if tx_cnt_done = '1' then
                    tx_cnt_reg <= (others => '0');
                else
                    tx_cnt_reg <= (tx_cnt_reg + 1);
                end if;
            end if;
        end if;
    end process tx_cnt_proc;

    tx_cnt_done <= '1' when tx_cnt_reg = TX_COUNTER_MAX else '0';

    data_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                data_reg <= (others => '0');
            elsif valid_i = '1' and ready_reg = '1' then
                data_reg <= data_i;
            elsif baud_cnt_done = '1' and (tx_data_en_reg = '1' or state_reg = TX_START) then
                data_reg <= '0' & data_reg(7 downto 1);
            end if;
        end if;
    end process data_reg_proc;

    ------------------------------ Outputs  ------------------------------

    tx_o <= tx_reg;
    busy_o <= baud_cnt_en_reg;
    ready_o <= ready_reg;

end architecture rtl;