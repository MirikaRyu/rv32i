# RV32I CPU Core

[简体中文](README.md) | English

## ✨ Features
- Fully implements the RV32I base integer instruction set
- Unified memory access: instruction fetch and data access share the same address space, supporting simultaneous access to ROM, RAM, and I/O
- Multi-cycle (non-pipelined) implementation with a clean, easy-to-understand structure

## 📦 Project Structure
```
rv32i/
├── src/                    # CPU Verilog source code
│   ├── memory/             # Memory subsystem
│   │   ├── access.v        # Memory access control
│   │   ├── io.v            # Simulation I/O
│   │   ├── ram.v           # Simulated RAM
│   │   └── rom.v           # Simulated ROM
│   ├── constants.v         # Constant definitions
│   ├── core.v              # Top-level CPU module
│   ├── decode.v            # Instruction decoder
│   ├── execute.v           # Execution unit
│   ├── fetch.v             # Fetch unit
│   └── register.v          # Register file
│
├── test/                   # Simulation and test code
│   ├── code/               # Test programs
│   ├── mock/               # Simulated memory implementation
│   ├── run.cpp             # Run arbitrary test programs
│   ├── test_core.cpp       # Run `mini` test to verify CPU functionality
│   └── test_decode.cpp     # Run `mini` test to verify decoder
│
├── tools/                  # Project utilities
│   ├── convert.py          # Convert binary to plain-text hex
│   └── vformat.py          # Verilog code formatter
│
├── README.en.md            # This file
└── xmake.lua               # Build script
```

## 🛠️ Simulation
### Dependencies
- [Verilator](https://www.veripool.org/verilator/)
- [Xmake](https://xmake.io/)
- Python
- Host GCC / Clang (C++23 support required)
- [riscv32-unknown-elf-gcc](https://github.com/riscv-collab/riscv-gnu-toolchain) (GCC 15 or newer)

### Quick Start
```bash
git clone https://github.com/MirikaRyu/rv32i.git
cd rv32i
```

**Run core test**
```bash
xmake r
```

**Run decoder test**
```bash
xmake r test_decode
```

**Run application test**
```bash
xmake r test_app
```

**Select a different test program**
```bash
xmake f --app=exception     # See test/code/ for more programs
xmake r test_app
```

After simulation completes, VCD waveform files can be found in `$(builddir)/vcd`.

## 📌 Notes
- This project is **JUST FOR FUN** — not intended for production use.
- `ecall / exceptions` will trigger a CPU reset.
- `ebreak` will halt the entire CPU.