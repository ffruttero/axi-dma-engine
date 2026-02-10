# VerifProject


## 📁 Repository Structure

The GitHub repository structure for the RTL and UVM (Universal Verification Methodology) project is as follows:

```
axi_dma_controller/
├── 📄 README.md             — Top-level overview
├── 📁 doc/                  — Design & verification docs
│   ├── dma_spec.md         — Full design spec (Markdown)
│   └── test_plan.md        — UVM test plan
├── 📁 rtl/                  — RTL design files
│   ├── dma_top.sv          — Top-level AXI DMA module
│   ├── dma_ctrl.sv         — FSM and control logic
│   ├── dma_reader.sv       — AXI read engine
│   ├── dma_writer.sv       — AXI write engine
│   ├── dma_fifo.sv         — Internal FIFO buffer
│   ├── axi_if.sv           — AXI4 interface definition
│   └── apb_if.sv           — APB interface definition
├── 📁 tb/                   — Testbench infrastructure
│   ├── top_tb.sv           — Testbench top module
│   ├── dut_interfaces.sv   — Interface bindings to DUT
│   ├── reference_memory.sv — AXI memory model
│   ├── 📁 uvm_env/          — UVM environment components
│   │   ├── dma_env.sv      — UVM env top
│   │   ├── scoreboard.sv   — Scoreboard for data checking
│   │   ├── apb_agent.sv    — APB UVM agent
│   │   └── axi_agent.sv    — AXI slave model or passive agent
│   ├── 📁 uvm_sequences/    — UVM sequences
│   │   └── dma_transfer_seq.sv
│   ├── 📁 uvm_tests/        — UVM testcases
│   │   ├── smoke_test.sv
│   │   └── error_test.sv
│   └── run_sim.do          — Simulation run script
├── 📁 scripts/              — Automation and utilities
│   ├── compile.tcl
│   ├── run_all.tcl
│   └── lint.tcl
└── 🛠️  Makefile              — Optional build flow entry point
```
