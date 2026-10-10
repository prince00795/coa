// ============================================================================
// Module: data_mem (Data Memory / RAM)
// Description: Stores and retrieves data for load (lw) and store (sw) instructions.
//              - Combinational (instant) read for single-cycle flow
//              - Synchronous write on rising clock edge when mem_write is high
//              - Word-addressed using addr[7:2]
// ============================================================================

module data_mem (
    input  wire        clk,       // Clock signal
    input  wire        mem_read,  // Read Enable (asserted for 'lw')
    input  wire        mem_write, // Write Enable (asserted for 'sw')
    input  wire [31:0] addr,      // Memory address (ALU Result)
    input  wire [31:0] wr_data,   // Data to write (from register rs2)
    output wire [31:0] rd_data    // Data read from memory
);

    // 64 words (256 bytes) of Data RAM
    reg [31:0] memory [0:63];
    integer i;

    // Initialize data memory to 0
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'b0;
        end
    end

    // Asynchronous / Combinational Read:
    // If mem_read is high, read the word at addr[7:2], else output 0.
    assign rd_data = (mem_read) ? memory[addr[7:2]] : 32'b0;

    // Synchronous Write:
    // Store data into memory on the rising clock edge when mem_write is high
    always @(posedge clk) begin
        if (mem_write) begin
            memory[addr[7:2]] <= wr_data;
        end
    end

endmodule
