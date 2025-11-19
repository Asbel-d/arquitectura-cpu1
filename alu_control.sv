// alu_control.sv
module alu_control(
    input  logic [6:0] funct7,
    input  logic [2:0] funct3,
    input  logic [1:0] alu_op,    // from main control
    output logic [3:0] alu_ctrl
);

    // alu_ctrl encoding (chosen for this design)
    // 0000 AND
    // 0001 OR
    // 0010 ADD
    // 0110 SUB
    // 0011 XOR
    // 0100 SLL
    // 0101 SRL
    // 0111 SRA
    // 1000 SLT
    // 1001 SLTU

    always_comb begin
        unique case (alu_op)
            2'b00: alu_ctrl = 4'b0010; // for loads/stores/addi -> ADD
            2'b01: alu_ctrl = 4'b0110; // for branches -> SUB (branch unit does comparison)
            default: begin // 2'b10 -> R-type, 2'b11 -> I-type ALU
                // For R-type: check funct3 + funct7
                unique case (funct3)
                    3'b000: begin // add/sub
                        if (funct7 == 7'b0100000)
                            alu_ctrl = 4'b0110; // SUB
                        else
                            alu_ctrl = 4'b0010; // ADD
                    end
                    3'b001: alu_ctrl = 4'b0100; // SLL
                    3'b010: alu_ctrl = 4'b1000; // SLT
                    3'b011: alu_ctrl = 4'b1001; // SLTU
                    3'b100: alu_ctrl = 4'b0011; // XOR
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = 4'b0111; // SRA
                        else
                            alu_ctrl = 4'b0101; // SRL
                    end
                    3'b110: alu_ctrl = 4'b0001; // OR
                    3'b111: alu_ctrl = 4'b0000; // AND
                    default: alu_ctrl = 4'b0010;
                endcase
            end
        endcase
    end

endmodule
