// =======================================
// BRANCH UNIT - RISC-V RV32I
// =======================================
module branch_unit(
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    input  logic [2:0]  funct3,
    output logic        take_branch
);

    logic signed [31:0] s_rs1;
    logic signed [31:0] s_rs2;

    always_comb begin
        // conversiones a signed
        s_rs1 = rs1;
        s_rs2 = rs2;

        unique case (funct3)
            3'b000: take_branch = (s_rs1 == s_rs2);       // BEQ
            3'b001: take_branch = (s_rs1 != s_rs2);       // BNE
            3'b100: take_branch = (s_rs1 <  s_rs2);       // BLT
            3'b101: take_branch = (s_rs1 >= s_rs2);       // BGE
            3'b110: take_branch = (rs1  <  rs2);          // BLTU
            3'b111: take_branch = (rs1  >= rs2);          // BGEU
            default: take_branch = 1'b0;
        endcase
    end

endmodule
