library IEEE;
use IEEE.std_logic_1164.all;

package uart_pkg is

    constant UART_DATA_WIDTH : natural := 8;
    constant UART_BAUD_WIDTH : natural := 16;

    component fifo is
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
    end component fifo;

    component uart_tx is
        port (
            clk_i:  in  std_logic;
            rst_i:  in  std_logic;
            div_i:  in  std_logic_vector(UART_BAUD_WIDTH-1 downto 0);
            vld_i:  in  std_logic;
            dat_i:  in  std_logic_vector(UART_DATA_WIDTH-1 downto 0);
            rdy_o:  out std_logic;
            busy_o: out std_logic;
            tx_o:   out std_logic
        );
    end component uart_tx;

    component uart_rx is
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
    end component uart_rx;

    component uart is
        port (
            clk:   in  std_logic;
            reset: in  std_logic;

            rd:      in  std_logic;
            rd_addr: in  std_logic_vector(1  downto 0);
            rd_data: out std_logic_vector(15 downto 0);

            wr:      in std_logic;
            wr_addr: in std_logic_vector(1  downto 0);
            wr_data: in std_logic_vector(15 downto 0);

            rx: in  std_logic;
            tx: out std_logic
        );
    end component uart;

    component uart_wbsl is
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            dat_i : in  std_logic_vector(31 downto 0);
            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            sel_i : in  std_logic_vector(3  downto 0);
            adr_i : in  std_logic_vector(1 downto 0);
            rx    : in  std_logic;
            ack_o : out std_logic;
            dat_o : out std_logic_vector(31 downto 0);
            tx    : out std_logic
        );
    end component uart_wbsl;

end package uart_pkg;
