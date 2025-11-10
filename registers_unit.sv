module registers_unit(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data,
    input  logic        reg_write,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] regs [0:31];
    integer i;

    always_ff @(negedge rst_n or posedge clk) begin
        if (!rst_n)
            for (i = 0; i < 32; i++)
                regs[i] <= i;
        else if (reg_write && rd != 0)
            regs[rd] <= write_data;
    end

    assign read_data1 = regs[rs1];
    assign read_data2 = regs[rs2];

endmodule

