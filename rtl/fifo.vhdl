----------------------------------------------------------------------
-- Wishbone UART
-- developed by: Daniel Santos
-- module: fifo
-- description: generic circular buffer
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo is
    generic (
        FIFO_DEPTH : natural := 8;
        DATA_WIDTH : natural := 8
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        vld_i : in  std_logic;
        rdy_i : in  std_logic;
        dat_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        vld_o : out std_logic;
        rdy_o : out std_logic;
        dat_o : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity fifo;

architecture rtl of fifo is

    constant READ_OP  : std_logic := '0';
    constant WRITE_OP : std_logic := '1';

    type fifo_data_array is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fifo_data_reg : fifo_data_array;
    signal last_op_reg   : std_logic;

    signal wr_ptr_reg : integer range 0 to FIFO_DEPTH-1;
    signal rd_ptr_reg : integer range 0 to FIFO_DEPTH-1;

    signal empty : std_logic;
    signal full  : std_logic;

begin

    ----------------------- Datapath Logic -----------------------------

    dat_o <= fifo_data_reg(rd_ptr_reg);

    read_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                rd_ptr_reg <= 0;
            elsif rdy_i = '1' and empty = '0' then
                rd_ptr_reg <= (rd_ptr_reg + 1) mod FIFO_DEPTH;
            end if;
        end if;
    end process read_proc;

    write_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                fifo_data_reg <= (others => (others => '0'));
                wr_ptr_reg <= 0;
            elsif vld_i = '1' and full = '0' then
                fifo_data_reg(wr_ptr_reg) <= dat_i;
                wr_ptr_reg <= (wr_ptr_reg + 1) mod FIFO_DEPTH;
            end if;
        end if;
    end process write_proc;

    last_op_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                last_op_reg <= READ_OP;
            elsif rdy_i = '1' and vld_i = '0' then
                last_op_reg <= READ_OP;
            elsif rdy_i = '0' and vld_i = '1' then
                last_op_reg <= WRITE_OP;
            end if;
        end if;
    end process last_op_proc;

    ------------------------- Control Logic ----------------------------

    empty <= '1' when wr_ptr_reg = rd_ptr_reg and last_op_reg = READ_OP  else '0';
    full  <= '1' when wr_ptr_reg = rd_ptr_reg and last_op_reg = WRITE_OP else '0';

    ------------------------------ Outputs ------------------------------

    vld_o <= not empty;
    rdy_o <= not full;

end architecture rtl;
