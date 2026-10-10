// ============================================================================
// Module: alu_control (ALU Decoder)
// Description: Generates the 4-bit alu_control signal based on alu_op from
//              Main Control Unit, funct3, and funct7[5] from the instruction.
// ============================================================================

module alu_control (
    input  wire [1:0] alu_op,      // 2-bit control from Main Control Unit
    input  wire [2:0] funct3,      // instr[14:12]
    input  wire       funct7_5,    // instr[30] (distinguishes ADD/SUB, SRL/SRA)
    output reg  [3:0] alu_ctrl     // 4-bit code sent to the ALU
);

    // ALU Codes (must match alu.v):
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;
    localparam ALU_SLL  = 4'b0110;
    localparam ALU_SRL  = 4'b0111;
    localparam ALU_SRA  = 4'b1000;

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = ALU_ADD; // Memory operations (lw, sw): calculate address rs1 + offset
            2'b01: alu_ctrl = ALU_SUB; // Branch operations (beq, bne): compare rs1 - rs2

            2'b10: begin // R-type instructions
                case (funct3)
                    3'b000: alu_ctrl = funct7_5 ? ALU_SUB : ALU_ADD; // sub (if bit 30=1) else add
                    3'b001: alu_ctrl = ALU_SLL;                      // sll
                    3'b010: alu_ctrl = ALU_SLT;                      // slt
                    3'b100: alu_ctrl = ALU_XOR;                      // xor
                    3'b101: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL; // sra (if bit 30=1) else srl
                    3'b110: alu_ctrl = ALU_OR;                       // or
                    3'b111: alu_ctrl = ALU_AND;                      // and
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            2'b11: begin // I-type arithmetic (addi, andi, ori, slti, etc.)
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;                      // addi
                    3'b001: alu_ctrl = ALU_SLL;                      // slli
                    3'b010: alu_ctrl = ALU_SLT;                      // slti
                    3'b100: alu_ctrl = ALU_XOR;                      // xori
                    3'b101: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL; // srai else srli
                    3'b110: alu_ctrl = ALU_OR;                       // ori
                    3'b111: alu_ctrl = ALU_AND;                      // andi
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            default: alu_ctrl = ALU_ADD;
        endcase
    end

endmodule
