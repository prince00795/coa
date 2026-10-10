// ============================================================================
// Module: control_unit (Main Control Unit)
// Description: Decodes the 7-bit opcode and sets all CPU control signals.
// ============================================================================

module control_unit (
    input  wire [6:0] opcode,      // instr[6:0]
    output reg        reg_write,   // 1: Write result into destination register rd
    output reg        alu_src,     // 0: Operand B is rs2; 1: Operand B is immediate
    output reg        mem_read,    // 1: Read from Data Memory (lw)
    output reg        mem_write,   // 1: Write to Data Memory (sw)
    output reg  [1:0] mem_to_reg,  // 00: ALU result, 01: Memory data, 10: PC+4 (for JAL/JALR)
    output reg        branch,      // 1: Conditional branch instruction (beq, bne)
    output reg        jump,        // 1: Unconditional jump (jal, jalr)
    output reg  [1:0] alu_op       // 00: lw/sw, 01: branch, 10: R-type, 11: I-type
);

    // RISC-V RV32I Opcodes
    localparam OPC_R_TYPE = 7'b0110011; // add, sub, and, or, slt...
    localparam OPC_I_TYPE = 7'b0010011; // addi, andi, ori, slti...
    localparam OPC_LOAD   = 7'b0000011; // lw
    localparam OPC_STORE  = 7'b0100011; // sw
    localparam OPC_BRANCH = 7'b1100011; // beq, bne
    localparam OPC_JAL    = 7'b1101111; // jal
    localparam OPC_LUI    = 7'b0110111; // lui

    always @(*) begin
        // Default safe values (all de-asserted)
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)
            OPC_R_TYPE: begin
                reg_write  = 1'b1;
                alu_src    = 1'b0;    // Operand B = register rs2
                mem_to_reg = 2'b00;   // Write back ALU result
                alu_op     = 2'b10;   // Determined by funct3 & funct7
            end

            OPC_I_TYPE: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;    // Operand B = immediate
                mem_to_reg = 2'b00;   // Write back ALU result
                alu_op     = 2'b11;   // Determined by funct3
            end

            OPC_LOAD: begin // lw
                reg_write  = 1'b1;
                alu_src    = 1'b1;    // ALU calculates address: rs1 + offset
                mem_read   = 1'b1;    // Enable reading from Data Memory
                mem_to_reg = 2'b01;   // Write back data read from memory
                alu_op     = 2'b00;   // ALU adds
            end

            OPC_STORE: begin // sw
                alu_src    = 1'b1;    // ALU calculates address: rs1 + offset
                mem_write  = 1'b1;    // Enable writing to Data Memory
                alu_op     = 2'b00;   // ALU adds
            end

            OPC_BRANCH: begin // beq, bne
                alu_src    = 1'b0;    // Compare rs1 and rs2
                branch     = 1'b1;    // May branch if condition met
                alu_op     = 2'b01;   // ALU subtracts to check zero
            end

            OPC_JAL: begin // jal
                reg_write  = 1'b1;    // Save PC+4 into rd (return address)
                jump       = 1'b1;    // Unconditional jump
                mem_to_reg = 2'b10;   // Write back PC+4
            end

            default: begin
                // All defaults are 0
            end
        endcase
    end

endmodule
