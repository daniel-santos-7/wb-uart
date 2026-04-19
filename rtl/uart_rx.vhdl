library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_rx is
    port (
        clk:      in  std_logic;
        reset:    in  std_logic;
        baud_div: in  std_logic_vector(15 downto 0);
        wr:       out std_logic;
        wr_en:    in  std_logic;
        wr_data:  out std_logic_vector(7 downto 0);
        busy:     out std_logic;
        rx:       in  std_logic
    );
end entity uart_rx;

architecture uart_rx_arch of uart_rx is

    type state is (START, IDLE, RX_START, RX_DATA, RX_STOP);

    signal curr_state: state;
    signal next_state: state;

    signal uart_baud_val: std_logic_vector(15 downto 0);
    
    signal baud_counter_tc:   std_logic;
    signal baud_counter_clr:    std_logic;
    signal baud_counter_en:     std_logic;
    signal baud_counter_mode:  std_logic;
    signal baud_counter_val:   unsigned(15 downto 0);
    
    signal rx_counter_tc:   std_logic;
    signal rx_counter_val:   unsigned(2 downto 0);
    
    signal rx_shift_reg: std_logic_vector(7 downto 0);

begin
    
    fsm: process(clk)
    begin
        
        if rising_edge(clk) then
            
            if reset = '1' then
            
                curr_state <= START;
            
            else

                curr_state <= next_state;

            end if;

        end if;

    end process fsm;

    fsm_next_state: process(curr_state, wr_en, rx, baud_counter_tc, rx_counter_tc)
    begin
        
        case curr_state is
            
            when START =>
                
                next_state <= IDLE;
        
            when IDLE =>
                
                if wr_en = '1' and rx = '0' then

                    next_state <= RX_START;

                else

                    next_state <= IDLE;

                end if;

            when RX_START =>

                if baud_counter_tc = '1' then
                    
                    next_state <= RX_DATA;

                else

                    next_state <= RX_START;

                end if;

            when RX_DATA =>

                if  baud_counter_tc = '1' and rx_counter_tc = '1' then
                    
                    next_state <= RX_STOP;

                else

                    next_state <= RX_DATA;

                end if;

            when RX_STOP => 

                if baud_counter_tc = '1' then
                    
                    next_state <= IDLE;

                else

                    next_state <= RX_STOP;

                end if;
        
        end case;

    end process fsm_next_state;

    uart_baud_val <= baud_div;

    baud_counter_clr  <= '1' when curr_state = START else '0';
    baud_counter_en  <= '0' when curr_state = START else '1';

    baud_counter_mode <= '1' when curr_state = IDLE or baud_counter_tc = '1' else '0';

    baud_counter: process(clk)
    begin
        if rising_edge(clk) then
            if baud_counter_clr = '1' then
                baud_counter_val <= unsigned(uart_baud_val);
            elsif baud_counter_en = '1' then
                if baud_counter_mode = '1' then
                    if curr_state = RX_START then
                        baud_counter_val <= unsigned('0' & uart_baud_val(15 downto 1));
                    else
                        baud_counter_val <= unsigned(uart_baud_val);
                    end if;
                elsif baud_counter_val = 0 then
                    baud_counter_val <= unsigned(uart_baud_val);
                else
                    baud_counter_val <= baud_counter_val - 1;
                end if;
            end if;
        end if;
    end process baud_counter;

    baud_counter_tc <= '1' when baud_counter_val = 0 else '0';

    rx_counter: process(clk)
    begin
        if rising_edge(clk) then
            if curr_state = START then
                rx_counter_val <= (others => '1');
            elsif baud_counter_tc = '1' and curr_state = RX_DATA then
                rx_counter_val <= rx_counter_val - 1;
            end if;
        end if;
    end process rx_counter;

    rx_counter_tc <= '1' when rx_counter_val = 0 else '0';

    rx_shift: process(clk)
    begin
        if rising_edge(clk) then
            if curr_state = START then
                rx_shift_reg <= (others => '1');
            elsif baud_counter_tc = '1' and (curr_state = RX_START or curr_state = RX_DATA) then
                rx_shift_reg <= rx & rx_shift_reg(7 downto 1);
            end if;
        end if;
    end process rx_shift;

    wr <= '1' when curr_state = RX_STOP and next_state = IDLE else '0';

    wr_data <= rx_shift_reg;

    busy <= '0' when curr_state = IDLE else '1';
    
end architecture uart_rx_arch;