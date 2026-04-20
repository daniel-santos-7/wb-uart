# AGENTS.md

## Project Type
VHDL UART core with Wishbone slave interface (uart_wbsl)

## Simulation
Uses GHDL (VHDL simulator). Command flow: import → make → run

```bash
make simulation    # Run full simulation (10ms stop time)
make clean        # Clean work directory and generated files
```

## Directory Structure
- `rtl/` - RTL source files (uart, uart_tx, uart_rx, fifo, uart_wbsl, uart_pkg)
- `tbs/` - Testbench files (uart_tb_pkg, uart_tb)
- `work/` - GHDL work library (generated)
- `waves/` - Waveform output

## Key Commands
- `make .import` - Import VHDL files into work library
- `make .make` - Elaborate design
- `make simulation` - Run testbench (stops at 10ms by default)

## Build System
- Uses GHDL with `--ieee=synopsys` and `--ieee-asserts=disable`
- Top testbench: `uart_tb`