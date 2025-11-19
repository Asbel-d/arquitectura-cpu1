// imm_generator.sv
// Genera immediatos para I, S, B, U, J
module imm_generator (
    input  logic [31:0] instr,
    output logic [31:0] imm
);
    logic [6:0] opcode = instr[6:0];

    always_comb begin
        imm = 32'h0;
        unique case (opcode)
            7'b0010011, // I (addi...)
            7'b0000011, // loads
            7'b1100111: // jalr
                imm = {{20{instr[31]}}, instr[31:20]};

            7'b0100011: // S-type (store)
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            7'b1100011: // B-type
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm = {instr[31:12], 12'd0};

            7'b1101111: // J-type (JAL)
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

            default: imm = 32'h0;
        endcase
    end

endmodule
