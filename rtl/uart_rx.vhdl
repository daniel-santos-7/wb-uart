----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: uart_rx
-- description: UART receiver with mid-bit sampling
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_rx is
    generic (
        DATA_WIDTH : natural := 8 -- UART data word size (5 to 8 bits)
    );
    port (
        clk_i   : in  std_logic; -- System clock
        rst_i   : in  std_logic; -- Synchronous reset (active high)
        rx_i    : in  std_logic; -- Synchronized serial input line
        ready_i : in  std_logic; -- Downstream ready to receive data
        baud_div_i : in  std_logic_vector(15 downto 0); -- Baud rate divider value
        
        busy_o  : out std_logic; -- High during active reception
        valid_o : out std_logic; -- Pulses high when a valid word is received
        data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0) -- Received data word
    );
end entity uart_rx;

architecture rtl of uart_rx is

    type state is (RX_IDLE, RX_START, RX_DATA, RX_STOP, RX_WRITE);

    signal state_reg : state; -- FSM current state

    signal baud_cnt_sel_reg : std_logic; -- '0' for half-baud (start), '1' for full-baud
    signal baud_cnt_en_reg  : std_logic; -- Baud rate counter enable
    signal rx_data_en_reg   : std_logic; -- Data shift enable
    signal valid_reg        : std_logic; -- Internal valid flag
    
    signal baud_cnt_mux : unsigned(15 downto 0); -- Target value for baud counter
    signal baud_cnt_reg : unsigned(15 downto 0); -- Clock cycle counter for bit timing
    signal rx_cnt_reg   : integer range 0 to DATA_WIDTH-1; -- Received bit counter

    signal rx_data_reg  : std_logic_vector(DATA_WIDTH-1 downto 0); -- Shift register
    
    signal baud_cnt_done : std_logic; -- High when one bit period has elapsed
    signal rx_cnt_done   : std_logic; -- High when all data bits are received

begin
    
    ----------------------- Control Logic (FSM) --------------------------

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state_reg        <= RX_IDLE;
                valid_reg        <= '0';
                baud_cnt_en_reg  <= '0';
                baud_cnt_sel_reg <= '0';
                rx_data_en_reg   <= '0';
            else            
                case state_reg is
                    when RX_IDLE =>
                        if rx_i = '0' then -- Start bit detection
                            state_reg <= RX_START;
                            baud_cnt_en_reg <= '1';
                        end if;

                    when RX_START =>
                        if baud_cnt_done = '1' then
                            if rx_i = '1' then -- Glitch detection
                                state_reg        <= RX_IDLE;
                                baud_cnt_en_reg  <= '0';
                                baud_cnt_sel_reg <= '0';
                            else -- Valid start bit, move to sampling data
                                state_reg        <= RX_DATA;
                                baud_cnt_sel_reg <= '1'; -- Use full baud period
                                rx_data_en_reg   <= '1';
                            end if;
                        end if;

                    when RX_DATA =>
                        if  baud_cnt_done = '1' and rx_cnt_done = '1' then
                            state_reg      <= RX_STOP;
                            rx_data_en_reg <= '0';
                        end if;

                    when RX_STOP => 
                        if baud_cnt_done = '1' then
                            if rx_i = '1' and ready_i = '1' then -- Valid stop bit and space in FIFO
                                state_reg        <= RX_WRITE;
                                valid_reg        <= '1';
                                baud_cnt_en_reg  <= '0';
                                baud_cnt_sel_reg <= '0';
                            else -- Framing error or FIFO full, discard frame
                                state_reg <= RX_IDLE;
                                baud_cnt_en_reg <= '0';
                                baud_cnt_sel_reg <= '0';
                            end if;
                        end if;

                    when RX_WRITE => -- Wait state to pulse valid_o
                        state_reg        <= RX_IDLE;
                        valid_reg        <= '0';
                        baud_cnt_en_reg  <= '0';
                        baud_cnt_sel_reg <= '0';
                end case;
            end if;
        end if;
    end process fsm_proc;

    ----------------------- Datapath Logic -----------------------------

    -- Mux to select between half-baud (for mid-bit alignment) and full-baud
    baud_cnt_mux_proc: process(baud_cnt_sel_reg, baud_div_i)
    begin
        if baud_cnt_sel_reg = '0' then
            baud_cnt_mux <= unsigned('0' & baud_div_i(15 downto 1));
        else
            baud_cnt_mux <= unsigned(baud_div_i);
        end if;
    end process baud_cnt_mux_proc;

    -- Baud rate timing counter
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

    baud_cnt_done <= '1' when baud_cnt_reg = (baud_cnt_mux - 1) else '0';

    -- Data bit counter
    rx_cnt_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rx_cnt_reg <= 0;
            elsif baud_cnt_done = '1' and rx_data_en_reg = '1' then
                if rx_cnt_done = '1' then
                    rx_cnt_reg <= 0;
                else
                    rx_cnt_reg <= rx_cnt_reg + 1;
                end if;
            end if;
        end if;
    end process rx_cnt_proc;

    rx_cnt_done <= '1' when rx_cnt_reg = DATA_WIDTH-1 else '0';

    -- Serial to Parallel shift register
    rx_shift_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rx_data_reg <= (others => '0');
            elsif baud_cnt_done = '1' and rx_data_en_reg = '1' then
                rx_data_reg <= rx_i & rx_data_reg(DATA_WIDTH-1 downto 1);
            end if;
        end if;
    end process rx_shift_proc;

    ------------------------------ Outputs ------------------------------

    busy_o  <= baud_cnt_en_reg;
    valid_o <= valid_reg;
    data_o  <= rx_data_reg;
    
end architecture rtl;
