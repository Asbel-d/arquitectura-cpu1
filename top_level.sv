// top_level.sv
`timescale 1ns/1ps
module top_level (
    input  wire       clk,        // 50 MHz en DE1-SoC
    input  wire       rst_n,      // reset activo bajo (DE1 switches)
    input  wire [9:0] SW,         // switches
    output wire [6:0] display,
    output wire [6:0] display1,
    output wire [6:0] display2,
    output wire [6:0] display3,
    output wire [6:0] display4,
    output wire [6:0] display5,
    output wire [9:0] LEDR,
    // VGA pins (exportados desde top)
    output wire [7:0] vga_r,
    output wire [7:0] vga_g,
    output wire [7:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync,
    output wire       vga_clock
);

    // =========================
    // CPU signals (single-cycle style)
    // =========================
    logic [31:0] pc;
    logic [31:0] instr;

    logic [4:0] rs1, rs2, rd;
    logic [31:0] read_data1, read_data2;
    logic [31:0] write_data;
    logic        reg_write;

    logic        alu_src;
    logic        mem_read, mem_write;
    logic        mem_to_reg;
    logic        branch;
    logic        jump;
    logic [1:0]  alu_op;
    logic [3:0]  alu_ctrl;
    logic [31:0] alu_in2;
    logic [31:0] alu_result;
    logic [31:0] mem_read_data;
    logic [2:0]  mem_funct3;
    logic        take_branch;

    logic signed [31:0] imm_i, imm_s, imm_b, imm_u, imm_j, imm;
    logic [31:0] pc_plus4;

    assign pc_plus4 = pc + 32'd4;

    // --------------------
    // Instruction memory
    // --------------------
    instruction_memory imem (
        .addr(pc),
        .instr(instr)
    );

    // --------------------
    // decode fields
    // --------------------
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];
    assign mem_funct3 = instr[14:12];

    // immediates
    assign imm_i = $signed(instr[31:20]);
    assign imm_s = $signed({instr[31:25], instr[11:7]});
    assign imm_b = $signed({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0});
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = $signed({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});

    always_comb begin
        unique case (instr[6:0])
            7'b0010011, 7'b0000011, 7'b1100111: imm = imm_i;
            7'b0100011: imm = imm_s;
            7'b1100011: imm = imm_b;
            7'b0110111, 7'b0010111: imm = imm_u;
            7'b1101111: imm = imm_j;
            default: imm = 32'sd0;
        endcase
    end

    // --------------------
    // control unit
    // --------------------
    logic [6:0] opcode;
    assign opcode = instr[6:0];

    control_unit ctrl (
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op)
    );

    // --------------------
    // registers
    // --------------------
    registers_unit reg_unit (
        .clk(clk),
        .rst_n(rst_n),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .reg_write(reg_write),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // --------------------
    // ALU control + ALU
    // --------------------
    alu_control alu_ctrl_unit (
        .funct7(instr[31:25]),
        .funct3(instr[14:12]),
        .alu_op(alu_op),
        .alu_ctrl(alu_ctrl)
    );

    assign alu_in2 = (alu_src) ? imm : read_data2;

    alu alu_unit (
        .a(read_data1),
        .b(alu_in2),
        .alu_ctrl(alu_ctrl),
        .result(alu_result)
    );

    // --------------------
    // branch unit
    // --------------------
    branch_unit branch_unit0 (
        .funct3(instr[14:12]),
        .rs1(read_data1),
        .rs2(read_data2),
        .take_branch(take_branch)
    );

    // next PC
    logic [31:0] next_pc;
    always_comb begin
        next_pc = pc + 32'd4;
        if (opcode == 7'b1101111)          // JAL
            next_pc = pc + imm_j;
        else if (opcode == 7'b1100111)     // JALR
            next_pc = (read_data1 + imm_i) & ~32'd1;
        else if (opcode == 7'b1100011)     // branches
            if (take_branch) next_pc = pc + imm_b;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'h0;
        else
            pc <= next_pc;
    end

    // --------------------
    // data memory
    // --------------------
    data_memory dmem (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .addr(alu_result),
        .write_data(read_data2),
        .read_data(mem_read_data)
    );

    // writeback
    always_comb begin
        if (opcode == 7'b1101111 || opcode == 7'b1100111)
            write_data = pc + 32'd4;
        else if (mem_to_reg)
            write_data = mem_read_data;
        else
            write_data = alu_result;
    end

    // --------------------
    // 6 displays (same as you had) - show 6 hex digits chosen by SW[1:0], SW[0] picks high/low 6 nibbles
    // --------------------
    logic [23:0] disp_val;
    always_comb begin
        logic [31:0] sel32;
        case (SW[1:0])
            2'b00: sel32 = instr;
            2'b01: sel32 = instr;
            2'b10: sel32 = read_data1;
            2'b11: sel32 = read_data2;
            default: sel32 = 32'h0;
        endcase

        if (SW[0] == 1'b0)
            disp_val = sel32[23:0];
        else
            disp_val = sel32[31:8];
    end

    hex7seg h0 (.val(disp_val[3:0]),   .display(display));
    hex7seg h1 (.val(disp_val[7:4]),   .display(display1));
    hex7seg h2 (.val(disp_val[11:8]),  .display(display2));
    hex7seg h3 (.val(disp_val[15:12]), .display(display3));
    hex7seg h4 (.val(disp_val[19:16]), .display(display4));
    hex7seg h5 (.val(disp_val[23:20]), .display(display5));

    assign LEDR = pc[11:2];

    // =========================
    // VGA / renderer integration
    // =========================

    // create VGA clock (uses your pll wrapper).  
    // The project you showed contains module 'clock1280x800' wrapper that outputs vgaclk.
    // If you have different name for wrapper, change below to match yours.
    wire vgaclk;
    wire pll_reset_n;
    // Use your existing PLL wrapper (example name used earlier: clock1280x800)
    clock1280x800 clkgen (
        .clock50(clk),
        .reset(~rst_n),
        .vgaclk(vgaclk)
    );

    assign vga_clock = vgaclk;

    // vga timing controller (your vga_controller_1280x800 from example)
    wire [10:0] hcount;
    wire [9:0]  vcount;
    wire videoOn;

    vga_controller_1280x800 vga_ctl (
        .clk(vgaclk),
        .reset(~rst_n),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .hcount(hcount),
        .vcount(vcount),
        .video_on(videoOn)
    );

    // renderer: draws ASCII boxes + values coming from CPU
    riscv_vga_renderer renderer (
        .vgaclk(vgaclk),
        .reset_n(rst_n),
        .hcount(hcount),
        .vcount(vcount),
        .video_on(videoOn),
        // CPU debug signals
        .pc(pc),
        .instr(instr),
        .rs1_data(read_data1),
        .rs2_data(read_data2),
        .alu_result(alu_result),
        // VGA color outputs (8-bit per channel)
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

endmodule
