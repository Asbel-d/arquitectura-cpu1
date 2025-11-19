// control_unit.sv
module control_unit(
    input  logic [6:0] opcode,
    output logic       reg_write,
    output logic       alu_src,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       branch,
    output logic       jump,
    output logic [1:0] alu_op
);

    // Default
    always_comb begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        unique case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I-type ALU (addi, andi, ...)
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b0000011: begin // Loads
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00; // ADD for address
            end
            7'b0100011: begin // Stores
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00; // ADD for address
            end
            7'b1100011: begin // Branches
                branch  = 1'b1;
                alu_op  = 2'b01; // SUB for compare
            end
            7'b1101111: begin // JAL
                reg_write = 1'b1;
                jump = 1'b1;
            end
            7'b1100111: begin // JALR
                reg_write = 1'b1;
                alu_src = 1'b1;
                jump = 1'b1;
            end
            7'b0110111: begin // LUI
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 2'b11;
            end
            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 2'b11;
            end
            default: begin
                // keep defaults (NOP)
            end
        endcase
    end

endmodule
