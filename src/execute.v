module execute(
    // Inputs
    input         clk,
    input         rst_n,
    input [2:0]   operand_id_reg,
    input [1:0]   op1_sel,
    input [1:0]   op2_sel,
    input [1:0]   operation_sel,
    input [4:0]   reg_wr_en,
    input [47:0]  reg_A,
    input [47:0]  reg_B,
    input [47:0]  reg_C,
    
    // Outputs
    output [3:0]  instr_ptr,
    output        halt,
    output [2:0]  last_out,
    output [47:0] reg_out,
    output        out_valid
);

    // Combo and literal operand
    wire [47:0]   combo_op;
    wire [47:0]   lit_op;

    // Combo operand used for shift, limited to 6 bits = ceil(log2(48))
    //   since register A can only be shifted by a maximum of 48 bits,
    //   and to reduce bitwidth and shifter length
    wire [5:0]    shift_combo_op;

    // Operation outputs
    wire [47:0]   shift_output;
    wire [47:0]   xor_output;
    wire [2:0]    mod_output;
    wire [4:0]    add_output;
    wire [2:0]    jump_output;

    // Selected operands
    wire [47:0]   op1;
    wire [47:0]   op2;

    // Registers
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_ptr <= 3'd0;

            reg_A <= `REG_A_RST_VAL;
            reg_B <= `REG_B_RST_VAL;
            reg_C <= `REG_C_RST_VAL;

            reg_out   <= 3'd0;
            out_valid <= 1'b0;
        end else if (!halt) begin
            instr_ptr <= jump_output;

            reg_A <= (reg_wr_en[0]) ? result : reg_A;
            reg_B <= (reg_wr_en[1]) ? result : reg_B;
            reg_C <= (reg_wr_en[2]) ? result : reg_C;

            // Program output logic
            reg_out   <= (reg_wr_en[3]) ? result[2:0] : reg_out;
            out_valid <= (reg_wr_en[3]);
        end
    end

    // Combo or literal operand
    assign lit_op = {44'd0, operand_id_reg};
    assign shift_combo_op = combo_op[5:0];

    // Operations
    assign shift_output = reg_A >> shift_combo_op;
    assign xor_output   = op1 ^ op2;
    assign mod_output   = op1[2:0];
    assign add_output   = instr_ptr + 4'd2;
    assign jump_output  = (reg_A != 48'd0) ? lit_op : add_output[3:0];

    assign halt = add_output[4];

    // Literal/Combo operand logic
    always@(*) begin
        case (operand_id_reg) begin
            2'd0,
            2'd1,
            2'd2,
            2'd3    : combo_op = lit_op;
            2'd4    : combo_op = reg_A;
            2'd5    : combo_op = reg_B;
            2'd6    : combo_op = reg_C;
            default : combo_op = 48'd0; // unused, so arbitrarily set to 0
        end
    end

    // Operand 1 select logic
    always@(*) begin
        op1 = `COMBO_OP_SEL;
        case (op1_sel) begin
            `COMBO_OP_SEL : op1 = combo_op;
            `LIT_OP_SEL   : op1 = lit_op;
            `REG_B_OP_SEL : op1 = reg_B;
            `REG_C_OP_SEL : op1 = reg_C;
        endcase
    end

    // Operand 2 select logic
    always@(*) begin
        op2 = `COMBO_OP_SEL;
        case (op2_sel) begin
            `COMBO_OP_SEL : op2 = combo_op;
            `LIT_OP_SEL   : op2 = {44'd0, operand_id_reg};
            `REG_B_OP_SEL : op2 = reg_B;
            `REG_C_OP_SEL : op2 = reg_C;
        endcase
    end

    // Operator results logic
    always@(*) begin
        case (operation_sel) begin
            `SHIFT_SEL : results = shift_out;
            `XOR_SEL   : results = xor_out;
            `MOD_SEL   : results = {44'd0, mod_out};
            default    : results = 48'd0;
        end
    end

endmodule
