// ========================================================
// DATA MEMORY - RISC-V (para instrucciones tipo I y S)
// Compatible con DE1-SoC y direccionamiento por bytes
// ========================================================
module data_memory (
    input  logic        clk,
    input  logic        mem_write,   // Habilita escritura (store)
    input  logic        mem_read,    // Habilita lectura (load)
    input  logic [31:0] addr,        // Dirección byte a byte
    input  logic [31:0] write_data,  // Datos a escribir (para store)
    output logic [31:0] read_data    // Datos leídos (para load)
);

    // Memoria de 1 KB = 256 palabras de 32 bits
    logic [7:0] mem [0:1023]; // 1024 bytes (byte-addressable)

    integer i;

    // Inicialización
    initial begin
        for (i = 0; i < 1024; i++) begin
            mem[i] = 8'h00;
        end

        // Algunos datos de prueba:
        mem[0]  = 8'hAA;
        mem[1]  = 8'hBB;
        mem[2]  = 8'hCC;
        mem[3]  = 8'hDD;
    end

    // Escritura síncrona (solo si mem_write = 1)
    always_ff @(posedge clk) begin
        if (mem_write) begin
            mem[addr]     <= write_data[7:0];
            mem[addr + 1] <= write_data[15:8];
            mem[addr + 2] <= write_data[23:16];
            mem[addr + 3] <= write_data[31:24];
        end
    end

    // Lectura combinacional (solo si mem_read = 1)
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
