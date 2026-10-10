#!/usr/bin/env python3
"""
RISC-V Single-Cycle Interactive Demonstrator
Takes user input (Operands and ALU Operation), generates 32-bit RISC-V machine code,
runs the Verilog hardware simulation, and displays the full hardware execution flow.
"""

import sys
import os
import subprocess
import argparse

# ANSI color codes for terminal display
CYAN    = "\033[96m"
GREEN   = "\033[92m"
YELLOW  = "\033[93m"
RED     = "\033[91m"
MAGENTA = "\033[95m"
BOLD    = "\033[1m"
RESET   = "\033[0m"

OPERATIONS = {
    "1": ("ADD",  0x00, 0x0, "Addition (x1 + x2)"),
    "2": ("SUB",  0x20, 0x0, "Subtraction (x1 - x2)"),
    "3": ("AND",  0x00, 0x7, "Bitwise AND (x1 & x2)"),
    "4": ("OR",   0x00, 0x6, "Bitwise OR (x1 | x2)"),
    "5": ("XOR",  0x00, 0x4, "Bitwise XOR (x1 ^ x2)"),
    "6": ("SLT",  0x00, 0x2, "Set Less Than (signed x1 < x2 ? 1 : 0)"),
}

def encode_i(imm, rs1, funct3, rd, opcode=0x13):
    """Encodes I-type instruction (e.g., ADDI)"""
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)

def encode_r(funct7, rs2, rs1, funct3, rd, opcode=0x33):
    """Encodes R-type instruction (e.g., ADD, SUB, AND, OR)"""
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)

def print_banner():
    print(f"""
{CYAN}{BOLD}========================================================================
       🚀 RISC-V SINGLE-CYCLE PROCESSOR INTERACTIVE DEMONSTRATOR
========================================================================{RESET}
""")

def get_user_inputs():
    print(f"{YELLOW}{BOLD}Select an ALU Operation to execute:{RESET}")
    for key, (name, _, _, desc) in OPERATIONS.items():
        print(f"  {BOLD}[{key}]{RESET} {CYAN}{name:<4}{RESET} : {desc}")

    choice = input(f"\n{BOLD}Enter choice (1-6) [default: 1]: {RESET}").strip()
    if not choice or choice not in OPERATIONS:
        choice = "1"

    op_name, funct7, funct3, desc = OPERATIONS[choice]

    while True:
        try:
            val_a_str = input(f"{BOLD}Enter Operand 1 (saved to register x1) [-2048 to 2047, default: 50]: {RESET}").strip()
            val_a = int(val_a_str) if val_a_str else 50
            if -2048 <= val_a <= 2047:
                break
            print(f"{RED}Value must fit in 12-bit signed immediate (-2048 to 2047).{RESET}")
        except ValueError:
            print(f"{RED}Please enter a valid integer.{RESET}")

    while True:
        try:
            val_b_str = input(f"{BOLD}Enter Operand 2 (saved to register x2) [-2048 to 2047, default: 30]: {RESET}").strip()
            val_b = int(val_b_str) if val_b_str else 30
            if -2048 <= val_b <= 2047:
                break
            print(f"{RED}Value must fit in 12-bit signed immediate (-2048 to 2047).{RESET}")
        except ValueError:
            print(f"{RED}Please enter a valid integer.{RESET}")

    return op_name, funct7, funct3, val_a, val_b

def main():
    parser = argparse.ArgumentParser(description="RISC-V Interactive Runner")
    parser.add_argument("--op", choices=["ADD", "SUB", "AND", "OR", "XOR", "SLT"], help="ALU operation")
    parser.add_argument("--a", type=int, help="Operand A value")
    parser.add_argument("--b", type=int, help="Operand B value")
    args = parser.parse_args()

    print_banner()

    if args.op and args.a is not None and args.b is not None:
        op_name = args.op.upper()
        # Find config
        found = False
        for _, (name, f7, f3, _) in OPERATIONS.items():
            if name == op_name:
                funct7, funct3 = f7, f3
                found = True
                break
        if not found:
            sys.exit(1)
        val_a = args.a
        val_b = args.b
    else:
        op_name, funct7, funct3, val_a, val_b = get_user_inputs()

    # 1. Generate Instructions
    instr0 = encode_i(val_a, 0, 0, 1) # addi x1, x0, val_a
    instr1 = encode_i(val_b, 0, 0, 2) # addi x2, x0, val_b
    instr2 = encode_r(funct7, 2, 1, funct3, 3) # op x3, x1, x2

    # 2. Write sim/instructions.hex
    os.makedirs("sim", exist_ok=True)
    hex_path = "sim/instructions.hex"
    with open(hex_path, "w") as f:
        f.write(f"{instr0:08x}\n")
        f.write(f"{instr1:08x}\n")
        f.write(f"{instr2:08x}\n")
        # Fill rest with NOPs (addi x0, x0, 0 -> 00000013)
        for _ in range(3, 64):
            f.write("00000013\n")

    # 3. Print Machine Code Breakdown
    print(f"\n{GREEN}{BOLD}--- [1] GENERATED RISC-V MACHINE CODE ---{RESET}")
    print(f"Instruction 0: {CYAN}addi x1, x0, {val_a:<4}{RESET} -> Hex: {BOLD}0x{instr0:08x}{RESET}")
    print(f"Instruction 1: {CYAN}addi x2, x0, {val_b:<4}{RESET} -> Hex: {BOLD}0x{instr1:08x}{RESET}")
    print(f"Instruction 2: {CYAN}{op_name.lower()} x3, x1, x2{RESET:<8} -> Hex: {BOLD}0x{instr2:08x}{RESET}")

    # Detailed 32-bit field breakdown of the ALU instruction
    b32 = f"{instr2:032b}"
    print(f"\n{MAGENTA}{BOLD}--- [2] 32-BIT INSTRUCTION BIT SLICE ({op_name} x3, x1, x2) ---{RESET}")
    print(f"  funct7  (31:25) : {b32[0:7]}    (7'b{funct7:07b})")
    print(f"  rs2     (24:20) : {b32[7:12]}      (x2 -> Operand B)")
    print(f"  rs1     (19:15) : {b32[12:17]}      (x1 -> Operand A)")
    print(f"  funct3  (14:12) : {b32[17:20]}        (3'b{funct3:03b})")
    print(f"  rd      (11:7)  : {b32[20:25]}      (x3 -> Destination)")
    print(f"  opcode  (6:0)   : {b32[25:32]}    (7'b0110011 -> R-type)")

    # 4. Print 5-Stage Hardware Execution Theory
    print(f"\n{YELLOW}{BOLD}--- [3] 5-STAGE HARDWARE EXECUTION BREAKDOWN ---{RESET}")
    print(f"  1. {BOLD}FETCH{RESET}     : PC fetches 32-bit word 0x{instr2:08x} from Instruction RAM.")
    print(f"  2. {BOLD}DECODE{RESET}    : Control Unit detects opcode 0110011 (R-type):")
    print(f"                  - Sets RegWrite = 1 (enable write to x3)")
    print(f"                  - Sets ALUSrc   = 0 (select register x2, not immediate)")
    print(f"                  - Sets MemToReg = 00 (select ALU result for write-back)")
    print(f"                  - Reads Register x1 (contains {val_a}) and x2 (contains {val_b}).")
    print(f"  3. {BOLD}EXECUTE{RESET}   : ALU Control decodes (funct7, funct3) into ALU code.")
    print(f"                  - ALU executes {op_name} on Operand A ({val_a}) and Operand B ({val_b}).")
    print(f"  4. {BOLD}MEMORY{RESET}    : MemRead=0, MemWrite=0. Data RAM is bypassed.")
    print(f"  5. {BOLD}WRITE-BACK{RESET}: ALU result is routed to destination register x3 on clock edge.")

    # 5. Compile and Run Verilog Simulation
    print(f"\n{CYAN}{BOLD}--- [4] RUNNING ICARUS VERILOG HARDWARE SIMULATION ---{RESET}")
    compile_cmd = ["iverilog", "-o", "sim/interactive_sim", "src/pc.v", "src/instruction_mem.v", 
                   "src/reg_file.v", "src/imm_gen.v", "src/alu_control.v", "src/alu.v", 
                   "src/control_unit.v", "src/data_mem.v", "src/riscv_core.v", "sim/tb_interactive.v"]
    
    comp_res = subprocess.run(compile_cmd, capture_output=True, text=True)
    if comp_res.returncode != 0:
        print(f"{RED}Compilation Error:\n{comp_res.stderr}{RESET}")
        return

    sim_res = subprocess.run(["vvp", "sim/interactive_sim"], capture_output=True, text=True)
    print(sim_res.stdout)

if __name__ == "__main__":
    main()
