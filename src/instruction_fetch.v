module instruction_fetch(
    // Inputs
    input         clk,
    input         rstn,
    input         halt,
    input [2:0]   program [3:0],
    input [3:0]   instr_ptr,
    
    // Outputs
    output [2:0]  opcode,
    output [2:0]  operand
);

    // Instruction cache
    always@(posedge clk or negedge rstn) begin
        if (!rstn) begin
            opcode  <= 3'b000;
            operand <= 3'b000;
        end else if (!halt) begin
            opcode  <= program[instr_ptr];
            operand <= program[instr_ptr+1];
        end
    end

endmodule
