library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_rx is
    port (
        clk:       in  std_logic;
        reset:     in  std_logic;
        baud_div:  in  std_logic_vector(15 downto 0);
        out_valid: out std_logic;
        in_ready:  in  std_logic;
        out_data:  out std_logic_vector(7 downto 0);
        busy:      out std_logic;
        rx:        in  std_logic
    );
end entity uart_rx;

architecture rtl of uart_rx is

    type state is (RX_IDLE, RX_START, RX_DATA, RX_STOP, RX_WRITE);

    signal state_reg : state;
    
    signal baud_counter_sel : std_logic;
    signal baud_counter_mux : unsigned(15 downto 0);

    signal baud_counter_tc  : std_logic;
    signal baud_counter_val : unsigned(15 downto 0);
    
    signal rx_counter_tc  : std_logic;
    signal rx_counter_val : unsigned(2 downto 0);
    
    signal rx_shift_reg  : std_logic_vector(7 downto 0);
    
    signal out_valid_reg : std_logic;
    signal busy_reg      : std_logic;

begin
    
    -- Control FSM --

    fsm: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state_reg <= RX_IDLE;
                out_valid_reg <= '0';
                busy_reg <= '0';
                baud_counter_sel <= '0';
            else            
                case state_reg is
                    when RX_IDLE =>
                        if rx = '0' then
                            state_reg <= RX_START;
                            busy_reg <= '1';
                        end if;
                    when RX_START =>
                        if baud_counter_tc = '1' then
                            if rx = '1' then
                                state_reg <= RX_IDLE;
                                busy_reg <= '0';
                                baud_counter_sel <= '0';
                            else
                                state_reg <= RX_DATA;
                                baud_counter_sel <= '1';
                            end if;
                        end if;
                    when RX_DATA =>
                        if  baud_counter_tc = '1' and rx_counter_tc = '1' then
                            state_reg <= RX_STOP;
                        end if;
                    when RX_STOP => 
                        if baud_counter_tc = '1' then
                            if rx = '1' and in_ready = '1' then
                                state_reg <= RX_WRITE;
                                out_valid_reg <= '1';
                                busy_reg <= '0';
                                baud_counter_sel <= '0';
                            else
                                state_reg <= RX_IDLE;
                                busy_reg <= '0';
                                baud_counter_sel <= '0';
                            end if;
                        end if;
                    when RX_WRITE =>
                        state_reg <= RX_IDLE;
                        out_valid_reg <= '0';
                        busy_reg <= '0';
                        baud_counter_sel <= '0';
                end case;
            end if;
        end if;
    end process fsm;

    -- Datapath --

    baud_counter_mux_proc: process(baud_counter_sel, baud_div)
    begin
        if baud_counter_sel = '0' then
            baud_counter_mux <= unsigned('0' & baud_div(15 downto 1));
        else
            baud_counter_mux <= unsigned(baud_div);
        end if;
    end process baud_counter_mux_proc;

    baud_counter: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or busy_reg = '0' then
                baud_counter_val <= (others => '0');
            else
                if baud_counter_tc = '1' then
                    baud_counter_val <= (others => '0');
                else
                    baud_counter_val <= baud_counter_val + 1;
                end if;
            end if;
        end if;
    end process baud_counter;

    baud_counter_tc <= '1' when baud_counter_val = baud_counter_mux - 1 else '0';

    rx_counter: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_counter_val <= (others => '0');
            elsif baud_counter_tc = '1' and state_reg = RX_DATA then
                rx_counter_val <= rx_counter_val + 1;
            end if;
        end if;
    end process rx_counter;

    rx_counter_tc <= '1' when rx_counter_val = 7 else '0';

    rx_shift: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_shift_reg <= (others => '0');
            elsif baud_counter_tc = '1' and state_reg = RX_DATA then
                rx_shift_reg <= rx & rx_shift_reg(7 downto 1);
            end if;
        end if;
    end process rx_shift;

    -- Output assignments --
    out_valid <= out_valid_reg;
    busy <= busy_reg;
    out_data <= rx_shift_reg;
    
end architecture rtl;