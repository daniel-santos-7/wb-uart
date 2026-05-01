----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_rx
-- description: UART receiver with mid-bit sampling
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_rx is
    port (
        clk_i:      in  std_logic;
        rst_i:      in  std_logic;
        rx_i:       in  std_logic;
        ready_i:    in  std_logic;
        div_i:      in  std_logic_vector(15 downto 0);
        busy_o:     out std_logic;
        valid_o:    out std_logic;
        data_o:     out std_logic_vector(7 downto 0)
    );
end entity uart_rx;

architecture rtl of uart_rx is

    type state is (RX_IDLE, RX_START, RX_DATA, RX_STOP, RX_WRITE);

    signal state_reg : state;

    signal baud_cnt_sel_reg : std_logic;
    signal baud_cnt_en_reg  : std_logic;
    signal rx_data_en_reg   : std_logic;
    signal valid_reg        : std_logic;
    
    signal baud_cnt_mux : unsigned(15 downto 0);
    signal baud_cnt_reg : unsigned(15 downto 0);
    signal rx_cnt_reg   : unsigned(2 downto 0);
    signal rx_data_reg  : std_logic_vector(7 downto 0);
    
    signal baud_cnt_done : std_logic;
    signal rx_cnt_done   : std_logic;

begin
    
    ----------------------- Control Logic (FSM) --------------------------

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state_reg <= RX_IDLE;
                valid_reg <= '0';
                baud_cnt_en_reg <= '0';
                baud_cnt_sel_reg <= '0';
                rx_data_en_reg <= '0';
            else            
                case state_reg is
                    when RX_IDLE =>
                        if rx_i = '0' then
                            state_reg <= RX_START;
                            baud_cnt_en_reg <= '1';
                        end if;
                    when RX_START =>
                        if baud_cnt_done = '1' then
                            if rx_i = '1' then
                                state_reg <= RX_IDLE;
                                baud_cnt_en_reg <= '0';
                                baud_cnt_sel_reg <= '0';
                            else
                                state_reg <= RX_DATA;
                                baud_cnt_sel_reg <= '1';
                                rx_data_en_reg <= '1';
                            end if;
                        end if;
                    when RX_DATA =>
                        if  baud_cnt_done = '1' and rx_cnt_done = '1' then
                            state_reg <= RX_STOP;
                            rx_data_en_reg <= '0';
                        end if;
                    when RX_STOP => 
                        if baud_cnt_done = '1' then
                            if rx_i = '1' and ready_i = '1' then
                                state_reg <= RX_WRITE;
                                valid_reg <= '1';
                                baud_cnt_en_reg <= '0';
                                baud_cnt_sel_reg <= '0';
                            else
                                state_reg <= RX_IDLE;
                                baud_cnt_en_reg <= '0';
                                baud_cnt_sel_reg <= '0';
                            end if;
                        end if;
                    when RX_WRITE =>
                        state_reg <= RX_IDLE;
                        valid_reg <= '0';
                        baud_cnt_en_reg <= '0';
                        baud_cnt_sel_reg <= '0';
                end case;
            end if;
        end if;
    end process fsm_proc;

    ----------------------- Datapath Logic -----------------------------

    baud_cnt_mux_proc: process(baud_cnt_sel_reg, div_i)
    begin
        if baud_cnt_sel_reg = '0' then
            baud_cnt_mux <= unsigned('0' & div_i(15 downto 1));
        else
            baud_cnt_mux <= unsigned(div_i);
        end if;
    end process baud_cnt_mux_proc;

    baud_cnt_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                baud_cnt_reg <= (others => '0');
            elsif baud_cnt_en_reg = '1' then
                if baud_cnt_done = '1' then
                    baud_cnt_reg <= (others => '0');
                else
                    baud_cnt_reg <= baud_cnt_reg + 1;
                end if;
            end if;
        end if;
    end process baud_cnt_proc;

    baud_cnt_done <= '1' when baud_cnt_reg = baud_cnt_mux - 1 else '0';

    rx_cnt_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rx_cnt_reg <= (others => '0');
            elsif baud_cnt_done = '1' and rx_data_en_reg = '1' then
                rx_cnt_reg <= rx_cnt_reg + 1;
            end if;
        end if;
    end process rx_cnt_proc;

    rx_cnt_done <= '1' when rx_cnt_reg = 7 else '0';

    rx_shift_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rx_data_reg <= (others => '0');
            elsif baud_cnt_done = '1' and rx_data_en_reg = '1' then
                rx_data_reg <= rx_i & rx_data_reg(7 downto 1);
            end if;
        end if;
    end process rx_shift_proc;

    ------------------------------ Outputs  ------------------------------

    busy_o <= baud_cnt_en_reg;
    valid_o <= valid_reg;
    data_o <= rx_data_reg;
    
end architecture rtl;
