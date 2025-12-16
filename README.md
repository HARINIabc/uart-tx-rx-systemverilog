# UART Transmitter and Receiver (SystemVerilog)

A simple and reliable implementation of a **UART transmitter and receiver** in **SystemVerilog**, supporting standard 8-bit UART communication with start and stop bits.  
The design includes **baud-rate timing**, **FSM-based control**, and **TX–RX loopback verification**.

---

## Features

- UART Transmitter (TX)
- UART Receiver (RX)
- 8-bit data frames (LSB first)
- Start bit and stop bit handling
- Parameterized clock frequency and baud rate
- FSM-based implementation
- End-to-end loopback testbench

---

## UART Configuration

- Clock frequency: **50 MHz**
- Baud rate: **9600**
- Data bits: **8**
- Parity: **None**
- Stop bits: **1**

UART frame format:
Idle (1) → Start (0) → 8 Data Bits → Stop (1)


---

## File Structure
.
├── uart_tx.v # UART transmitter
├── uart_rx.v # UART receiver
├── uart_loopback_tb.v # TX–RX loopback testbench
└── README.md

---

## Simulation

### Requirements
- Icarus Verilog
- GTKWave

### Run loopback simulation

```bash
iverilog -g2012 -o uart_loopback_tb.vvp uart_tx.v uart_rx.v uart_loopback_tb.v
vvp uart_loopback_tb.vvp
gtkwave uart_loopback.vcd



