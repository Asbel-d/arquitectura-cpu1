// vga_timing.sv (640x480@60, pixel clock 25 MHz)
module vga_timing (
    input  wire clk,      // 25 MHz pixel clock
    input  wire rst_n,
    output wire hsync,
    output wire vsync,
    output wire [9:0] pixel_x, // 0..639 visible
    output wire [9:0] pixel_y, // 0..479 visible
    output wire active
);

    // timing constants
    localparam H_VISIBLE = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800

    localparam V_VISIBLE = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525

    reg [10:0] hcount;
    reg [9:0]  vcount;

    // counters
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hcount <= 0;
            vcount <= 0;
        end else begin
            if (hcount == H_TOTAL - 1) begin
                hcount <= 0;
                if (vcount == V_TOTAL - 1) vcount <= 0;
                else vcount <= vcount + 1;
            end else begin
                hcount <= hcount + 1;
            end
        end
    end

    // hsync/vsync (active low)
    assign hsync = ~((hcount >= (H_VISIBLE + H_FRONT)) && (hcount < (H_VISIBLE + H_FRONT + H_SYNC)));
    assign vsync = ~((vcount >= (V_VISIBLE + V_FRONT)) && (vcount < (V_VISIBLE + V_FRONT + V_SYNC)));

    // active region
    assign active = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);
    assign pixel_x = (hcount < H_VISIBLE) ? hcount[9:0] : 10'd0;
    assign pixel_y = (vcount < V_VISIBLE) ? vcount[9:0] : 10'd0;

endmodule

