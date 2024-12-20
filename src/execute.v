module execute(
    // Inputs
    input wire             clk,
    input wire             rst_n,
    input wire             A_lsb_opcode_0,
    input wire             B_lsb_opcode_1,
    input wire             C_lsb_opcode_2,
    input wire             init_regs,
    input wire [2:0]       operand_id_reg,
    input wire [1:0]       op1_sel,
    input wire [1:0]       op2_sel,
    input wire [1:0]       operation_sel,
    input wire [4:0]       reg_wr_en,
    input wire [4:0]       instr_ptr,
    
    // Outputs
    output reg [4:0]       add_output,
    output wire            halt_if,
    output wire            halt_id,
    output wire            halt_ex,
    output reg [2:0]       reg_out,
    output reg             out_valid,
    output wire            reg_A_nz,
    output wire [2:0]      mod_output
);

    // Combo and literal operand
    reg  [47:0]   combo_op;
    wire [2:0]    lit_op;

    // Combo operand used for shift, limited to 6 bits = ceil(log2(48))
    //   since register A can only be shifted by a maximum of 48 bits,
    //   and to reduce bitwidth and shifter length
    wire [5:0]    shift_combo_op;

    // Operation outputs
    wire [47:0]   shift_output;
    wire [47:0]   xor_output;
    wire [4:0]    next_add_output;
    wire [4:0]    jump_output;

    // Selected operands
    reg [47:0]    op1;
    reg [47:0]    op2;

    // Result after operation mux
    reg [47:0]    result;

    // Registers
    reg [47:0]    reg_A;
    reg [47:0]    reg_B;
    reg [47:0]    reg_C;

    // Shift register for initial and final 2-cycle pipeline delay
    reg [1:0]     init_shift_reg;
    reg [1:0]     halt_shift_reg;

    // Registers
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_shift_reg <= 2'd0;
            halt_shift_reg <= 2'd0;

            add_output <= 5'd0;

            reg_A <= 48'd0;
            reg_B <= 48'd0;
            reg_C <= 48'd0;

            reg_out   <= 3'd0;
            out_valid <= 1'b0;
        end else if (init_regs) begin
            reg_A <= {reg_A[46:0], A_lsb_opcode_0};
            reg_B <= {reg_B[46:0], B_lsb_opcode_1};
            reg_C <= {reg_C[46:0], C_lsb_opcode_2};
        end else begin
            init_shift_reg <= {init_shift_reg[0], 1'b1};
            halt_shift_reg <= {halt_shift_reg[0], halt_if};

            add_output <= next_add_output;

            reg_A <= (reg_wr_en[0]) ? result : reg_A;
            reg_B <= (reg_wr_en[1]) ? result : reg_B;
            reg_C <= (reg_wr_en[2]) ? result : reg_C;

            // Program output logic
            reg_out   <= (reg_wr_en[3]) ? result[2:0] : reg_out;
            out_valid <= (reg_wr_en[3]);
        end
    end

    // Halt signals
    assign halt_if = instr_ptr[4]; // driven by combinational so that IF stage would immediately halt
    assign halt_id = halt_shift_reg[0];
    assign halt_ex = halt_shift_reg[1];

    // Combo or literal operand
    assign lit_op         = operand_id_reg;
    assign shift_combo_op = combo_op[5:0];

    // Operations
    assign shift_output = reg_A >> shift_combo_op;
    assign xor_output   = op1 ^ op2;
    assign mod_output   = op1[2:0];

    assign reg_A_nz     = (reg_A != 48'd0);
    assign next_add_output   = (init_shift_reg[1]) ? instr_ptr + 5'd2 : instr_ptr;
    assign jump_output  = (reg_A_nz && (operation_sel == `JUMP_SEL)) ? {2'd0, lit_op} : next_add_output;

    // Literal/Combo operand logic
    always@(*) begin
        case (operand_id_reg)
            3'd0,
            3'd1,
            3'd2,
            3'd3    : combo_op = {44'd0, lit_op};
            3'd4    : combo_op = reg_A;
            3'd5    : combo_op = reg_B;
            3'd6    : combo_op = reg_C;
            default : combo_op = 48'd0; // unused, so arbitrarily set to 0
        endcase
    end

    // Operand 1 select logic
    always@(*) begin
        op1 = `COMBO_OP_SEL;
        case (op1_sel)
            `COMBO_OP_SEL : op1 = combo_op;
            `LIT_OP_SEL   : op1 = {44'd0, lit_op};
            `REG_B_SEL    : op1 = reg_B;
            `REG_C_SEL    : op1 = reg_C;
        endcase
    end

    // Operand 2 select logic
    always@(*) begin
        op2 = `COMBO_OP_SEL;
        case (op2_sel)
            `COMBO_OP_SEL : op2 = combo_op;
            `LIT_OP_SEL   : op2 = {44'd0, lit_op};
            `REG_B_SEL    : op2 = reg_B;
            `REG_C_SEL    : op2 = reg_C;
        endcase
    end

    // Operator mux result logic
    always@(*) begin
        case (operation_sel)
            `SHIFT_SEL : result = shift_output;
            `XOR_SEL   : result = xor_output;
            `MOD_SEL   : result = {44'd0, mod_output};
            default    : result = 48'd0;
        endcase
    end

endmodule
