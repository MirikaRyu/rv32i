# RV32I CPU Core

简体中文 | [English](README.en.md)

## ✨ 特性
- 完整实现RV32I基本整数指令集
- 统一内存访问：取指与数据访问共享同一地址空间，可同时访问ROM，RAM和I/O
- 多周期（非流水线）实现，结构清晰，易于理解

## 📦 项目结构
```
rv32i/
├── src/                    # CPU Verilog源代码
│   ├── memory/             # 访存相关
│   │   ├── access.v        # 访存控制
│   │   ├── io.v            # 仿真IO
│   │   ├── ram.v           # 仿真RAM
│   │   └── rom.v           # 仿真ROM
│   ├── constants.v         # 常量定义
│   ├── core.v              # CPU顶层模块
│   ├── decode.v            # 指令解码
│   ├── execute.v           # 执行单元
│   ├── fetch.v             # 取指单元
│   └── register.v          # 寄存器堆
│
├── test/                   # 测试仿真相关代码
│   ├── code/               # 被测程序
│   ├── mock/               # 仿真内存实现
│   ├── run.cpp             # 运行任意被测程序
│   ├── test_core.cpp       # 运行`mini`测试检查CPU功能
│   └── test_decode.cpp     # 运行`mini`测试检查解码器
│
├── tools/                  # 项目相关工具
│   ├── convert.py          # 转换binary至纯文本hex文件
│   └── vformat.py          # 代码格式化
│
├── README.md               # README
└── xmake.lua               # 构建脚本
```

## 🛠️ 仿真
### 依赖
- [Verilator](https://www.veripool.org/verilator/)
- [Xmake](https://xmake.io/)
- Python
- Host GCC / Clang (支持 C++23)
- [riscv32-unknown-elf-gcc](https://github.com/riscv-collab/riscv-gnu-toolchain) (>= GCC 15)

### 运行
```bash
git clone https://github.com/MirikaRyu/rv32i.git
cd rv32i
```

核心测试
```bash
xmake r
```

解码测试
```bash
xmake r test_decode
```

应用测试
```bash
xmake r test_app
```

选择其他被测程序
```bash
xmake f --app=exception     # 在test/code目录下查找更多程序
xmake r test_app
```

测试完成后可在`$(builddir)/vcd`中找到生成的VCD波形文件

## 📌 注意事项
- 本项目用途为**图一乐**，请勿用于生产环境
- `ecall / exceptions` 会直接使CPU复位
- `ebreak` 会停止整个CPU的运行