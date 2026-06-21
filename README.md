# I2C Communication Protocol Using VHDL

## Overview

This project implements the Inter-Integrated Circuit (I2C) protocol using VHDL. The design supports communication between an I2C Master and Slave using two-wire serial communication.

The implementation includes start/stop condition generation, address transmission, data transfer, and acknowledgment handling.

---

## Features

* I2C Master Controller
* I2C Slave Device
* Start and Stop Condition Generation
* Address Transmission
* ACK/NACK Detection
* Serial Data Transfer
* FSM-Based Design
* Simulation Testbench

---

## I2C Signals

```text
SCL  - Serial Clock Line
SDA  - Serial Data Line
```

---

## Project Structure

```text
I2C_Project/
│
├── i2c_clk_generator.vhd
├── i2c_master_fsm.vhd
├── i2c_master_shift_reg.vhd
├── i2c_slave.vhd
├── i2c_top.vhd
├── tb_i2c_top.vhd
│
└── README.md
```

---

## I2C Frame Format

```text
START
↓
7-bit Slave Address
↓
R/W Bit
↓
ACK
↓
Data Byte
↓
ACK
↓
STOP
```

---

## Design Description

### Clock Generator

Generates the I2C clock (SCL) from the system clock.

### I2C Master FSM

Controls:

* START condition
* Address transmission
* Data transmission
* ACK checking
* STOP condition

### Shift Register

Converts parallel data into serial data for transmission on SDA.

### I2C Slave

Receives address and data from the master and generates ACK responses.

---

## Simulation Example

```text
Slave Address : 0x50
Data Sent     : A5h

Master → Slave

Address ACK   : Received
Data ACK      : Received

Status        : PASS
```

---

## Tools Used

* VHDL
* Xilinx Vivado
* Vivado Simulator

---

## Applications

* EEPROM Communication
* Temperature Sensors
* Real-Time Clock (RTC)
* Embedded Systems
* FPGA Peripheral Interfaces

---

## Future Improvements

* Multi-Master Support
* Clock Stretching
* Multiple Slave Devices
* Read and Write Transactions
* FIFO-Based Data Transfer

---

## Author

Developed as part of FPGA and Digital Communication learning using VHDL and Xilinx Vivado.
