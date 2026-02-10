# AXI4 DMA Controller — Design Requirements Spec

Each Design Requirement (DR) below is uniquely numbered and represents a measurable functionality or architectural constraint. These are to be used to guide RTL development and track status to RTL closure.

> Status: `TODO`, `IN PROGRESS`, or `DONE`

---

## 📌 Interface Requirements

| ID     | Title                        | Requirement                                                                 | Category   | Status       |
|--------|------------------------------|-----------------------------------------------------------------------------|------------|--------------|
| DR001  | APB Slave Interface          | The DMA shall expose an APB3-compatible slave interface for register access. | Interface  | TODO         |
| DR002  | AXI4 Master Interface        | The DMA shall expose a 32-bit AXI4 master interface for issuing read/write bursts. | Interface  | TODO         |
| DR003  | IRQ Output                   | The DMA shall expose a 1-bit level-sensitive `irq` output.                  | Interface  | TODO         |

---

## 📌 Functional Requirements

| ID     | Title                          | Requirement                                                                   | Category    | Status   |
|--------|--------------------------------|-------------------------------------------------------------------------------|-------------|----------|
| DR010  | Single One-Shot Transfer       | The DMA shall execute one complete memory-to-memory transfer per `START` command. | Functionality | TODO     |
| DR011  | AXI Burst Generation           | The DMA shall issue INCR-type AXI bursts with a fixed length of 4 beats where possible. | Functionality | TODO     |
| DR012  | AXI Error Detection            | The DMA shall detect `BRESP` or `RRESP` error responses and raise `STATUS.ERROR`. | Functionality | TODO     |
| DR013  | IRQ on Completion              | The DMA shall assert `irq` when a transfer completes or an error occurs and `IE=1`. | Functionality | TODO     |
| DR014  | Transfer Length Enforcement    | The DMA shall transfer exactly `LENGTH` bytes, no more and no less.          | Functionality | TODO     |
| DR015  | FIFO Buffered Data Path        | The DMA shall buffer data between AXI read and write via an internal FIFO.   | Functionality | TODO     |

---

## 📌 Control & Register Behavior

| ID     | Title                        | Requirement                                                                 | Category        | Status   |
|--------|------------------------------|-----------------------------------------------------------------------------|------------------|----------|
| DR020  | START Bit Behavior           | Writing `CONTROL.START=1` shall trigger a transfer and self-clear immediately. | Register Logic   | TODO     |
| DR021  | IE Bit Enable                | Writing `CONTROL.IE=1` shall enable interrupt generation on DONE or ERROR. | Register Logic   | TODO     |
| DR022  | DONE Flag                    | Upon successful transfer, `STATUS.DONE` shall be set until cleared by W1C. | Register Logic   | TODO     |
| DR023  | ERROR Flag                   | On error, `STATUS.ERROR` shall be set and retained until W1C clear.        | Register Logic   | TODO     |
| DR024  | BUSY Reflects Active State   | `STATUS.BUSY` shall be high from START until the transfer completes or errors. | Register Logic   | TODO     |

---

## 📌 Architectural Requirements

| ID     | Title                         | Requirement                                                                   | Category     | Status   |
|--------|-------------------------------|-------------------------------------------------------------------------------|--------------|----------|
| DR030  | FSM-Based Control             | The DMA shall be controlled by an FSM with IDLE, READ, WRITE, COMPLETE states. | Architecture | TODO     |
| DR031  | Single Outstanding TX         | The DMA shall issue only one read and one write AXI burst at a time.         | Architecture | TODO     |
| DR032  | 4KB Burst Boundary Compliance | The DMA shall not issue AXI bursts that cross 4KB boundaries.                | Architecture | TODO     |
| DR033  | FIFO Flow Control             | The DMA shall not issue AXI reads if FIFO is full, nor writes if FIFO is empty. | Architecture | TODO     |

---

## 📌 Initialization & Reset

| ID     | Title                     | Requirement                                                               | Category | Status |
|--------|---------------------------|---------------------------------------------------------------------------|----------|--------|
| DR040  | Reset Clears All State    | After reset, all registers and state shall return to default (IDLE, flags = 0). | Reset    | TODO   |
| DR041  | Ready for Reuse Post-IRQ  | The DMA shall support repeated use after clearing DONE or ERROR.         | Reset    | TODO   |

---