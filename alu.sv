// ========================================================
// ALU - R, I, S (RISC-V)
// ========================================================
module alu(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_ctrl,
    output logic [31:0] result
);
    logic signed [31:0] sa, sb;
    assign sa = a;
    assign sb = b;

    always_comb begin
        case (alu_ctrl)
            4'b0000: result = a & b;
            4'b0001: result = a | b;
            4'b0010: result = a + b;
            4'b0110: result = a - b;
            4'b0011: result = a ^ b;
            4'b0100: result = a << b[4:0];
            4'b0101: result = a >> b[4:0];
            4'b0111: result = sa >>> b[4:0];
            4'b1000: result = (sa < sb) ? 32'b1 : 32'b0;
            4'b1001: result = (a < b) ? 32'b1 : 32'b0;
            default: result = 32'b0;
        endcase
    end
endmodule
