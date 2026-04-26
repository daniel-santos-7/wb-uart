# WB-UART: Simple & Robust UART IP Core

A simple and robust, synthesizable UART (Universal Asynchronous Receiver-Transmitter) IP core written in VHDL-93, featuring a Wishbone B3 compatible slave interface.

## Key Features

- **Standard Interface:** Wishbone Slave (B3) compatible.
- **Minimal Footprint:** Optimized for low resource usage while maintaining high reliability.
- **Configurable Baud Rate:** 16-bit divider register for precise timing across various clock frequencies.
- **Deep Buffering:** Integrated 8-byte synchronous FIFOs for both Transmit (TX) and Receive (RX) paths.
- **Status Monitoring:** Real-time monitoring of FIFO states (full/empty) and UART busy flags via a dedicated status register.
- **Robust Receiver:** 
  - Two-stage synchronization for the `rx` input to prevent metastability.
  - Mid-bit sampling for start-bit validation and noise immunity.
  - Automatic discard of frames with stop-bit errors.
- **Timing-Optimized Design:** Registered FSM control signals decouple state decoding from the datapath, improving $F_{max}$ and ensuring consistent timing across synthesis targets.
- **Clean Architecture:** Fully synchronous reset design optimized for modern FPGAs.

## Register Map

The peripheral occupies a 2-bit address space (4 registers):

| Offset | Name | Access | Description |
|:------:|:----:|:------:|:-----------|
| `00`   | STAT | R      | Status Register (see below) |
| `01`   | CTRL | R/W    | Control Register (Reserved/Fixed) |
| `10`   | BRDV | R/W    | Baud Rate Divider (16-bit) |
| `11`   | TXRX | R/W    | Data: Write for TX / Read for RX |

### Status Register (STAT) Bits

| Bits  | Name       | Description |
|:-----:|:-----------|:------------|
| [5]   | TX_READY   | TX FIFO is not full (ready to receive data) |
| [4]   | RX_READY   | RX FIFO is not full (ready to receive from line) |
| [3]   | TX_VALID   | TX FIFO has data (valid for transmitter) |
| [2]   | RX_VALID   | RX FIFO has data (valid for Wishbone read) |
| [1]   | TX_BUSY    | UART Transmitter is active |
| [0]   | RX_BUSY    | UART Receiver is active |

## Project Structure

- `rtl/`: Synthesizable VHDL source files.
  - `uart_wbsl.vhdl`: Wishbone Slave wrapper.
  - `uart.vhdl`: Top-level core logic and register file.
  - `uart_tx.vhdl` / `uart_rx.vhdl`: Serializer and deserializer logic.
  - `fifo.vhdl`: Generic circular buffer implementation.
  - `uart_pkg.vhdl`: Component and constant declarations.
- `tbs/`: Testbenches and simulation models.
- `syn/`: Directory for generated synthesis artifacts (e.g., Verilog).
- `work/`: GHDL intermediate build artifacts.

## Usage

### Prerequisites

- [GHDL](https://github.com/ghdl/ghdl) for simulation and synthesis.
- `make` for automation.

### Running Simulation

To compile the design and run the standard testbench:
```bash
make simulation
```

### Synthesis (VHDL to Verilog)

To generate a synthesizable Verilog version of the IP core:
```bash
make synthesis
```
The output will be located at `syn/uart_wbsl.v`.

### Cleaning Build Artifacts

```bash
make clean
```

## License

This project is released under the MIT License.
