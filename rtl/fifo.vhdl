----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: fifo
-- description: generic circular buffer (optimized for synthesis)
-- license: MIT
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity fifo is
    generic (
        FIFO_DEPTH : positive := 8;
        DATA_WIDTH : positive := 8
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;

        valid_i : in  std_logic; -- Push
        ready_i : in  std_logic; -- Pop
        data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        valid_o : out std_logic; -- Not empty
        ready_o : out std_logic; -- Not full
        data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0) -- Head, combinational
    );
end entity fifo;

architecture rtl of fifo is

    constant ADDR_WIDTH : natural := clog2(FIFO_DEPTH);

    type fifo_data_array is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fifo_data_reg : fifo_data_array;

    signal wr_ptr_reg : unsigned(ADDR_WIDTH-1 downto 0);
    signal rd_ptr_reg : unsigned(ADDR_WIDTH-1 downto 0);

    signal wr_ptr_next : unsigned(ADDR_WIDTH-1 downto 0);
    signal rd_ptr_next : unsigned(ADDR_WIDTH-1 downto 0);

    signal empty_reg : std_logic;
    signal full_reg  : std_logic;

    signal pushing : std_logic;
    signal popping : std_logic;

begin

    pushing <= valid_i and not full_reg;
    popping <= ready_i and not empty_reg;

    wr_ptr_next <= (others => '0') when wr_ptr_reg = FIFO_DEPTH - 1 else wr_ptr_reg + 1;
    rd_ptr_next <= (others => '0') when rd_ptr_reg = FIFO_DEPTH - 1 else rd_ptr_reg + 1;

    memory_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if pushing = '1' then
                fifo_data_reg(to_integer(wr_ptr_reg)) <= data_i;
            end if;
        end if;
    end process memory_proc;

    data_o <= fifo_data_reg(to_integer(rd_ptr_reg));

    write_pointer_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                wr_ptr_reg <= (others => '0');
            elsif pushing = '1' then
                wr_ptr_reg <= wr_ptr_next;
            end if;
        end if;
    end process write_pointer_proc;

    read_pointer_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rd_ptr_reg <= (others => '0');
            elsif popping = '1' then
                rd_ptr_reg <= rd_ptr_next;
            end if;
        end if;
    end process read_pointer_proc;

    -- Full/empty flags without an occupancy counter; a simultaneous push and pop keeps both
    status_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                empty_reg    <= '1';
                full_reg     <= '0';
            else
                if pushing = '1' and popping = '0' then
                    empty_reg <= '0';
                    if wr_ptr_next = rd_ptr_reg then
                        full_reg <= '1';
                    end if;
                elsif popping = '1' and pushing = '0' then
                    full_reg <= '0';
                    if rd_ptr_next = wr_ptr_reg then
                        empty_reg <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process status_proc;

    valid_o <= not empty_reg;
    ready_o <= not full_reg;

end architecture rtl;
