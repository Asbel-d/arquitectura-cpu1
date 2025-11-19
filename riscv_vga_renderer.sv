// riscv_vga_renderer.sv
`timescale 1ns/1ps
module riscv_vga_renderer (
    input  wire        vgaclk,
    input  wire        reset_n,
    input  wire [10:0] hcount,
    input  wire [9:0]  vcount,
    input  wire        video_on,
    // CPU debug signals
    input  wire [31:0] pc,
    input  wire [31:0] instr,
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [31:0] alu_result,
    // VGA outputs (8-bit each)
    output reg  [7:0]  vga_r,
    output reg  [7:0]  vga_g,
    output reg  [7:0]  vga_b
);

    // Screen geometry (1280x800, font 8x16)
    localparam CHAR_W = 8;
    localparam CHAR_H = 16;
    localparam COLS = 1280 / CHAR_W; // 160
    localparam ROWS = 800  / CHAR_H; // 50

    // Where to place each labeled line (0-based rows)
    localparam LINE_PC    = 2;
    localparam LINE_INSTR = 4;
    localparam LINE_RS1   = 6;
    localparam LINE_RS2   = 8;
    localparam LINE_ALU   = 10;

    // helper: produce ascii hex string of a 32-bit word (8 chars) in order MSB..LSB
    function automatic [8*8-1:0] to_hex_ascii;
        input [31:0] w;
        integer i;
        reg [7:0] ch;
        begin
            to_hex_ascii = 0;
            for (i = 0; i < 8; i = i + 1) begin
                // nibble from MSB to LSB
                reg [3:0] nib;
                nib = w >> (28 - i*4);
                if (nib < 10) ch = "0" + nib;
                else ch = "A" + (nib - 4'd10);
                to_hex_ascii[ (8*(7-i)) +: 8 ] = ch;
            end
        end
    endfunction

    // precompute ASCII strings (COMBINATIONAL)
    wire [8*8-1:0] pc_ascii    = to_hex_ascii(pc);
    wire [8*8-1:0] instr_ascii = to_hex_ascii(instr);
    wire [8*8-1:0] rs1_ascii   = to_hex_ascii(rs1_data);
    wire [8*8-1:0] rs2_ascii   = to_hex_ascii(rs2_data);
    wire [8*8-1:0] alu_ascii   = to_hex_ascii(alu_result);

    // font rom interface: 256 chars x 16 rows x 8 bits
    // font_rom module must provide: font_byte = font_rom(char_code, row)
    // We'll instantiate a small synchronous ROM that outputs row bits combinationally.
    // Address calculation:
    wire [6:0] char_col = hcount / CHAR_W; // up to 159 -> needs 8 bits, but 7 is enough for 0..159 (use 8 to be safe)
    wire [5:0] char_row = vcount / CHAR_H; // up to 49

    wire [2:0] pixel_x = hcount % CHAR_W;  // 0..7
    wire [3:0] pixel_y = vcount % CHAR_H;  // 0..15

    // determine which character to show at current char_col,char_row
    // default background - show only our text lines
    reg [7:0] cur_char;
    reg [3:0] cur_char_row; // 0..15
    always_comb begin
        cur_char = 8'h20; // space by default
        cur_char_row = pixel_y;
        // PC line: show "PC: " then 8 hex
        if (char_row == LINE_PC) begin
            if (char_col == 0) cur_char = " ";
            else if (char_col == 1) cur_char = "P";
            else if (char_col == 2) cur_char = "C";
            else if (char_col == 3) cur_char = ":";
            else if (char_col >= 5 && char_col < 13) begin
                // place pc_ascii at columns 5..12
                integer idx = char_col - 5;
                cur_char = pc_ascii[ (8*(7-idx)) +: 8 ];
            end
        end
        // INSTR line
        else if (char_row == LINE_INSTR) begin
            if (char_col == 1) cur_char = "I";
            else if (char_col == 2) cur_char = "N";
            else if (char_col == 3) cur_char = "S";
            else if (char_col == 4) cur_char = "T";
            else if (char_col == 5) cur_char = "R";
            else if (char_col == 6) cur_char = ":";
            else if (char_col >= 8 && char_col < 16) begin
                integer idx = char_col - 8;
                cur_char = instr_ascii[ (8*(7-idx)) +: 8 ];
            end
        end
        // RS1 line
        else if (char_row == LINE_RS1) begin
            if (char_col == 1) cur_char = "R";
            else if (char_col == 2) cur_char = "S";
            else if (char_col == 3) cur_char = "1";
            else if (char_col == 4) cur_char = ":";
            else if (char_col >= 6 && char_col < 14) begin
                integer idx = char_col - 6;
                cur_char = rs1_ascii[ (8*(7-idx)) +: 8 ];
            end
        end
        // RS2 line
        else if (char_row == LINE_RS2) begin
            if (char_col == 1) cur_char = "R";
            else if (char_col == 2) cur_char = "S";
            else if (char_col == 3) cur_char = "2";
            else if (char_col == 4) cur_char = ":";
            else if (char_col >= 6 && char_col < 14) begin
                integer idx = char_col - 6;
                cur_char = rs2_ascii[ (8*(7-idx)) +: 8 ];
            end
        end
        // ALU line
        else if (char_row == LINE_ALU) begin
            if (char_col == 1) cur_char = "A";
            else if (char_col == 2) cur_char = "L";
            else if (char_col == 3) cur_char = "U";
            else if (char_col == 4) cur_char = ":";
            else if (char_col >= 6 && char_col < 14) begin
                integer idx = char_col - 6;
                cur_char = alu_ascii[ (8*(7-idx)) +: 8 ];
            end
        end
    end

    // font ROM instantiation (reads font.mem using $readmemh inside)
    // font_rom returns 8-bit row data for given char and row (bit7..bit0)
    wire [7:0] font_rowbyte;
    font_rom font0 (
        .char_code(cur_char),
        .row(pixel_y),
        .rowbyte(font_rowbyte)
    );

    // pick pixel bit
    wire font_pixel = font_rowbyte[7 - pixel_x];

    // color palette — choose simple colors: background dark, text green-ish, boxes maybe cyan
    localparam [23:0] COLOR_BG  = 24'h001020; // dark blueish
    localparam [23:0] COLOR_TEXT = 24'h00FF80; // greenish
    localparam [23:0] COLOR_LABEL = 24'h80FFDF;

    // compose RGB each pixel
    always_ff @(posedge vgaclk or negedge reset_n) begin
        if (!reset_n) begin
            vga_r <= 8'h00;
            vga_g <= 8'h00;
            vga_b <= 8'h00;
        end else begin
            if (!video_on) begin
                vga_r <= 8'h00;
                vga_g <= 8'h00;
                vga_b <= 8'h00;
            end else begin
                if (font_pixel) begin
                    // differentiate label letters (like "PC"/"INSTR") vs hex: simple heuristic
                    if ((char_row == LINE_PC && char_col >=1 && char_col <=3) ||
                        (char_row == LINE_INSTR && char_col >=1 && char_col <=7) ||
                        (char_row == LINE_RS1 && char_col >=1 && char_col <=4) ||
                        (char_row == LINE_RS2 && char_col >=1 && char_col <=4) ||
                        (char_row == LINE_ALU && char_col >=1 && char_col <=4) ) begin
                        vga_r <= COLOR_LABEL[23:16];
                        vga_g <= COLOR_LABEL[15:8];
                        vga_b <= COLOR_LABEL[7:0];
                    end else begin
                        vga_r <= COLOR_TEXT[23:16];
                        vga_g <= COLOR_TEXT[15:8];
                        vga_b <= COLOR_TEXT[7:0];
                    end
                end else begin
                    vga_r <= COLOR_BG[23:16];
                    vga_g <= COLOR_BG[15:8];
                    vga_b <= COLOR_BG[7:0];
                end
            end
        end
    end

endmodule
