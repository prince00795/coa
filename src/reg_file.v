// ============================================================================
// Module: reg_file (Register File)
// Description: Implements the 32 general-purpose 32-bit registers (x0 - x31).
//              - Two combinational read ports (rd_data1, rd_data2)
//              - One synchronous write port (wr_data on posedge clk when reg_write is high)
//              - Register x0 is HARDWIRED to 32'b0 (cannot be modified)
// ============================================================================

module reg_file (
    input  wire        clk,        // Clock signal
    input  wire        rst,        // Reset signal
    input  wire        reg_write,  // Write Enable signal (from Control Unit)
    input  wire [4:0]  rs1,        // Source Register 1 address (5 bits -> 0 to 31)
    input  wire [4:0]  rs2,        // Source Register 2 address (5 bits -> 0 to 31)
    input  wire [4:0]  rd,         // Destination Register address (5 bits -> 0 to 31)
    input  wire [31:0] wr_data,    // 32-bit Data to write into register rd
    output wire [31:0] rd_data1,   // 32-bit Data read from register rs1
    output wire [31:0] rd_data2    // 32-bit Data read from register rs2
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];
    integer i;

    // Asynchronous read:
    // If reading from register x0, always return 0.
    // Otherwise return value stored in registers[rs1] / registers[rs2].
    assign rd_data1 = (rs1 == 5'b00000) ? 32'b0 : registers[rs1];
    assign rd_data2 = (rs2 == 5'b00000) ? 32'b0 : registers[rs2];

    // Synchronous write:
    // On the rising clock edge, if reg_write is enabled AND target is not x0:
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to 0
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write && (rd != 5'b00000)) begin
            registers[rd] <= wr_data;
        end
    end

endmodule
