// ============================================================================
// Module: imm_gen (Immediate Generator)
// Description: Extracts immediate fields from 32-bit RISC-V instructions and
//              sign-extends them to a full 32-bit value based on the opcode.
//              Handles:
//              - I-type (addi, lw, jalr, etc.)
//              - S-type (sw, etc.)
//              - B-type (beq, bne, etc.)
//              - U-type (lui, auipc)
//              - J-type (jal)
// ============================================================================

module imm_gen (
    input  wire [31:0] instr,   // 32-bit RISC-V instruction
    output reg  [31:0] imm_out  // Sign-extended 32-bit immediate
);

    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            // I-type: addi, andi, ori, xori, slti, lw, jalr
            7'b0010011, // OP-IMM (addi, etc.)
            7'b0000011, // LOAD   (lw)
            7'b1100111: // JALR
                imm_out = {{20{instr[31]}}, instr[31:20]};

            // S-type: sw (Store Word)
            7'b0100011: // STORE  (sw)
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type: beq, bne (Branch)
            7'b1100011: // BRANCH (beq, bne)
                imm_out = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

            // U-type: lui, auipc
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm_out = {instr[31:12], 12'b0};

            // J-type: jal (Jump and Link)
            7'b1101111: // JAL
                imm_out = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

            default:
                imm_out = 32'b0;
        endcase
    end

endmodule
