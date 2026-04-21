# Gemini Context: WB-UART

This project implements a UART (Universal Asynchronous Receiver-Transmitter) IP core with a Wishbone Slave interface, written in VHDL.

## Project Overview

- **Purpose:** A synthesizable UART peripheral for SoC (System on Chip) designs.
- **Interface:** Wishbone B3 compatible slave interface.
- **Technologies:** VHDL-93, GHDL (simulation).
- **Key Features:**
  - Configurable baud rate via a 16-bit divider register.
  - 8-byte deep FIFOs for both transmit and receive paths.
  - Status register for monitoring FIFO states and UART busy flags.

## Architecture

The design is modularized into several components:

- `rtl/uart_wbsl.vhdl`: Wishbone Slave wrapper that translates Wishbone cycles into internal register accesses.
- `rtl/uart.vhdl`: The top-level UART logic, containing the register file and FIFO instantiations.
- `rtl/uart_tx.vhdl`: Transmitter logic (serializer).
- `rtl/uart_rx.vhdl`: Receiver logic (deserializer with oversampling).
- `rtl/fifo.vhdl`: A generic synchronous FIFO used for buffering.
- `rtl/uart_pkg.vhdl`: Package defining components and shared constants.

### Register Map (2-bit address space)

| Address | Register | Description |
|---------|----------|-------------|
| `00`    | STAT     | Status: TX/RX FIFO status and Busy flags |
| `01`    | CTRL     | Control (currently fixed/unused) |
| `10`    | BRDV     | Baud Rate Divider (16-bit) |
| `11`    | TXRX     | Data Register (Write for TX, Read for RX) |

## Building and Running

The project uses a `Makefile` for automation with `ghdl`.

### Prerequisites
- `ghdl` (VHDL simulator)
- `make`

### Commands
- **Run Simulation:**
  ```bash
  make simulation
  ```
  This compiles the design and runs the testbench (`tbs/uart_tb.vhdl`), printing results to stdout.

- **Generate Waveforms:**
  ```bash
  make
  ```
  Compiles and runs the simulation, generating a GHW wave file at `waves/uart_tb.ghw`. You can view this using `gtkwave`.

- **Clean Build Artifacts:**
  ```bash
  make clean
  ```

## Development Conventions

- **Directory Structure:**
  - `rtl/`: Contains all synthesizable VHDL source files.
  - `tbs/`: Contains testbenches and simulation-only models.
  - `work/`: Intermediate directory for GHDL compilation artifacts.
  - `waves/`: Output directory for simulation waveform files.
- **Coding Style:**
  - Standard IEEE libraries (`std_logic_1164`, `numeric_std`) are preferred.
  - Components are declared in `uart_pkg.vhdl`.
  - Asynchronous reset (active high) is used throughout the design.
- **Testing:**
  - `tbs/uart_tb.vhdl` is the main testbench.
  - `tbs/uart_tb_pkg.vhdl` provides helper procedures for Wishbone transactions and UART signal emulation.
