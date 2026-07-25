# WB-UART Project Overview

This project implements a simple and robust, synthesizable UART (Universal Asynchronous Receiver-Transmitter) IP core in VHDL-93, featuring a Wishbone B4 compatible slave interface. It focuses on a lightweight implementation with configurable baud rates, data widths (5-8 bits), and integrated FIFOs.

## Technology Stack
- **Language:** VHDL-93
- **Simulator/Synthesis Tool:** [GHDL](https://github.com/ghdl/ghdl)
- **Interface:** Wishbone B4 Slave
- **Build System:** GNU Make

## Project Structure
- `rtl/`: Core synthesizable logic.
  - `uart_pkg.vhdl`: Component, constant and utility declarations.
  - `fifo.vhdl`: Synchronous FIFO implementation (optimized for BRAM).
  - `uart_tx.vhdl` / `uart_rx.vhdl`: Serializer and deserializer logic.
  - `uart_csrs.vhdl`: Control and Status Registers (CSRs).
  - `uart.vhdl`: Main UART logic integration (Datapath).
  - `uart_wbsl.vhdl`: Wishbone B4 Slave wrapper (Top Level).
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

### Synthesis
To convert the VHDL design into a synthesizable Verilog file:
```bash
make synthesis
```

### Cleanup
To remove all build artifacts and temporary files:
```bash
make clean
```

## Development Conventions

### Coding Style
- **Naming:** 
  - Input ports: Suffix `_i` (e.g., `clk_i`, `data_i`).
  - Output ports: Suffix `_o` (e.g., `ack_o`, `tx_o`, `ready_o`).
  - Internal signals: Registered signals use `_reg` suffix. Use `valid`/`ready`/`data` pattern.
- **Reset:** Fully synchronous reset (`rst_i`) is used throughout the design.
- **Generics:** Use `FIFO_DEPTH` and `DATA_WIDTH` to configure the core at instantiation.
- **Packages:** All components are declared in `rtl/uart_pkg.vhdl`. Use `work.uart_pkg.all` in all entities.
- **Hierarchy:** `uart_wbsl` (Top) -> (`uart_csrs` & `uart`) -> (`uart_tx`, `uart_rx`, `fifo`).

### Testing Practices
- Testbenches are located in `tbs/`.
- Use `uart_tb_pkg.vhdl` for bus functional models.
- Waveforms are generated in GHW format and stored in the `waves/` directory.
