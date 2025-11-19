// registers_unit.sv
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

    // 32 registros de 32 bits
    logic [31:0] regs [0:31];

    integer i;

    // reset and write (synchronous write, asynchronous reset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h0;
        end else begin
            if (reg_write && (rd != 5'd0)) begin
                regs[rd] <= write_data;
            end
            // x0 stays 0
            regs[0] <= 32'h0;
        end
    end

    // combinational reads
    assign read_data1 = regs[rs1];
    assign read_data2 = regs[rs2];

endmodule
