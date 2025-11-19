// font_rom.sv
module font_rom (
    input  wire [7:0]  char_code, // ASCII code
    input  wire [3:0]  row,       // 0..15
    output wire [7:0]  rowbyte    // 8 bits for that row
);
    // memory: 256 chars * 16 rows = 4096 bytes
    reg [7:0] mem [0:4095];

    initial begin
        // expects a file "font.mem" in project root where each line is 2 hex chars e.g.
        // 00
        // 00
        // 18
        // ...
        // The file must contain 4096 lines (or fewer; missing lines default to 00).
        $display("font_rom: loading font.mem ...");
        $readmemh("font.mem", mem);
    end

    // compute index: char_code*16 + row
    wire [11:0] idx = {char_code, 4'b0} + row;
    assign rowbyte = mem[idx];

endmodule
