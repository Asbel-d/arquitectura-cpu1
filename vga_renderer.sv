// vga_renderer.sv
module vga_renderer (
    input  wire clk,
    input  wire rst_n,
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire active,
    // VGA outputs
    output reg [3:0] vga_red,
    output reg [3:0] vga_green,
    output reg [3:0] vga_blue,
    // hsync/vsync (pass-through from timing)
    input  wire hsync,
    input  wire vsync
);

    // screen geometry in chars
    localparam CHAR_W = 8;
    localparam CHAR_H = 16;
    localparam COLS = 80;
    localparam ROWS = 30;

    // compute which char cell and which pixel inside char
    wire [6:0] col_idx = pixel_x / CHAR_W; // 0..79
    wire [5:0] row_idx = pixel_y / CHAR_H; // 0..29
    wire [2:0] px_in_char = pixel_x % CHAR_W; // 0..7
    wire [3:0] py_in_char = pixel_y % CHAR_H; // 0..15

    // We'll assume we can read text_buffer via a synchronous read port:
    // connect to external signals (these will be wires in top and wired to tbuf ports)
    // To keep module standalone for now, we implement an internal simple font for ASCII hex and space.
    // But ideally you instantiate your font_rom here.

    // Simple built-in tiny font for 0-9,A-F and space (8x16). For brevity we draw a filled block for any non-space.
    // A real font ROM should be used; here we return 1-bit pixel on/off: font_pixel
    reg font_pixel;

    // Simple rendering: if active and char != space, draw white; else black.
    always_comb begin
        // default off
        font_pixel = 1'b0;
        // show a simple pattern for hex digits for debugging:
        // We'll approximate: if (row_idx < ROWS && col_idx < COLS) then show checker for non-space
        if (active) begin
            font_pixel = ((px_in_char + py_in_char) & 1); // checkerboard for visibility
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vga_red <= 4'h0;
            vga_green <= 4'h0;
            vga_blue <= 4'h0;
        end else begin
            if (!active) begin
                vga_red <= 4'h0;
                vga_green <= 4'h0;
                vga_blue <= 4'h0;
            end else begin
                if (font_pixel) begin
                    vga_red <= 4'hF;
                    vga_green <= 4'hF;
                    vga_blue <= 4'hF;
                end else begin
                    vga_red <= 4'h0;
                    vga_green <= 4'h0;
                    vga_blue <= 4'h0;
                end
            end
        end
    end

endmodule
