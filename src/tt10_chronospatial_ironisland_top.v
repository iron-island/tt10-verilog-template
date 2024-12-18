/*
 * Copyright (c) 2024 Aldrin Rolf Ison
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

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
`define SHIFT_SEL 2'd0
`define XOR_SEL   2'd1
`define MOD_SEL   2'd2
`define JUMP_SEL  2'd3

// TODO: Remove and design a way to dynamically add the initial register values and program
//       Just included to obfuscate actual values since it corresponds to Advent of Code inputs
//         which are copyrighted
`include "reg_prog_init.h"

// TODO: Add .f file instead to be read in testbench and OpenLANE setup
`include "instruction_fetch.v"
`include "instruction_decode.v"
`include "execute.v"

module tt10_chronospatial_ironisland_top(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    // Internal wires to be assigned to outputs
    wire [2:0]    reg_out;
    wire          out_valid;
    wire          halt;

    // TT: All output pins must be assigned. If not used, assign to 0.
    assign uo_out[2:0] = reg_out;
    assign uo_out[3]   = out_valid;
    assign uo_out[4]   = halt;
    assign uo_out[7:5] = 0;
    assign uio_out     = 0;
    assign uio_oe      = 0;

    // TT: List all unused inputs to prevent warnings
    wire _unused = &{ena, uio_in};

    // instruction_fetch outputs
    wire [2:0]    opcode;
    wire [2:0]    operand;
    wire [3:0]    instr_ptr_if_reg;

    // instruction_decode outputs
    wire [2:0]    operand_id_reg;
    wire [3:0]    instr_ptr_id_reg;
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
        .rst_n             (rst_n),
        .halt              (halt),
        .instr_ptr         (instr_ptr),

        // Outputs
        .opcode            (opcode),
        .operand           (operand),
        .instr_ptr_if_reg  (instr_ptr_if_reg)
    );

    // Pipeline stage 2: Instruction decode
    instruction_decode u_id(
        // Inputs
        .clk               (clk),
        .rst_n             (rst_n),
        .halt              (halt),
        .opcode            (opcode),
        .operand           (operand),
        .instr_ptr_if_reg  (instr_ptr_if_reg),

        // Outputs
        .operand_id_reg    (operand_id_reg),
        .instr_ptr_id_reg  (instr_ptr_id_reg),
        .op1_sel           (op1_sel),
        .op2_sel           (op2_sel),
        .operation_sel     (operation_sel),
        .reg_wr_en         (reg_wr_en)
    );

    // Pipeline stage 3: Execute
    execute u_ex(
        // Inputs
        .clk               (clk),
        .rst_n             (rst_n),
        .operand_id_reg    (operand_id_reg),
        .instr_ptr_id_reg  (instr_ptr_id_reg),
        .op1_sel           (op1_sel),
        .op2_sel           (op2_sel),
        .operation_sel     (operation_sel),
        .reg_wr_en         (reg_wr_en),

        // Outputs
        .instr_ptr         (instr_ptr),
        .halt              (halt),
        .reg_out           (reg_out),
        .out_valid         (out_valid)
    );

endmodule