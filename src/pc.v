// ============================================================================
// Module: pc (Program Counter)
// Description: 32-bit register holding the address of the current instruction.
//              Updates to pc_next on every rising clock edge.
//              Resets to 0x00000000 when rst is asserted.
// ============================================================================

module pc (
    input  wire        clk,      // Clock signal
    input  wire        rst,      // Active-high reset signal
    input  wire [31:0] pc_next,  // Next PC value (from PC+4 or Branch/Jump target)
    output reg  [31:0] pc        // Current PC value
);

    // Sequential logic: updates on the rising edge of the clock or reset
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'h0000_0000; // Reset PC to address 0
        end else begin
            pc <= pc_next;       // Load next instruction address
        end
    end

endmodule
