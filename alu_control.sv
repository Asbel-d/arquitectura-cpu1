module alu_control(
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alu_ctrl,
    output logic       alu_src,
    output logic       mem_write,
    output logic       mem_read,
    output logic       reg_write,
    output logic [1:0] result_src
);
    always_comb begin
        alu_ctrl   = 4'b0000;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        mem_read   = 1'b0;
        reg_write  = 1'b0;
        result_src = 2'b00;

        case (opcode)
            7'b0110011: begin
                reg_write = 1'b1;
                case ({funct7, funct3})
                    10'b0000000_000: alu_ctrl = 4'b0010;
                    10'b0100000_000: alu_ctrl = 4'b0110;
                    10'b0000000_111: alu_ctrl = 4'b0000;
                    10'b0000000_110: alu_ctrl = 4'b0001;
                    10'b0000000_100: alu_ctrl = 4'b0011;
                    10'b0000000_001: alu_ctrl = 4'b0100;
                    10'b0000000_101: alu_ctrl = 4'b0101;
                    10'b0100000_101: alu_ctrl = 4'b0111;
                    10'b0000000_010: alu_ctrl = 4'b1000;
                    10'b0000000_011: alu_ctrl = 4'b1001;
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            7'b0010011: begin
                alu_ctrl   = 4'b0010;
                alu_src    = 1'b1;
                reg_write  = 1'b1;
            end

            7'b0000011: begin
                alu_ctrl   = 4'b0010;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                reg_write  = 1'b1;
                result_src = 2'b01;
            end

            7'b0100011: begin
                alu_ctrl   = 4'b0010;
                alu_src    = 1'b1;
                mem_write  = 1'b1;
            end
        endcase
    end
endmodule
