# WB-UART Project Overview

This project implements a simple and robust, synthesizable UART (Universal Asynchronous Receiver-Transmitter) IP core in VHDL-93, featuring a Wishbone B3 compatible slave interface. It focuses on a lightweight implementation with configurable baud rates and integrated FIFOs for efficient data handling.

## Technology Stack
- **Language:** VHDL-93
- **Simulator/Synthesis Tool:** [GHDL](https://github.com/ghdl/ghdl)
- **Interface:** Wishbone B3 Slave
- **Build System:** GNU Make

## Project Structure
- `rtl/`: Core synthesizable logic.
  - `uart_pkg.vhdl`: Component and constant declarations.
  - `fifo.vhdl`: Synchronous FIFO implementation.
  - `uart_tx.vhdl` / `uart_rx.vhdl`: Serializer and deserializer logic with registered control paths.
  - `uart.vhdl`: Main UART logic and register file.
  - `uart_wbsl.vhdl`: Wishbone B3 Slave wrapper (Top Level).
- `tbs/`: Testbenches and simulation models.
  - `uart_tb_pkg.vhdl`: Simulation helper procedures (Wishbone/UART bus models).
  - `uart_tb.vhdl`: Main system-level testbench.
- `syn/`: Directory for generated synthesis artifacts (e.g., Verilog).
- `work/`: GHDL intermediate build artifacts.
- `waves/`: Simulation waveform files (`.ghw`).

## Building and Running

### Simulation
To compile the RTL and testbenches, and run the simulation:
```bash
make simulation
```
This will run the testbench and verify basic UART functionality (TX/RX and Wishbone access).

### Synthesis
To convert the VHDL design into a synthesizable Verilog file:
```bash
make synthesis
```
The output will be generated at `syn/uart_wbsl.v`.

### Cleanup
To remove all build artifacts and temporary files:
```bash
make clean
```

## Development Conventions

### Coding Style
- **Naming:** 
  - Input ports: Suffix `_i` (e.g., `clk_i`, `dat_i`).
  - Output ports: Suffix `_o` (e.g., `ack_o`, `tx_o`).
  - Internal signals: No specific suffix, but usually descriptive.
- **Reset:** Fully synchronous reset (`rst_i`) is preferred and used throughout the design.
- **Packages:** All components are declared in `rtl/uart_pkg.vhdl`. Use `work.uart_pkg.all` in all entities.
- **Hierarchy:** `uart_wbsl` (WB Wrapper) -> `uart` (Core) -> `uart_tx`/`uart_rx`/`fifo`.

### Testing Practices
- Testbenches are located in `tbs/`.
- Use `uart_tb_pkg.vhdl` for bus functional models (BFMs) like `wb_write`, `wb_read`, `uart_transmit`, and `uart_expect` to keep testbenches readable.
- Waveforms are generated in GHW format and stored in the `waves/` directory for debugging.
