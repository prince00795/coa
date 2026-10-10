// ============================================================================
// Module: instruction_mem (Instruction Memory)
// Description: ROM storing 32-bit RISC-V instructions.
//              - If PROGRAM_FILE is empty (""), loads built-in 11-instruction test suite.
//              - If PROGRAM_FILE is specified, loads hex file using $readmemh.
// ============================================================================

module instruction_mem #(
    parameter PROGRAM_FILE = ""
)(
    input  wire [31:0] pc,     // Instruction address from Program Counter
    output wire [31:0] instr   // 32-bit instruction fetched from memory
);

    // 64 words (256 bytes) of instruction memory
    reg [31:0] memory [0:63];
    integer i;

    // Asynchronous read: pc[7:2] provides word index
    assign instr = memory[pc[7:2]];

    initial begin
        // Initialize memory with NOPs (addi x0, x0, 0)
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h0000_0013;
        end

        if (PROGRAM_FILE != "") begin
            $readmemh(PROGRAM_FILE, memory);
        end else begin
            // ----------------------------------------------------------------
            // Built-in 11-Instruction Verification Suite
            // ----------------------------------------------------------------
            memory[0] = 32'h00f0_0093; // addi x1, x0, 15    (x1 = 15)
            memory[1] = 32'h0190_0113; // addi x2, x0, 25    (x2 = 25)
            memory[2] = 32'h0020_81b3; // add  x3, x1, x2    (x3 = 40)
            memory[3] = 32'h4011_0233; // sub  x4, x2, x1    (x4 = 10)
            memory[4] = 32'h0020_f2b3; // and  x5, x1, x2    (x5 = 9)
            memory[5] = 32'h0020_e333; // or   x6, x1, x2    (x6 = 31)
            memory[6] = 32'h0030_2223; // sw   x3, 4(x0)     (mem[4] = 40)
            memory[7] = 32'h0040_2383; // lw   x7, 4(x0)     (x7 = 40)
            memory[8] = 32'h0071_8463; // beq  x3, x7, 8     (taken!)
            memory[9] = 32'h0630_0413; // addi x8, x0, 99    (skipped!)
            memory[10]= 32'h02a0_0493; // addi x9, x0, 42    (branch target: x9 = 42)
        end
    end

endmodule
