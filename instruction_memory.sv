// ========================================================
// INSTRUCTION MEMORY - RISC-V
// Carga las instrucciones desde un archivo HEX externo (program.hex)
// Compatible con DE1-SoC y direccionamiento por bytes
// ========================================================

module instruction_memory (
    input  logic [31:0] addr,     // Dirección del PC (en bytes)
    output logic [31:0] instr     // Instrucción de 32 bits
);

    // Memoria ROM de 256 palabras (1 KB)
    logic [31:0] mem [0:255];

    // Carga automática del archivo .hex
    initial begin
        $display("📥 Cargando instrucciones desde program.hex ...");
        $readmemh("program.hex", mem);
        $display("✅ Instrucciones cargadas correctamente.");
    end

    // Como el PC incrementa de 4 en 4 (dirección por bytes),
    // usamos las posiciones [9:2] para indexar palabras (dividir entre 4)
    assign instr = mem[addr[9:2]];

endmodule
