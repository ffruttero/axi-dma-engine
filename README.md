# AXI4 DMA Controller — RTL + UVM Verification Project

## 📌 Overview

This repository contains a complete RTL design and UVM-based verification environment for a parameterizable **AXI4 Memory-to-Memory DMA Controller** with an APB configuration interface.

The project demonstrates:

- Clean, synthesizable SystemVerilog RTL
- AXI4 and APB protocol compliance
- FIFO-based burst decoupling architecture
- Structured finite state machine control
- UVM testbench with scoreboard and agents
- Modular, scalable repository organization
- Industry-style documentation and build flow

This project is designed for a portfolio-grade ASIC verification showcase, reflecting best practices used in real semiconductor environments.

---

# 🧠 Design Summary

The DMA controller performs autonomous memory-to-memory transfers using:

- **APB Slave Interface** for configuration
- **AXI4 Master Interface** for data movement
- **Internal FIFO buffer** for read/write decoupling
- **Burst-based transfer logic**
- **Interrupt generation on completion or error**

## High-Level Architecture

```
CPU (APB)
   │
   ▼
┌─────────────┐
│  APB RegBlk │
└─────────────┘
        │
        ▼
┌─────────────┐
│  DMA CTRL   │  ← FSM (IDLE / READ / WRITE / COMPLETE)
└─────────────┘
   │        │
   ▼        ▼
┌───────┐  ┌────────┐
│Reader │  │ Writer │
└───────┘  └────────┘
     │        ▲
     ▼        │
     └── FIFO ┘
```

---

# 🚀 Key Features

### ✅ AXI4 Master Support
- Incremental bursts (INCR)
- Configurable data width
- 4-beat burst default
- 4KB boundary protection
- Proper WSTRB handling for partial transfers (TODO)
- Single outstanding burst model (simplified, deterministic)

### ✅ APB Configuration Interface
- Memory-mapped register block
- START + IRQ enable
- Sticky DONE and ERROR bits (W1C behavior)
- Secure access filtering via PPROT
- Level-sensitive interrupt generation

### ✅ Internal FIFO
- Parameterizable depth
- Circular pointer design
- Full/empty detection using next-pointer logic
- Read/write decoupling between AXI channels

### ✅ Robust FSM Control
States:
- `IDLE`
- `WAIT_START`
- `READ`
- `WRITE`
- `COMPLETE`

Handles:
- Burst sequencing
- Length tracking
- Error propagation
- Status signaling

---

# 🧪 Verification Environment (UVM)

The testbench is fully UVM-compliant and structured for scalability.

## Components

- UVM Environment (`dma_env`)
- APB Agent (active)
- AXI Agent (passive or memory model)
- Scoreboard (data comparison)
- Reference memory model
- Sequences for DMA transactions
- Multiple test scenarios

## Example Tests

- `smoke_test`
- `error_test`
- Burst boundary tests
- Unaligned transfer handling
- Backpressure injection
- Protocol error injection

---

# 📁 Repository Structure

```
axi_dma_controller/
├── README.md
├── doc/
│   ├── HAS.md
│   └── HighLevelSpec.md
├── rtl/
│   ├── dma_top.sv
│   ├── dma_ctrl.sv
│   ├── dma_reader.sv
│   ├── dma_writer.sv
│   ├── dma_fifo.sv
│   ├── apb_if.sv
│   └── apb_regs.sv
├── tb/
│   ├── top_tb.sv
│   ├── dut_interfaces.sv
│   ├── reference_memory.sv
│   ├── uvm_env/
│   ├── uvm_sequences/
│   ├── uvm_tests/
│   └── run_sim.do
├── scripts/
│   ├── compile.tcl
│   ├── run_all.tcl
│   └── lint.tcl
└── Makefile
```

---

# 🏗️ Build & Simulation

This project supports:

- QuestaSim flow
- Verilator lint flow
- Makefile-based automation
- Script-based batch regression

Example usage:

```bash
make comp
make elab
make sim TEST=smoke_test SEED=123
```

---

# 📚 What This Project Demonstrates

This project was built to demonstrate competency in:

- SystemVerilog RTL coding (synthesizable)
- AXI4 protocol understanding
- APB register design
- FIFO architecture design
- FSM design methodology
- Error handling strategies
- Sticky status register modeling
- UVM environment architecture
- Scoreboard design
- Verification planning
- Structured repository organization
- Clean modular hierarchy

---

# 📈 Future Improvements

Planned extensions:

- Multiple outstanding AXI bursts
- Configurable burst sizes
- Scatter-gather descriptor support
- Performance counters
- Coverage-driven regression
- Formal property checks
- AXI protocol assertions
- GitHub CI integration

---

# 👤 Author

Federico Fruttero
ASIC Design Verification Engineer  
SystemVerilog • UVM • AXI • APB • DMA Architecture  

---

# 📜 License

This project is provided for educational and portfolio purposes.
