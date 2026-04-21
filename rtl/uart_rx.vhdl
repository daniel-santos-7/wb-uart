library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_rx is
    port (
        clk_i:      in  std_logic;
        rst_i:      in  std_logic;
        baud_div_i: in  std_logic_vector(15 downto 0);
        valid_o:    out std_logic;
        ready_i:    in  std_logic;
        data_o:     out std_logic_vector(7 downto 0);
        busy_o:     out std_logic;
        rx_i:       in  std_logic
    );
end entity uart_rx;

architecture rtl of uart_rx is

    type state is (RX_IDLE, RX_START, RX_DATA, RX_STOP, RX_WRITE);

    signal state_reg : state;
    
    signal baud_cnt_sel : std_logic;
    signal baud_cnt_mux : unsigned(15 downto 0);

    signal baud_cnt_done  : std_logic;
    signal baud_cnt_val : unsigned(15 downto 0);
    
    signal rx_cnt_done  : std_logic;
    signal rx_cnt_val : unsigned(2 downto 0);
    
    signal rx_data_reg  : std_logic_vector(7 downto 0);
    
    signal valid_reg : std_logic;
    signal busy_reg      : std_logic;

begin
    
    ----------------------- Control Logic (FSM) --------------------------

    fsm: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state_reg <= RX_IDLE;
                valid_reg <= '0';
                busy_reg <= '0';
                baud_cnt_sel <= '0';
            else            
                case state_reg is
                    when RX_IDLE =>
                        if rx_i = '0' then
                            state_reg <= RX_START;
                            busy_reg <= '1';
                        end if;
                    when RX_START =>
                        if baud_cnt_done = '1' then
                            if rx_i = '1' then
                                state_reg <= RX_IDLE;
                                busy_reg <= '0';
                                baud_cnt_sel <= '0';
                            else
                                state_reg <= RX_DATA;
                                baud_cnt_sel <= '1';
                            end if;
                        end if;
                    when RX_DATA =>
                        if  baud_cnt_done = '1' and rx_cnt_done = '1' then
                            state_reg <= RX_STOP;
                        end if;
                    when RX_STOP => 
                        if baud_cnt_done = '1' then
                            if rx_i = '1' and ready_i = '1' then
                                state_reg <= RX_WRITE;
                                valid_reg <= '1';
                                busy_reg <= '0';
                                baud_cnt_sel <= '0';
                            else
                                state_reg <= RX_IDLE;
                                busy_reg <= '0';
                                baud_cnt_sel <= '0';
                            end if;
                        end if;
                    when RX_WRITE =>
                        state_reg <= RX_IDLE;
                        valid_reg <= '0';
                        busy_reg <= '0';
                        baud_cnt_sel <= '0';
                end case;
            end if;
        end if;
    end process fsm;

    ----------------------- Datapath Logic -----------------------------

    baud_cnt_mux_proc: process(baud_cnt_sel, baud_div_i)
    begin
        if baud_cnt_sel = '0' then
            baud_cnt_mux <= unsigned('0' & baud_div_i(15 downto 1));
        else
            baud_cnt_mux <= unsigned(baud_div_i);
        end if;
    end process baud_cnt_mux_proc;

    baud_counter: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' or busy_reg = '0' then
                baud_cnt_val <= (others => '0');
            else
                if baud_cnt_done = '1' then
                    baud_cnt_val <= (others => '0');
                else
                    baud_cnt_val <= baud_cnt_val + 1;
                end if;
            end if;
        end if;
    end process baud_counter;

    baud_cnt_done <= '1' when baud_cnt_val = baud_cnt_mux - 1 else '0';

    rx_counter: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rx_cnt_val <= (others => '0');
            elsif baud_cnt_done = '1' and state_reg = RX_DATA then
                rx_cnt_val <= rx_cnt_val + 1;
            end if;
        end if;
    end process rx_counter;

    rx_cnt_done <= '1' when rx_cnt_val = 7 else '0';

    rx_shift: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rx_data_reg <= (others => '0');
            elsif baud_cnt_done = '1' and state_reg = RX_DATA then
                rx_data_reg <= rx_i & rx_data_reg(7 downto 1);
            end if;
        end if;
    end process rx_shift;

    ------------------------------ Outputs  ------------------------------

    valid_o <= valid_reg;
    busy_o <= busy_reg;
    data_o <= rx_data_reg;
    
end architecture rtl;