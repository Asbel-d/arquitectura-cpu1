module top_level (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [9:0] SW,          
    output wire [6:0] display,     
    output wire [6:0] display1,   
    output wire [6:0] display2,   
    output wire [6:0] display3,    
    output wire [6:0] display4,    
    output wire [6:0] display5,   
    output wire [9:0] LEDR         
);

    
    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] read_data1, read_data2;
    logic [4:0]  rs1, rs2, rd;

   
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'b0;
        else
            pc <= pc + 4;
    end

    
    instruction_memory imem (
        .addr(pc),
        .instr(instr)
    );

   
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];

    registers_unit reg_unit (
        .clk(clk),
        .rst_n(rst_n),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(32'b0),
        .reg_write(1'b0),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    logic [23:0] disp_val;

    always_comb begin
        case (SW[1])
            1'b0: begin
                
                if (SW[0] == 1'b0)
                    disp_val = instr[23:0];   
                else
                    disp_val = {16'b0, instr[31:24]}; 
            end

            1'b1: begin
                
                if (SW[0] == 1'b0)
                    disp_val = read_data1[23:0];
                else
                    disp_val = read_data2[23:0];
            end

            default: disp_val = 24'h000000;
        endcase
    end

   
    hex7seg h0 (.val(disp_val[3:0]),   .display(display));
    hex7seg h1 (.val(disp_val[7:4]),   .display(display1));
    hex7seg h2 (.val(disp_val[11:8]),  .display(display2));
    hex7seg h3 (.val(disp_val[15:12]), .display(display3));
    hex7seg h4 (.val(disp_val[19:16]), .display(display4));
    hex7seg h5 (.val(disp_val[23:20]), .display(display5));

   
    assign LEDR = pc[11:2];

endmodule
