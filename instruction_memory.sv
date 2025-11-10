module instruction_memory (
    input  logic [31:0] addr,     
    output logic [31:0] instr     
);

    
    logic [31:0] mem [0:255];

    
    initial begin
        $display("📥 Cargando instrucciones desde program.hex ...");
        $readmemh("program.hex", mem);
        $display("✅ Instrucciones cargadas correctamente.");
    end

    assign instr = mem[addr[9:2]];

endmodule
