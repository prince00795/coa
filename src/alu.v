// ============================================================================
// Module: alu (Arithmetic Logic Unit)
// Description: Performs arithmetic and bitwise logic operations on two 32-bit
//              inputs (a, b) based on a 4-bit alu_control code.
//              Also outputs a 'zero' flag (high when result == 0) for branches.
// ============================================================================

module alu (
    input  wire [31:0] a,           // Operand A (from rs1)
    input  wire [31:0] b,           // Operand B (from rs2 or immediate)
    input  wire [3:0]  alu_control, // Operation selector
    output reg  [31:0] result,      // ALU calculation result
    output wire        zero         // Zero flag (1 if result == 0)
);

    // ALU Control Codes:
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101; // Set Less Than (signed)
    localparam ALU_SLL  = 4'b0110; // Shift Left Logical
    localparam ALU_SRL  = 4'b0111; // Shift Right Logical
    localparam ALU_SRA  = 4'b1000; // Shift Right Arithmetic

    always @(*) begin
        case (alu_control)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_AND: result = a & b;
            ALU_OR:  result = a | b;
            ALU_XOR: result = a ^ b;
            ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLL: result = a << b[4:0];
            ALU_SRL: result = a >> b[4:0];
            ALU_SRA: result = $signed(a) >>> b[4:0];
            default: result = 32'b0;
        endcase
    end

    // Zero flag: high when result is 0 (used for BEQ)
    assign zero = (result == 32'b0);

endmodule
