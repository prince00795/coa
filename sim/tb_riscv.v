// ============================================================================
// Testbench: tb_riscv
// Description: Simulates the RISC-V Single-Cycle Processor.
//              Generates clock and reset, logs instruction execution,
//              prints register values, and checks expected results.
// ============================================================================

`timescale 1ns / 1ps

module tb_riscv;

    reg clk;
    reg rst;

    // Instantiate Top-Level RISC-V Core
    riscv_core dut (
        .clk (clk),
        .rst (rst)
    );

    // 10ns Clock Period (100 MHz)
    always #5 clk = ~clk;

    // Simulation Flow
    initial begin
        // Setup VCD Waveform dump
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_riscv);

        // Initialize signals
        clk = 0;
        rst = 1;

        $display("==========================================================");
        $display("   STARTING RISC-V SINGLE-CYCLE PROCESSOR SIMULATION      ");
        $display("==========================================================");

        // Hold reset for 2 cycles
        #12;
        rst = 0;
        $display("[TIME: %0t ns] Reset released. CPU starting execution...", $time);

        // Run for 14 clock cycles (enough for our 11 instructions + branch)
        #140;

        // Print Register File State
        $display("\n==========================================================");
        $display("              FINAL REGISTER FILE VALUES                  ");
        $display("==========================================================");
        $display("  x0  (zero) = %0d  (Expected: 0)",  dut.u_regfile.registers[0]);
        $display("  x1         = %0d (Expected: 15)",  dut.u_regfile.registers[1]);
        $display("  x2         = %0d (Expected: 25)",  dut.u_regfile.registers[2]);
        $display("  x3  (add)  = %0d (Expected: 40)",  dut.u_regfile.registers[3]);
        $display("  x4  (sub)  = %0d (Expected: 10)",  dut.u_regfile.registers[4]);
        $display("  x5  (and)  = %0d  (Expected: 9)",  dut.u_regfile.registers[5]);
        $display("  x6  (or)   = %0d (Expected: 31)",  dut.u_regfile.registers[6]);
        $display("  x7  (lw)   = %0d (Expected: 40)",  dut.u_regfile.registers[7]);
        $display("  x8 (skip)  = %0d  (Expected: 0 - skipped by branch!)", dut.u_regfile.registers[8]);
        $display("  x9 (target)= %0d (Expected: 42 - reached via branch!)", dut.u_regfile.registers[9]);
        $display("  Data Mem[4]= %0d (Expected: 40 - written by sw)", dut.u_dmem.memory[1]); // word 1 is address 4
        $display("==========================================================");

        // Self-Checking Verification
        if (dut.u_regfile.registers[1] == 15 &&
            dut.u_regfile.registers[2] == 25 &&
            dut.u_regfile.registers[3] == 40 &&
            dut.u_regfile.registers[4] == 10 &&
            dut.u_regfile.registers[5] == 9  &&
            dut.u_regfile.registers[6] == 31 &&
            dut.u_regfile.registers[7] == 40 &&
            dut.u_regfile.registers[8] == 0  &&
            dut.u_regfile.registers[9] == 42 &&
            dut.u_dmem.memory[1]       == 40) begin
            $display("   TEST STATUS: >>> SUCCESS! ALL INSTRUCTIONS VERIFIED <<<");
        end else begin
            $display("   TEST STATUS: >>> FAILED! Verification mismatch <<<");
        end
        $display("==========================================================\n");

        $finish;
    end

    // Monitor instruction execution every clock cycle
    always @(posedge clk) begin
        if (!rst) begin
            $display("[Time %3t ns] PC = 0x%08h | Instr = 0x%08h", 
                     $time, dut.pc_current, dut.instr);
        end
    end

endmodule
