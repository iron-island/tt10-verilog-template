module instruction_fetch(
    // Inputs
    input         clk,
    input         rst_n,
    input         halt,
    input [2:0]   program [3:0],
    input [3:0]   instr_ptr,
    
    // Outputs
    output [2:0]  opcode,
    output [2:0]  operand
);


    // Instruction cache
    // TODO: Replace with dynamically read program inputs
    wire [2:0] program [3:0];
    assign program[ 0] = `PROGRAM_0_VAL;
    assign program[ 1] = `PROGRAM_1_VAL;
    assign program[ 2] = `PROGRAM_2_VAL;
    assign program[ 3] = `PROGRAM_3_VAL;
    assign program[ 4] = `PROGRAM_4_VAL;
    assign program[ 5] = `PROGRAM_5_VAL;
    assign program[ 6] = `PROGRAM_6_VAL;
    assign program[ 7] = `PROGRAM_7_VAL;
    assign program[ 8] = `PROGRAM_8_VAL;
    assign program[ 9] = `PROGRAM_9_VAL;
    assign program[10] = `PROGRAM_10_VAL;
    assign program[11] = `PROGRAM_11_VAL;
    assign program[12] = `PROGRAM_12_VAL;
    assign program[13] = `PROGRAM_13_VAL;
    assign program[14] = `PROGRAM_14_VAL;

    // Fetch opcode and operands
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode  <= 3'b000;
            operand <= 3'b000;
        end else if (!halt) begin
            opcode  <= program[instr_ptr];
            operand <= program[instr_ptr+1];
        end
    end

endmodule
