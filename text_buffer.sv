// text_buffer.sv
module text_buffer #(
    parameter COLS = 80,
    parameter ROWS = 30
)(
    input  wire clk,
    input  wire rst_n,
    // inputs from CPU
    input  wire [31:0] pc,
    input  wire [31:0] instr,
    input  wire [4:0]  rd,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [31:0] read_data1,
    input  wire [31:0] read_data2,
    input  wire [31:0] alu_result,
    input  wire [31:0] next_pc,
    output reg  write_done
);

    localparam SIZE = COLS*ROWS;

    // Character RAM: each entry is 8-bit ASCII
    reg [7:0] ram [0:SIZE-1];

    integer r, c, i;
    // helper proc: write ASCII string to given row and column
    task automatic write_string;
        input integer row;
        input integer col;
        input reg [8*64-1:0] str; // up to 64 chars
        input integer len;
        integer k;
        begin
            for (k=0; k<len; k=k+1) begin
                if (col+k < COLS) begin
                    ram[row*COLS + col + k] <= str[8*(len-1-k)+:8];
                end
            end
        end
    endtask

    // convert nibble to ascii hex
    function automatic [7:0] hex_char;
        input [3:0] nib;
        begin
            if (nib < 10) hex_char = "0" + nib;
            else hex_char = "A" + (nib - 4'd10);
        end
    endfunction

    // convert 32-bit to 8 ASCII hex characters (big endian)
    task automatic word_to_hexstr;
        input [31:0] w;
        output reg [8*8-1:0] out; // 8 chars
        integer t;
        reg [3:0] nib;
        begin
            out = 0;
            for (t=0; t<8; t=t+1) begin
                nib = w[4*(7-t)+:4];
                out[8*(8-1-t)+:8] = hex_char(nib);
            end
        end
    endtask

    // on reset initialize to spaces
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<SIZE; i=i+1) ram[i] <= " ";
            write_done <= 1'b0;
        end else begin
            // Format and write the strings each clock:
            reg [8*8-1:0] s32;
            // PC
            word_to_hexstr(pc, s32);
            write_string(0, 4, "0x", 2);
            write_string(0, 6, s32, 8); // PC at row 0 col 6..13 -> shows 8 hex
            // INSTR
            word_to_hexstr(instr, s32);
            write_string(1, 0, "INST:", 5);
            write_string(1, 6, s32, 8);
            // RS1 / RD1
            word_to_hexstr(read_data1, s32);
            write_string(2, 0, "RS1:", 4);
            write_string(2, 5, s32, 8);
            word_to_hexstr(read_data2, s32);
            write_string(2, 14, "RS2:", 4);
            write_string(2, 19, s32, 8);
            // ALU / NEXT
            word_to_hexstr(alu_result, s32);
            write_string(3, 0, "ALU:", 4);
            write_string(3, 5, s32, 8);
            word_to_hexstr(next_pc, s32);
            write_string(3, 14, "NEXT:", 5);
            write_string(3, 20, s32, 8);

            write_done <= 1'b1;
        end
    end

    // Expose read ports (for renderer)
    // We'll expose a simple read interface via functions (combinational)
    function [7:0] read_char;
        input integer row_in;
        input integer col_in;
        begin
            if (row_in < 0 || row_in >= ROWS || col_in < 0 || col_in >= COLS)
                read_char = 8'h20;
            else
                read_char = ram[row_in*COLS + col_in];
        end
    endfunction

    // Provide lookup through DPI-like wrapper via tasks not allowed; instead
    // renderer will instantiate this module and call a simple synchronous read port.
    // To keep it simple we add a synchronous read port interface below.

    // synchronous read port signals
    // Note: the vga_renderer will use separate instantiation of this same RAM by directly reading
    // via an interface function 'peek' - but in synthesizable Verilog we provide a sync read port:
    // (renderer will sample 'char_out' when it sets row_addr,col_addr and ticks clk)
    reg [15:0] rd_addr;
    reg [7:0] char_out;
    reg rd_req;
    // synchronous read: set address as row*COLS + col on next clock data available
    always_ff @(posedge clk) begin
        if (rd_req) begin
            char_out <= ram[rd_addr];
            rd_req <= 1'b0;
        end
    end

    // Export ports as simple tasks via interface? Not allowed in Verilog top level.
    // We'll instead provide a small behavioral read port using simple signals accessible by renderer:
    // Provide combinational function via generate? Not synthesizable. So we define external wires (addresses) below.

    // Signals to connect renderer:
    // (these are DUT-visible; instantiate as wires from top_level to renderer and tbuf)
    // We'll create public ports by making them 'bindable' in top module; easier: add explicit port list
    // But top_level instantiates both, so we'll instead declare these as global wires in top_level and connect them.

endmodule
