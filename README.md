# WB-UART: Simple & Robust UART IP Core

A simple and robust, synthesizable UART (Universal Asynchronous Receiver-Transmitter) IP core written in VHDL-93, featuring a Wishbone B4 pipelined slave interface.

## Key Features

- **Standard Interface:** Wishbone B4 pipelined slave. Accepts one request per cycle (`STALL_O` is never asserted) and acknowledges it on the next cycle. Classic-cycle masters that hold `STB_I` until `ACK_O` are **not** supported: each access would be executed twice.
- **Fully Parameterizable:**
  - `FIFO_DEPTH`: Configurable buffer size (default: 8).
  - `DATA_WIDTH`: Configurable word size (default: 8), up to the 32-bit Wishbone data bus.
- **Minimal Footprint:** Optimized for low resource usage while maintaining high reliability.
- **Configurable Baud Rate:** 16-bit divider register for precise timing across various clock frequencies. Writing `0` (the reset value) turns the receiver and transmitter off; a frame in progress completes first, and TX data stays queued in the FIFO. The bit period is BRDV clock cycles. The transmitter works with any non-zero value; the receiver needs BRDV >= 2 to find the middle of each bit, and BRDV >= 16 is recommended so that line phase and baud mismatch stay a small fraction of the bit.
- **Deep Buffering:** Integrated synchronous FIFOs for both Transmit (TX) and Receive (RX) paths.
- **Status Monitoring:** Real-time monitoring of FIFO states (full/empty) and UART busy flags via a dedicated status register.
- **Robust Receiver:** 
  - Two-stage synchronization for the `rx_i` input to prevent metastability (`rx_sync`).
  - Mid-bit sampling for start-bit validation and noise immunity.
  - Automatic discard of frames with stop-bit errors.
- **Timing-Optimized Design:** Registered FSM control signals decouple state decoding from the datapath.
- **Clean Architecture:** Fully synchronous reset design with no vendor-specific primitives or attributes, portable to FPGA and ASIC flows.

## Register Map

The peripheral occupies a 2-bit address space (4 registers):

| Offset | Name | Access | Description |
|:------:|:----:|:------:|:-----------|
| `00`   | STAT | R      | Status Register (see below) |
| `01`   | CTRL | R      | Reserved. Reads as `0x3`; writes are ignored |
| `10`   | BRDV | R/W    | Baud Rate Divider (16-bit), applied at the start of the next frame. `0` (reset value) turns RX and TX off. Byte writes update only the lanes selected by `sel_i` |
| `11`   | TXRX | R/W    | Data: Write for TX / Read for RX (Width: `DATA_WIDTH`). A write is queued only when `sel_i` selects every byte lane covered by `DATA_WIDTH` |

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
  - `uart.vhdl`: Top-level core logic (Datapath).
  - `uart_csrs.vhdl`: Control and Status Registers (Bus Interface).
  - `uart_tx.vhdl` / `uart_rx.vhdl`: Serializer and deserializer logic.
  - `rx_sync.vhdl`: Multi-stage synchronizer for the asynchronous RX input.
  - `fifo.vhdl`: Generic circular buffer implementation.
  - `uart_pkg.vhdl`: Constant and utility declarations.
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
The testbench uses 8-bit data by default. To run it with another `DATA_WIDTH`:
```bash
make simulation DATA_WIDTH=7
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
