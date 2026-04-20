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

    signal uart_baud_val: std_logic_vector(15 downto 0);
    
    signal baud_counter_tc:   std_logic;
    signal baud_counter_clr:    std_logic;
    signal baud_counter_en:     std_logic;
    signal baud_counter_mode:  std_logic;
    signal baud_counter_val:   unsigned(15 downto 0);
    
    signal rx_counter_tc:   std_logic;
    signal rx_counter_val:   unsigned(2 downto 0);
    
    signal rx_shift_reg: std_logic_vector(7 downto 0);
    signal wr_reg: std_logic;
    signal busy_reg: std_logic;
    signal baud_counter_clr_reg: std_logic;
    signal baud_counter_en_reg: std_logic;

begin
    
    fsm: process(clk)
    begin
        
        if rising_edge(clk) then
            
            if reset = '1' then
            
                curr_state <= START;
                wr_reg <= '0';
                busy_reg <= '0';
                baud_counter_clr_reg <= '1';
                baud_counter_en_reg <= '0';
            
            else
            
                wr_reg <= '0';
                baud_counter_clr_reg <= '0';
                baud_counter_en_reg <= '1';
            
                case curr_state is
            
                    when START =>
                        
                        curr_state <= IDLE;
                        busy_reg <= '0';
                        baud_counter_clr_reg <= '1';
                        baud_counter_en_reg <= '0';
                
                    when IDLE =>
                        
                        if wr_en = '1' and rx = '0' then
        
                            curr_state <= RX_START;
                            busy_reg <= '1';
        
                        else
        
                            curr_state <= IDLE;
        
                        end if;
        
                    when RX_START =>
        
                        if baud_counter_tc = '1' then
                            
                            curr_state <= RX_DATA;
        
                        else
        
                            curr_state <= RX_START;
        
                        end if;
        
                    when RX_DATA =>
        
                        if  baud_counter_tc = '1' and rx_counter_tc = '1' then
                            
                            curr_state <= RX_STOP;
        
                        else
        
                            curr_state <= RX_DATA;
        
                        end if;
        
                    when RX_STOP => 
         
                        if baud_counter_tc = '1' then
                            
                            curr_state <= IDLE;
                            wr_reg <= '1';
                            busy_reg <= '0';
        
                        else
        
                            curr_state <= RX_STOP;
        
                        end if;
            
                end case;
        
            end if;
    
        end if;

    end process fsm;

    uart_baud_val <= baud_div;

    baud_counter_clr  <= baud_counter_clr_reg;
    baud_counter_en  <= baud_counter_en_reg;

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
            elsif baud_counter_tc = '1' and curr_state = RX_DATA then
                rx_shift_reg <= rx & rx_shift_reg(7 downto 1);
            end if;
        end if;
    end process rx_shift;

    wr <= wr_reg;
    busy <= busy_reg;

    wr_data <= rx_shift_reg;
    
end architecture uart_rx_arch;