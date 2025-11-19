module data_memory (
    input  logic        clk,
    input  logic        mem_write,
    input  logic        mem_read,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    
    logic [7:0] mem [0:1023];

    integer i;


    initial begin
        for (i = 0; i < 1024; i++) begin
            mem[i] = 8'h00;
        end

    
        mem[0]  = 8'hAA;
        mem[1]  = 8'hBB;
        mem[2]  = 8'hCC;
        mem[3]  = 8'hDD;
    end

    
    always_ff @(posedge clk) begin
        if (mem_write) begin
            mem[addr]     <= write_data[7:0];
            mem[addr + 1] <= write_data[15:8];
            mem[addr + 2] <= write_data[23:16];
            mem[addr + 3] <= write_data[31:24];
        end
    end

    
    always_comb begin
        if (mem_read) begin
            read_data = { mem[addr + 3],
                          mem[addr + 2],
                          mem[addr + 1],
                          mem[addr + 0] };
        end else begin
            read_data = 32'h00000000;
        end
    end

endmodule
