// ============================================================================
// Testbench: tb_interactive
// Description: Interactive testbench that displays detailed hardware signals
//              for each executed instruction.
// ============================================================================

`timescale 1ns / 1ps

module tb_interactive;

    reg clk;
    reg rst;

    riscv_core #(
        .PROGRAM_FILE ("sim/instructions.hex")
    ) dut (
        .clk (clk),
        .rst (rst)
    );

    // 10ns Clock Period
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #12;
        rst = 0;

        // Run 5 cycles for user operation:
        // Cycle 1: addi x1, x0, val1
        // Cycle 2: addi x2, x0, val2
        // Cycle 3: op   x3, x1, x2
        // Cycle 4: NOP
        // Cycle 5: NOP
        #50;

        $display("\n============================================================");
        $display("               HARDWARE REGISTER STATUS                    ");
        $display("============================================================");
        $display("  x0 (zero) = %0d", dut.u_regfile.registers[0]);
        $display("  x1 (op A) = %0d (0x%08h)", dut.u_regfile.registers[1], dut.u_regfile.registers[1]);
        $display("  x2 (op B) = %0d (0x%08h)", dut.u_regfile.registers[2], dut.u_regfile.registers[2]);
        $display("  x3 (RES)  = %0d (0x%08h)", dut.u_regfile.registers[3], dut.u_regfile.registers[3]);
        $display("============================================================\n");
        $finish;
    end

    // Log each instruction execution cycle
    integer cycle_count = 0;
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;
            $display("[CYCLE %0d] PC: 0x%08h | Machine Code: 0x%08h", 
                     cycle_count, dut.pc_current, dut.instr);
            $display("   ├── [Decode] Opcode: 7'b%07b | rs1: x%0d | rs2: x%0d | rd: x%0d", 
                     dut.opcode, dut.rs1, dut.rs2, dut.rd);
            $display("   ├── [Control] RegWrite=%b | ALUSrc=%b | ALUOp=%b | MemToReg=%b", 
                     dut.reg_write, dut.alu_src, dut.alu_op, dut.mem_to_reg);
            $display("   ├── [ALU] OperA = %0d | OperB = %0d | ALUControl = 4'b%04b | Result = %0d", 
                     dut.rd_data1, dut.alu_operand_b, dut.alu_ctrl, dut.alu_result);
            if (dut.reg_write && dut.rd != 0) begin
                $display("   └── [Write-Back] Register x%0d <= %0d", dut.rd, dut.reg_wr_data);
            end else begin
                $display("   └── [Write-Back] No register write");
            end
            $display("------------------------------------------------------------");
        end
    end

endmodule
