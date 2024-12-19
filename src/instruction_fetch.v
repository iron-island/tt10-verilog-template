module instruction_fetch(
    // Inputs
    input wire             clk,
    input wire             rst_n,
    input wire             halt_if,
    input wire             init_regs,
    input wire [2:0]       opcode,
    input wire [2:0]       operand,
    
    // Outputs
    output reg [2:0]       opcode_if_reg,
    output reg [2:0]       operand_if_reg
);

    // Fetch opcode and operand and load to IF pipeline registers
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode_if_reg  <= 3'b000;
            operand_if_reg <= 3'b000;
        end else if (!init_regs && !halt_if) begin
            opcode_if_reg  <= opcode;
            operand_if_reg <= operand;
        end
    end

endmodule
