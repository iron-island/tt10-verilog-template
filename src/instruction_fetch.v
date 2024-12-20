module instruction_fetch(
    // Inputs
    input wire             clk,
    input wire             rst_n,
    input wire             halt_if,
    input wire             init_regs,
    input wire [2:0]       opcode,
    input wire [2:0]       operand,
    input wire             reg_A_wr_en,
    input wire             reg_A_nz,
    input wire [2:0]       mod_output,
    
    // Outputs
    output reg [2:0]       opcode_if_reg,
    output reg [2:0]       operand_if_reg,
    output reg             branch_predicted
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

    // Static branch prediction
    // Combinational logic to avoid cycle delay
    // Jump whenever opcode is for JNZ and:
    //   1: register A won't change, and it is non-zero
    //   2: register A will change, and the data to be written is non-zero
    always@(*) begin
        branch_predicted = 1'b0;

        if (opcode == `JNZ) begin
            if (((!reg_A_wr_en) && (reg_A_nz)) || 
                (reg_A_wr_en && (mod_output != 3'd0))) begin
                branch_predicted = 1'b1;
            end
        end
    end

endmodule
