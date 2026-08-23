# AXI4-Lite Master–Slave Communication System

## 1. Overview

This project implements a complete AXI4-Lite communication system consisting of a custom AXI4-Lite Master and AXI4-Lite Slave designed in Verilog RTL.

The system includes:

* A configurable AXI4-Lite Master controller.
* A register-based AXI4-Lite Slave peripheral.
* Full support for AXI4-Lite read and write transactions.
* Finite State Machines (FSMs) for transaction management.
* Byte-enable write support using the WSTRB signal.
* Protocol-compliant VALID/READY handshaking.
* Error handling using AXI response signals.

The AXI4-Lite Slave implements a register-file memory block in which specific address regions are configured as read-only or write-only. This allows the design to demonstrate protocol error responses for invalid access types.

## 2. System Architecture

The system consists of two primary modules:

### AXI4-Lite Master

The Master generates AXI4-Lite read and write transactions and controls the transaction flow using dedicated write and read FSMs.

### AXI4-Lite Slave

The Slave receives AXI4-Lite transactions and performs memory/register operations based on the requested address and access type.

Data transfer between the Master and Slave takes place through the five independent AXI4-Lite channels:

1. Write Address Channel
2. Write Data Channel
3. Write Response Channel
4. Read Address Channel
5. Read Data Channel

Each channel uses independent VALID/READY handshaking, allowing address, data, and response transfers to occur with flexible timing.

## 3. AXI4-Lite Interface Signals

### Clock and Reset

| Signal  | Direction | Description      |
| ------- | --------- | ---------------- |
| ACLK    | Input     | Global AXI clock |
| ARESETn | Input     | Active-low reset |

### Write Address Channel

| Signal  | Direction      | Description                                           |
| ------- | -------------- | ----------------------------------------------------- |
| AWADDR  | Master → Slave | Write address                                         |
| AWPROT  | Master → Slave | Protection attributes                                 |
| AWVALID | Master → Slave | Indicates that the write address is valid             |
| AWREADY | Slave → Master | Indicates that the Slave can accept the write address |

### Write Data Channel

| Signal | Direction      | Description                                        |
| ------ | -------------- | -------------------------------------------------- |
| WDATA  | Master → Slave | Write data                                         |
| WSTRB  | Master → Slave | Byte-enable strobes                                |
| WVALID | Master → Slave | Indicates that the write data is valid             |
| WREADY | Slave → Master | Indicates that the Slave can accept the write data |

### Write Response Channel

| Signal | Direction      | Description                                       |
| ------ | -------------- | ------------------------------------------------- |
| BRESP  | Slave → Master | Write response                                    |
| BVALID | Slave → Master | Indicates that the write response is valid        |
| BREADY | Master → Slave | Indicates that the Master can accept the response |

### Read Address Channel

| Signal  | Direction      | Description                                          |
| ------- | -------------- | ---------------------------------------------------- |
| ARADDR  | Master → Slave | Read address                                         |
| ARPROT  | Master → Slave | Protection attributes                                |
| ARVALID | Master → Slave | Indicates that the read address is valid             |
| ARREADY | Slave → Master | Indicates that the Slave can accept the read address |

### Read Data Channel

| Signal | Direction      | Description                                        |
| ------ | -------------- | -------------------------------------------------- |
| RDATA  | Slave → Master | Read data                                          |
| RRESP  | Slave → Master | Read response                                      |
| RVALID | Slave → Master | Indicates that read data is valid                  |
| RREADY | Master → Slave | Indicates that the Master can accept the read data |

## 4. AXI Response Encoding

| Response | Encoding | Description                     |
| -------- | -------- | ------------------------------- |
| OKAY     | `2'b00`  | Successful transaction          |
| EXOKAY   | `2'b01`  | Exclusive access success        |
| SLVERR   | `2'b10`  | Slave-generated error           |
| DECERR   | `2'b11`  | Decode error or invalid address |

## 5. Slave Memory Organization

The Slave implements a configurable register-file memory.

### Example Configuration

* **MEM_DEPTH:** 16 registers
* **DATA_WIDTH:** 32 bits
* **Total addressable range:** `0x00` to `0x3F` (0 to 63 decimal)

Each memory location stores 32-bit data.

Since AXI uses byte addressing while the internal memory is word-addressed, the word index is obtained using:

* **Write word address:** `AWADDR[5:2]`
* **Read word address:** `ARADDR[5:2]`

All accesses must be 32-bit aligned. Therefore:

`AWADDR[1:0] == 2'b00`

and

`ARADDR[1:0] == 2'b00`

An unaligned access generates an `SLVERR` response.

### Special Address Regions

| Byte Address Range | Word Index | Access Type | Description              |
| ------------------ | ---------: | ----------- | ------------------------ |
| `0x00–0x24`        |        0–9 | Read/Write  | Normal registers         |
| `0x28–0x30`        |      10–12 | Read-Only   | Status registers         |
| `0x34–0x38`        |      13–14 | Write-Only  | Command registers        |
| `0x3C`             |         15 | Read/Write  | Reserved/normal register |
| Others             |          — | Invalid     | Generates `DECERR`       |

## 6. Write Transaction Sequence

An AXI4-Lite write transaction follows these steps:

1. The Master asserts `AWVALID` with a valid write address.
2. The Master asserts `WVALID` with write data and byte strobes.
3. The Slave asserts `AWREADY` to accept the address.
4. The Slave asserts `WREADY` to accept the data.
5. The address and data channels may arrive independently and in any order.
6. Once both address and data transfers are completed, the Slave performs the memory write.
7. The Slave asserts `BVALID` with the appropriate write response.
8. The Master asserts `BREADY`.
9. The write transaction is completed when `BVALID` and `BREADY` are high on the same clock edge.

This behavior follows the AXI protocol rule that a transfer occurs only when both `VALID` and `READY` are asserted simultaneously.

## 7. Read Transaction Sequence

An AXI4-Lite read transaction follows these steps:

1. The Master asserts `ARVALID` with a valid read address.
2. The Slave asserts `ARREADY` to accept the address.
3. The Slave validates the address and retrieves the corresponding register data.
4. The Slave asserts `RVALID` with the read data and response.
5. The Master asserts `RREADY`.
6. The read transaction is completed when `RVALID` and `RREADY` are high on the same clock edge.

## 8. Write Channel FSM – Master

The Master write logic is controlled by a five-state FSM.

| State    | Description                     |
| -------- | ------------------------------- |
| `W_IDLE` | Waits for a write request       |
| `W_BOTH` | Sends both address and data     |
| `W_ADDR` | Waits for the address handshake |
| `W_DATA` | Waits for the data handshake    |
| `W_RESP` | Waits for the write response    |

### Operation

1. In `W_IDLE`, the Master waits for a write request.
2. In `W_BOTH`, the Master drives both the write address and write data channels.
3. If one handshake completes before the other, the FSM moves to `W_ADDR` or `W_DATA`.
4. Once both address and data handshakes are completed, the Master waits for `BVALID`.
5. When the write response is accepted through `BREADY`, the FSM returns to `W_IDLE`.

## 9. Read Channel FSM – Master

The Master read logic uses a three-state FSM.

| State    | Description              |
| -------- | ------------------------ |
| `R_IDLE` | Waits for a read request |
| `R_DATA` | Waits for read data      |

### Operation

1. In `R_IDLE`, the Master waits for a read request.
2. The Slave accepts the read address through the `ARVALID/ARREADY` handshake.
3. After the address is accepted, the Master waits for `RVALID`.
4. The Master captures the read data and response.
5. After the read transaction is completed, the FSM returns to `R_IDLE`.

## 10. Slave Write FSM

The Slave write logic supports independent arrival of the address and data channels.

| State    | Description                       |
| -------- | --------------------------------- |
| `W_IDLE` | Ready to accept address and data  |
| `W_BOTH` | Waiting for both address and data |
| `W_ADDR` | Address received first            |
| `W_DATA` | Data received first               |
| `W_RESP` | Generates the write response      |

### Features

* Supports decoupled address and data channels.
* Supports byte-enable writes using `WSTRB`.
* Detects invalid addresses.
* Prevents writes to read-only registers.
* Generates the appropriate AXI write response.

## 11. Slave Read FSM

The Slave read logic is implemented using a three-state FSM.

| State    | Description                  |
| -------- | ---------------------------- |
| `R_IDLE` | Waits for a read request     |
| `R_DATA` | Sends read data and response |

### Features

* Performs read-address validation.
* Generates error responses for accesses to write-only regions.
* Returns register data for valid read transactions.

## 12. Byte Enable Support Using WSTRB

The design supports partial-word updates using the `WSTRB` signal.

| WSTRB Bit  | Affected Data Bits |
| ---------- | ------------------ |
| `WSTRB[0]` | `[7:0]`            |
| `WSTRB[1]` | `[15:8]`           |
| `WSTRB[2]` | `[23:16]`          |
| `WSTRB[3]` | `[31:24]`          |

Each `WSTRB` bit controls whether the corresponding byte of the 32-bit register is updated.

For example, when a particular `WSTRB` bit is deasserted, the corresponding byte retains its previous value rather than being overwritten. This provides selective byte-level register updates.

## 13. Parallel Operation

The read and write FSMs operate independently. Therefore, the design allows read and write transactions to be processed concurrently, consistent with the independent nature of the AXI4-Lite read and write channels.

## 14. Design Assumptions

The following assumptions are made in the implementation of the AXI4-Lite Master and Slave:

* All AXI interface signals operate synchronously with the `ACLK` clock signal.
* `ARESETn` is an active-low reset signal that initializes the FSMs and interface signals.
* Address accesses are assumed to be word-aligned.
* The memory implemented in the Slave is limited to `MEM_DEPTH` registers.
* The Master follows the AXI protocol rule that `VALID` signals remain asserted until the corresponding `READY` signal is observed.
* Read and write channels operate independently and concurrently as defined by the AXI4-Lite specification.

## 15. Error Handling Behavior

The Slave generates AXI response signals based on the type and validity of the requested access.

| Condition                   | Response |
| --------------------------- | -------- |
| Unaligned address           | `SLVERR` |
| Address out of range        | `DECERR` |
| Write to read-only region   | `SLVERR` |
| Read from write-only region | `SLVERR` |
| Valid write                 | `OKAY`   |

These responses allow the Master to determine whether a transaction completed successfully or encountered an error.

## 16. Reset Behavior

When `ARESETn` is asserted low:

* All interface `VALID` signals are cleared.
* `READY` signals are reset to their default state.
* All finite state machines return to their respective `IDLE` states.
* Internal registers and memory elements are reset to zero.

This ensures that the AXI4-Lite Master–Slave interface and its internal state start from a known and deterministic condition after reset.

## 17. Summary

The AXI4-Lite Master–Slave Communication System provides a complete RTL implementation of AXI4-Lite communication with independent read and write channels. The design incorporates VALID/READY handshaking, independent Master and Slave FSMs, byte-enable write support, configurable register-file memory, address and access-type validation, protocol error responses, and concurrent read/write operation.

The implementation demonstrates the major functional aspects of an AXI4-Lite interface, including normal register accesses, partial-byte writes, read-only and write-only regions, invalid-address detection, unaligned-access detection, response generation, and reset handling.
