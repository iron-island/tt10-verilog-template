// Register write enable
// One-hot encoded to avoid needing another decoder in the execute stage
`define NO_WR_EN    5'b00000
`define REG_A_WR_EN 5'b00001
`define REG_B_WR_EN 5'b00010
`define REG_C_WR_EN 5'b00100
`define REG_O_WR_EN 5'b01000 // represents output register

// Operand selectors for actual operations (XOR, mod)
// Register A is not used for XOR and mod operators, and is always used
//   for shift operator, so its code is not used for operand selectors
// Instead, selectors for combo and literal operands are used
`define COMBO_OP_SEL 2'd0
`define LIT_OP_SEL   2'd1
`define REG_B_SEL    2'd2
`define REG_C_SEL    2'd3

// Operation select
`define SHIFT_SEL 2'd0;
`define XOR_SEL   2'd1;
`define MOD_SEL   2'd2;
`define JUMP_SEL  2'd3;

module tt10_chronospatial_ironisland_top(
    // Inputs
    input         clk,
    input         rstn,
    input [2:0]   program [3:0],

    // Outputs
    output        halt,
    output [2:0]  reg_out,
    output        out_valid
);

    // instruction_fetch outputs
    wire [2:0]    opcode;
    wire [2:0]    operand;

    // instruction_decode outputs
    wire [2:0]    operand_id_reg;
    wire [1:0]    op1_sel;
    wire [1:0]    op2_sel;
    wire [1:0]    operation_sel;
    wire [4:0]    reg_wr_en;

    // execute outputs
    wire [3:0]    instr_ptr;

    // Pipeline stage 1: Instruction fetch
    instruction_fetch u_if(
        // Inputs
        .clk               (clk),
        .rstn              (rstn),
        .halt              (halt),
        .program           (program),
        .instr_ptr         (instr_ptr),
        .halt              (halt),

        // Outputs
        .opcode            (opcode),
        .operand           (operand)
    );

    // Pipeline stage 2: Instruction decode
    instruction_decode u_id(
        // Inputs
        .clk               (clk),
        .rstn              (rstn),
        .halt              (halt),
        .opcode            (opcode),
        .operand           (operand),

        // Outputs
        .operand_id_reg    (operand_id_reg),
        .op1_sel           (op1_sel),
        .op2_sel           (op2_sel),
        .operation_sel     (operation_sel),
        .reg_wr_en         (reg_wr_en),
    );

    // Pipeline stage 3: Execute
    execute u_ex(
        // Inputs
        .clk               (clk),
        .rstn              (rstn),
        .operand_id_reg    (operand_id_reg),
        .op1_sel           (op1_sel),
        .op2_sel           (op2_sel),
        .operation_sel     (operation_sel),
        .reg_addr          (reg_addr),

        // Outputs
        .instr_ptr         (instr_ptr)
    );

endmodule
