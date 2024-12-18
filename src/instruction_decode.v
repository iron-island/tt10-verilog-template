// Instruction opcodes
`define ADV 3'd0
`define BXL 3'd1
`define BST 3'd2
`define JNZ 3'd3
`define BXC 3'd4
`define OUT 3'd5
`define BDV 3'd6
`define CDV 3'd7

module instruction_decode(
    // Inputs
    input         clk,
    input         rstn,
    input         halt,
    input [2:0]   opcode,
    input [2:0]   operand,
    
    // Outputs
    output [2:0]  operand_id_reg,
    output [1:0]  op1_sel,
    output [1:0]  op2_sel,
    output [1:0]  operation_sel,
    output [4:0]  reg_wr_en,
);

    always@(posedge clk or negedge rstn) begin
        if (!rstn) begin
            operand_id_reg <= 48'd0;

            op1_sel        <= 2'd0;
            op2_sel        <= 2'd0;
            operation_sel  <= 2'd0;
            reg_wr_en      <= 2'd0;
        end else if (!halt) begin
            operand_id_reg <= operand;

            op1_sel        <= next_op1_sel;
            op2_sel        <= next_op2_sel;
            operation_sel  <= next_operation_sel;
            reg_wr_en      <= next_reg_wr_en;
        end
    end

    always@(*) begin
        // Shift operator always has the same operands A >> COMBO_OP
        //   so shift operator only needs operator_sel updated, not
        //   op1_sel and op2_sel
        // Values that aren't used aren't updated and retain their last value
        //   to avoid additional decode logic for them, except for 
        //   write enable bits which are all 0s if unused
        next_op1_sel       = op1_sel;
        next_op2_sel       = op2_sel;
        next_operation_sel = operation_sel;
        next_reg_wr_en     = `NO_WR_EN;

        case (opcode) begin
            `ADV : begin
                // Decode shifter -> A
                //next_op1_sel       = op1_sel; // not used
                //next_op2_sel       = op2_sel; // not used
                next_operation_sel = `SHIFT_SEL;
                next_reg_wr_en     = `REG_A_WR_EN;
            end
            `BXL : begin
                // Decode B ^ LIT_OP -> B
                next_op1_sel       = `REG_B_OP;
                next_op2_sel       = `REG_O_OP;
                next_operation_sel = `XOR_SEL;
                next_reg_wr_en     = `REG_B_WR_EN;
            end
            `BST : begin
                // Decode B mod 8 -> B
                next_op1_sel       = `REG_B_OP;
                //next_op2_sel       = op2_sel; // not used
                next_operation_sel = `MOD_SEL;
                next_reg_wr_en     = `REG_B_WR_EN;
            end
            `JNZ : begin
                // Decode jump
                //next_op1_sel       = op1_sel;  // not used
                //next_op2_sel       = op2_sel;  // not used
                next_operation_sel = `JUMP_SEL;
                //next_reg_wr_en     = reg_wr_en; // not used
            end
            `BXC : begin
                // Decode B ^ C -> B
                next_op1_sel       = `REG_B_OP;
                next_op2_sel       = `REG_C_OP;
                next_operation_sel = `XOR_SEL;
                next_reg_wr_en     = `REG_B_WR_EN;
            end
            `OUT : begin
                // Decode COMBO_OP mod 8 -> out
                next_op1_sel       = `REG_O_OP;
                //next_op2_sel       = op2_sel; // not used
                next_operation_sel = `MODE_SEL;
                next_reg_wr_en     = `REG_O_WR_EN;
            end
            `BDV : begin
                // Decode shifter ->  B
                //next_op1_sel       = op1_sel; // not used
                //next_op2_sel       = op2_sel; // not used
                next_operation_sel = `SHIFT_SEL;
                next_reg_wr_en     = `REG_B_WR_EN;
            end
            `BCV : begin
                // Decode shifter -> C
                //next_op1_sel       = op1_sel; // not used
                //next_op2_sel       = op2_sel; // not used
                next_operation_sel = `SHIFT_SEL;
                next_reg_wr_en     = `REG_C_WR_EN;
            end
        end
    end

endmodule
