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

entity fifo is
    generic (
        FIFO_DEPTH : natural := 8; -- Number of slots in the FIFO
        DATA_WIDTH : natural := 8  -- Width of each data slot
    );
    port (
        clk_i : in  std_logic; -- System clock
        rst_i : in  std_logic; -- Synchronous reset (active high)

        -- Input Interface
        valid_i : in  std_logic; -- Input data is valid (push)
        ready_i : in  std_logic; -- Downstream is ready (pop enable)
        data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Data to be stored

        -- Output Interface
        valid_o : out std_logic; -- FIFO is not empty (data available)
        ready_o : out std_logic; -- FIFO is not full (ready to accept data)
        data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)  -- Data at current read pointer
    );
end entity fifo;

architecture rtl of fifo is

    constant READ_OP  : std_logic := '0';
    constant WRITE_OP : std_logic := '1';

    type fifo_data_array is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fifo_data_reg : fifo_data_array; -- Memory array (inferable to BRAM)
    signal last_op_reg   : std_logic;       -- Tracks the last operation to resolve empty/full

    signal wr_ptr_reg : integer range 0 to FIFO_DEPTH-1; -- Write address pointer
    signal rd_ptr_reg : integer range 0 to FIFO_DEPTH-1; -- Read address pointer

    signal empty : std_logic; -- Internal empty flag
    signal full  : std_logic; -- Internal full flag

begin

    ----------------------- Datapath Logic -----------------------------

    -- Combinational data output
    data_o <= fifo_data_reg(rd_ptr_reg);

    -- Read pointer management
    read_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rd_ptr_reg <= 0;
            elsif ready_i = '1' and empty = '0' then
                if rd_ptr_reg = FIFO_DEPTH - 1 then
                    rd_ptr_reg <= 0;
                else
                    rd_ptr_reg <= rd_ptr_reg + 1;
                end if;
            end if;
        end if;
    end process read_proc;

    -- Write data and pointer management
    write_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                wr_ptr_reg <= 0;
            elsif valid_i = '1' and full = '0' then
                fifo_data_reg(wr_ptr_reg) <= data_i;
                if wr_ptr_reg = FIFO_DEPTH - 1 then
                    wr_ptr_reg <= 0;
                else
                    wr_ptr_reg <= wr_ptr_reg + 1;
                end if;
            end if;
        end if;
    end process write_proc;

    -- Tracks the last operation to differentiate between empty and full when pointers are equal
    last_op_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                last_op_reg <= READ_OP;
            elsif ready_i = '1' and valid_i = '0' then
                last_op_reg <= READ_OP;
            elsif ready_i = '0' and valid_i = '1' then
                last_op_reg <= WRITE_OP;
            end if;
        end if;
    end process last_op_proc;

    ------------------------- Control Logic ----------------------------

    empty <= '1' when wr_ptr_reg = rd_ptr_reg and last_op_reg = READ_OP  else '0';
    full  <= '1' when wr_ptr_reg = rd_ptr_reg and last_op_reg = WRITE_OP else '0';

    ------------------------------ Outputs ------------------------------

    valid_o <= not empty;
    ready_o <= not full;

end architecture rtl;
