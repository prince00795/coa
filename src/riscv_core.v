// ============================================================================
// Module: riscv_core (Top-Level RV32I Single-Cycle Processor)
// Description: Integrates all sub-modules (PC, IM, RF, ALU, DM, CU, IMM)
//              and datapath multiplexers into a complete working CPU.
// ============================================================================

module riscv_core #(
    parameter PROGRAM_FILE = ""
)(
    input  wire        clk,        // System Clock
    input  wire        rst         // System Reset (Active High)
);

    // ========================================================================
    // Internal Wires and Buses
    // ========================================================================

    // PC wires
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    wire [31:0] branch_target;

    // Instruction wires
    wire [31:0] instr;
    wire [6:0]  opcode   = instr[6:0];
    wire [4:0]  rd       = instr[11:7];
    wire [2:0]  funct3   = instr[14:12];
    wire [4:0]  rs1      = instr[19:15];
    wire [4:0]  rs2      = instr[24:20];
    wire [6:0]  funct7   = instr[31:25];

    // Control Unit wires
    wire        reg_write;
    wire        alu_src;
    wire        mem_read;
    wire        mem_write;
    wire [1:0]  mem_to_reg;
    wire        branch;
    wire        jump;
    wire [1:0]  alu_op;

    // Register File wires
    wire [31:0] rd_data1;
    wire [31:0] rd_data2;
    reg  [31:0] reg_wr_data;

    // Immediate Generator wire
    wire [31:0] imm_out;

    // ALU wires
    wire [3:0]  alu_ctrl;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire        alu_zero;

    // Data Memory wire
    wire [31:0] mem_rd_data;

    // ========================================================================
    // 1. Fetch Stage: PC & Instruction Memory
    // ========================================================================
    assign pc_plus_4      = pc_current + 32'd4;
    assign branch_target  = pc_current + imm_out;

    // Next PC selection logic (Mux)
    wire pc_branch_taken = (branch & alu_zero); // For BEQ
    assign pc_next = (jump)            ? branch_target : 
                     (pc_branch_taken) ? branch_target : 
                                         pc_plus_4;

    // Program Counter Instance
    pc u_pc (
        .clk     (clk),
        .rst     (rst),
        .pc_next (pc_next),
        .pc      (pc_current)
    );

    // Instruction Memory Instance
    instruction_mem #(
        .PROGRAM_FILE (PROGRAM_FILE)
    ) u_imem (
        .pc    (pc_current),
        .instr (instr)
    );

    // ========================================================================
    // 2. Decode Stage: Control Unit, Register File, Immediate Gen
    // ========================================================================
    control_unit u_control (
        .opcode     (opcode),
        .reg_write  (reg_write),
        .alu_src    (alu_src),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .jump       (jump),
        .alu_op     (alu_op)
    );

    reg_file u_regfile (
        .clk       (clk),
        .rst       (rst),
        .reg_write (reg_write),
        .rs1       (rs1),
        .rs2       (rs2),
        .rd        (rd),
        .wr_data   (reg_wr_data),
        .rd_data1  (rd_data1),
        .rd_data2  (rd_data2)
    );

    imm_gen u_immgen (
        .instr   (instr),
        .imm_out (imm_out)
    );

    // ========================================================================
    // 3. Execute Stage: ALU & ALU Control
    // ========================================================================
    // Mux for ALU Operand B: select between Register 2 data and Immediate
    assign alu_operand_b = (alu_src) ? imm_out : rd_data2;

    alu_control u_alu_ctrl (
        .alu_op   (alu_op),
        .funct3   (funct3),
        .funct7_5 (instr[30]),
        .alu_ctrl (alu_ctrl)
    );

    alu u_alu (
        .a           (rd_data1),
        .b           (alu_operand_b),
        .alu_control (alu_ctrl),
        .result      (alu_result),
        .zero        (alu_zero)
    );

    // ========================================================================
    // 4. Memory Stage: Data RAM
    // ========================================================================
    data_mem u_dmem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (alu_result),
        .wr_data   (rd_data2),
        .rd_data   (mem_rd_data)
    );

    // ========================================================================
    // 5. Write-Back Stage: Write-Back Multiplexer
    // ========================================================================
    always @(*) begin
        case (mem_to_reg)
            2'b00:   reg_wr_data = alu_result;   // R-type / I-type math
            2'b01:   reg_wr_data = mem_rd_data;  // Load from memory (lw)
            2'b10:   reg_wr_data = pc_plus_4;    // Return address for JAL
            default: reg_wr_data = alu_result;
        endcase
    end

endmodule
