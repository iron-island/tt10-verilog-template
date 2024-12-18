module instruction_fetch(
    // Inputs
    input wire             clk,
    input wire             rst_n,
    input wire             halt,
    input wire [3:0]       instr_ptr,
    
    // Outputs
    output reg [2:0]       opcode,
    output reg [2:0]       operand,
    output reg [3:0]       instr_ptr_if_reg
);


    // Instruction cache
    // TODO: Replace with dynamically read program inputs
    wire [2:0] program_0;
    wire [2:0] program_1;
    wire [2:0] program_2;
    wire [2:0] program_3;
    wire [2:0] program_4;
    wire [2:0] program_5;
    wire [2:0] program_6;
    wire [2:0] program_7;
    wire [2:0] program_8;
    wire [2:0] program_9;
    wire [2:0] program_10;
    wire [2:0] program_11;
    wire [2:0] program_12;
    wire [2:0] program_13;
    wire [2:0] program_14;
    wire [2:0] program_15;
    assign program_0  = `PROGRAM_0_VAL;
    assign program_1  = `PROGRAM_1_VAL;
    assign program_2  = `PROGRAM_2_VAL;
    assign program_3  = `PROGRAM_3_VAL;
    assign program_4  = `PROGRAM_4_VAL;
    assign program_5  = `PROGRAM_5_VAL;
    assign program_6  = `PROGRAM_6_VAL;
    assign program_7  = `PROGRAM_7_VAL;
    assign program_8  = `PROGRAM_8_VAL;
    assign program_9  = `PROGRAM_9_VAL;
    assign program_10 = `PROGRAM_10_VAL;
    assign program_11 = `PROGRAM_11_VAL;
    assign program_12 = `PROGRAM_12_VAL;
    assign program_13 = `PROGRAM_13_VAL;
    assign program_14 = `PROGRAM_14_VAL;
    assign program_15 = `PROGRAM_15_VAL;

    reg [2:0] next_opcode;
    reg [2:0] next_operand;

    // Fetch opcode and operands
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode  <= 3'b000;
            operand <= 3'b000;
            
            instr_ptr_if_reg <= 4'd0;
        end else if (!halt) begin
            opcode  <= next_opcode;
            operand <= next_operand;

            instr_ptr_if_reg <= instr_ptr;
        end
    end

    always@(*) begin
        case (instr_ptr)
            4'd0  : begin next_opcode = program_0;  next_operand = program_1;  end
            4'd2  : begin next_opcode = program_2;  next_operand = program_3;  end
            4'd4  : begin next_opcode = program_4;  next_operand = program_5;  end
            4'd6  : begin next_opcode = program_6;  next_operand = program_7;  end
            4'd8  : begin next_opcode = program_8;  next_operand = program_9;  end
            4'd10 : begin next_opcode = program_10; next_operand = program_11; end
            4'd12 : begin next_opcode = program_12; next_operand = program_13; end
            4'd14 : begin next_opcode = program_14; next_operand = program_15; end
            // TODO: handle incorrect program when instruction pointer is not aligned to opcode
            default: begin next_opcode = 3'd0; next_operand = 3'd0; end
        endcase
    end

endmodule
