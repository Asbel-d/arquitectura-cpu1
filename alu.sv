// alu.sv
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
        unique case (alu_ctrl)
            4'b0000: result = a & b;                      // AND
            4'b0001: result = a | b;                      // OR
            4'b0010: result = a + b;                      // ADD
            4'b0110: result = a - b;                      // SUB
            4'b0011: result = a ^ b;                      // XOR
            4'b0100: result = a << b[4:0];                // SLL
            4'b0101: result = a >> b[4:0];                // SRL (logical)
            4'b0111: result = sa >>> b[4:0];              // SRA (arithmetic)
            4'b1000: result = (sa < sb) ? 32'd1 : 32'd0;  // SLT (signed)
            4'b1001: result = (a < b) ? 32'd1 : 32'd0;    // SLTU (unsigned)
            default: result = 32'd0;
        endcase
    end

endmodule
