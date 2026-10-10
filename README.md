# 32-Bit RISC-V Single-Cycle Processor (RV32I)

Designed in Verilog HDL and simulated using Icarus Verilog (`iverilog`).

---

## 🏛️ Architecture Overview

This processor implements a classic 5-stage single-cycle datapath for the RISC-V RV32I base integer instruction set:
1. **Instruction Fetch (IF)**: Program Counter (`pc.v`) and Instruction Memory (`instruction_mem.v`).
2. **Instruction Decode (ID)**: Control Unit (`control_unit.v`), Register File (`reg_file.v`), and Immediate Generator (`imm_gen.v`).
3. **Execute (EX)**: Arithmetic Logic Unit (`alu.v`) and ALU Decoder (`alu_control.v`).
4. **Memory Access (MEM)**: Data RAM (`data_mem.v`).
5. **Write-Back (WB)**: Multiplexer routing ALU result / Memory read data / Return address into destination register `rd`.

---

## 📁 Repository Structure

```
riscV/
├── src/
│   ├── pc.v               # 32-bit Program Counter register
│   ├── instruction_mem.v  # Instruction ROM (asynchronous read)
│   ├── reg_file.v         # 32x32 Register File (x0 hardwired to 0)
│   ├── imm_gen.v          # Sign-extending Immediate Generator
│   ├── alu.v              # Arithmetic Logic Unit
│   ├── alu_control.v      # ALU operation decoder
│   ├── control_unit.v     # Main 7-bit opcode decoder
│   ├── data_mem.v         # Data RAM for load/store
│   └── riscv_core.v       # Top-level datapath wiring all modules
├── sim/
│   ├── tb_riscv.v         # 11-instruction self-checking testbench
│   ├── tb_interactive.v   # Detailed cycle-by-cycle telemetry testbench
│   └── dump.vcd           # Waveform file (open with GTKWave)
├── run_interactive.py     # Interactive CLI tool for live demonstrations
└── README.md
```

---

## 🚀 How to Run

### Option 1: Live Interactive Demonstration (For Professor Presentation)
Run the interactive Python demonstrator:
```bash
python3 run_interactive.py
```
Or pass direct arguments:
```bash
python3 run_interactive.py --op ADD --a 50 --b 30
python3 run_interactive.py --op SUB --a 100 --b 35
python3 run_interactive.py --op XOR --a 12 --b 5
```
This tool:
1. Prompts you to pick an operation (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`) and enter two operand numbers.
2. Encodes the instructions into genuine 32-bit RISC-V machine code.
3. Displays the binary bit-slice breakdown (`funct7`, `rs2`, `rs1`, `funct3`, `rd`, `opcode`).
4. Explains the 5 hardware execution stages.
5. Runs the actual Verilog simulation and prints the hardware cycle-by-cycle telemetry and final register state.

---

### Option 2: Full 11-Instruction Verification Testbench
Compile and simulate the complete test suite:
```bash
iverilog -o sim/riscv_sim src/*.v sim/tb_riscv.v
vvp sim/riscv_sim
```

**Verified Instructions:**
- `addi x1, x0, 15`
- `addi x2, x0, 25`
- `add  x3, x1, x2`  $\rightarrow x3 = 40$
- `sub  x4, x2, x1`  $\rightarrow x4 = 10$
- `and  x5, x1, x2`  $\rightarrow x5 = 9$
- `or   x6, x1, x2`  $\rightarrow x6 = 31$
- `sw   x3, 4(x0)`   $\rightarrow \text{DataMem}[4] = 40$
- `lw   x7, 4(x0)`   $\rightarrow x7 = 40$
- `beq  x3, x7, 8`   $\rightarrow \text{Branch taken!}$
- `addi x8, x0, 99`  $\rightarrow \text{Skipped!}$
- `addi x9, x0, 42`  $\rightarrow \text{Target reached! } x9 = 42$

---

## 🎓 Professor Defense & Viva Guide

| Question | Answer |
|---|---|
| **Why is it called single cycle?** | Every instruction completes in exactly 1 clock cycle. CPI (Cycles Per Instruction) = 1. |
| **What is the critical path?** | The **Load Word (`lw`)** instruction, because it passes through all 5 stages in series (Fetch $\rightarrow$ Reg Read $\rightarrow$ ALU $\rightarrow$ Data Memory $\rightarrow$ Reg Write). The clock period must accommodate this total delay. |
| **Why is `x0` hardwired to 0?** | In RISC-V RV32I specification, register `x0` always reads 0 and ignores writes. This simplifies pseudo-instructions like `mv rd, rs` (`addi rd, rs, 0`) and `nop` (`addi x0, x0, 0`). |
| **Why use separate ALU Control?** | Multi-level decoding keeps the Main Control Unit fast and compact by only reading the 7-bit opcode, offloading `funct3` and `funct7` decoding to a smaller secondary block. |
| **How does branch decision work?** | In the Execute stage, the ALU computes $rs1 - rs2$. If zero, the Zero flag goes high. The next PC MUX selects $PC + \text{immediate}$ instead of $PC + 4$. |

