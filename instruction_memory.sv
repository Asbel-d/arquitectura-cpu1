// instruction_memory.sv
module instruction_memory (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    // 256 x 32-bit memory (1 KB)
    logic [31:0] mem [0:255];

    initial begin
        $display("Intentando cargar instrucciones desde program.hex...");
        // program.hex must contain lines like: 000007b7
        $readmemh("program.hex", mem);
        $display("✅ Instrucciones cargadas desde program.hex (readmemh).");
    end

    // addr is byte address; word index = addr[9:2] (256 words)
    logic [7:0] idx;
    assign idx = addr[9:2];
    assign instr = mem[idx];

endmodule
