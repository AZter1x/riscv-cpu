# RISC-V RV32I Pipelined CPU

A fully functional 5-stage pipelined RISC-V CPU implementing the RV32I base integer instruction set, written in Verilog.

## Architecture

5-stage pipeline: **IF → ID → EX → MEM → WB**

- **Forwarding unit** — resolves RAW data hazards without stalling
- **Hazard detection unit** — detects load-use hazards, inserts stall bubbles
- **Full branch support** — BEQ, BNE, BLT, BGE, BLTU, BGEU
- **Jump support** — JAL, JALR
- **Upper immediate** — LUI, AUIPC
- **Harvard memory model** — separate instruction and data memory

## Supported Instructions

| Type | Instructions |
|------|-------------|
| R-type | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| I-type | ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU |
| Load | LW, LH, LB, LHU, LBU |
| Store | SW, SH, SB |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jump | JAL, JALR |
| Upper | LUI, AUIPC |

## Project Structure
rtl/
alu/ - ALU and ALU control
core/ - Pipeline stages and control logic
mem/ - Instruction and data memory
tb/ - Testbenches
prog/ - Assembly test programs
sim/ - Simulation outputs
scripts/ - Build scripts
docs/ - Architecture documentation


## Simulation

### Requirements
- Icarus Verilog
- GTKWave
- riscv-none-elf-gcc toolchain

### Run test_basic.s
```powershell
riscv-none-elf-as -march=rv32i -mabi=ilp32 -o prog/test_basic.o prog/test_basic.s
riscv-none-elf-ld -m elf32lriscv -Ttext 0x0 -o prog/test_basic.elf prog/test_basic.o
riscv-none-elf-objcopy -O verilog prog/test_basic.elf prog/test.hex
iverilog -o sim/tb_top rtl/alu/alu.v rtl/core/alu_control.v rtl/mem/imem.v rtl/mem/dmem.v rtl/core/fetch.v rtl/core/decode.v rtl/core/execute.v rtl/core/memory.v rtl/core/writeback.v rtl/core/pipeline_regs.v rtl/core/hazard_unit.v rtl/core/forwarding_unit.v rtl/core/top.v tb/tb_top.v
vvp sim/tb_top
```

### View waveforms
```powershell
gtkwave sim/cpu.vcd
```

## Verification

| Test | Result |
|------|--------|
| test_basic.s — ALU, forwarding, load-use stall, branch | PASS |
| test_hazard.s — BNE, BLT, AUIPC, back-to-back RAW | PASS |

## Roadmap

- [ ] RV32M extension (multiply/divide) — required for Doom
- [ ] FPGA deployment (Xilinx/Intel)
- [ ] Memory-mapped I/O
- [ ] UART output
- [ ] Framebuffer + VGA/HDMI output
- [ ] Run Doom

## Tools

- Simulator: Icarus Verilog
- Waveform viewer: GTKWave
- Toolchain: xpack riscv-none-elf-gcc
