// data_memory.sv
module data_memory (
    input  logic        clk,
    input  logic        mem_write,
    input  logic        mem_read,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    input  logic [2:0]  funct3,     // determines width and sign
    output logic [31:0] read_data
);

    // 1024 bytes memory
    logic [7:0] mem [0:1023];
    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 8'h00;
        // demo bytes (optional)
        mem[0] = 8'hAA;
        mem[1] = 8'hBB;
        mem[2] = 8'hCC;
        mem[3] = 8'hDD;
    end

    // write (synchronous)
    always_ff @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB
                    mem[addr] <= write_data[7:0];
                end
                3'b001: begin // SH
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                end
                3'b010: begin // SW
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                    mem[addr + 2] <= write_data[23:16];
                    mem[addr + 3] <= write_data[31:24];
                end
                default: ;
            endcase
        end
    end

    // read (combinational)
    always_comb begin
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB (sign-extend)
                    read_data = { {24{mem[addr+0][7]}}, mem[addr+0] };
                end
                3'b001: begin // LH (sign-extend, little-endian)
                    read_data = { {16{mem[addr+1][7]}}, mem[addr+1], mem[addr+0] };
                end
                3'b010: begin // LW
                    read_data = { mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0] };
                end
                3'b100: begin // LBU (zero-extend)
                    read_data = { 24'h0, mem[addr+0] };
                end
                3'b101: begin // LHU (zero-extend)
                    read_data = { 16'h0, mem[addr+1], mem[addr+0] };
                end
                default: read_data = 32'h0;
            endcase
        end else begin
            read_data = 32'h0;
        end
    end

endmodule
