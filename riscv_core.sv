// riscv_core.sv
// Single-cycle educational wrapper. Usa:
 // instruction_memory.sv, registers_unit.sv, alu_control.sv, alu.sv, data_memory.sv
module riscv_core (
    input  logic       clk,
    input  logic       rst_n,
    output logic [31:0] pc_out,
    output logic [31:0] instr_out,
    output logic [31:0] rd1_out,
    output logic [31:0] rd2_out,
    output logic [1023:0] regs_flat_out,
    output logic [255:0] mem_sample_out
);

    // Program counter
    logic [31:0] pc;
    logic [31:0] next_pc;

    // Instr memory
    logic [31:0] instr;

    // register file interface
    logic [4:0] rs1, rs2, rd;
    logic [31:0] write_data;
    logic reg_write;
    logic [31:0] read_data1, read_data2;
    logic [1023:0] regs_flat;

    // ALU
    logic [31:0] alu_a, alu_b, alu_result;
    logic [3:0] alu_ctrl;

    // Data mem
    logic mem_write, mem_read;
    logic [31:0] mem_read_data;

    // Fetch: PC increment simple
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'b0;
        end else begin
            pc <= pc + 4;
        end
    end
    assign pc_out = pc;

    // Instruction memory (byte addr). instruction_memory uses addr[9:2] indexing.
    instruction_memory imem (
        .addr(pc),
        .instr(instr)
    );

    // decode fields
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];

    // For now single-cycle R-type support: take rs1, rs2 from reg file, ALU compute, no writes to mem.
    // registers_unit supports reg_write and outputs regs_flat for debugging.
    registers_unit regs (
        .clk(clk),
        .rst_n(rst_n),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .reg_write(reg_write),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .regs_flat_out(regs_flat)
    );

    // Simple ALU control: map opcode/funct3/funct7 -> alu_ctrl
    alu_control actrl (
        .opcode(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7(instr[31:25]),
        .alu_op(alu_ctrl)
    );

    // Connect ALU
    assign alu_a = read_data1;
    assign alu_b = read_data2;

    alu alu_unit (
        .a(alu_a),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result)
    );

    // For this demo core: we do not perform any writes (reg_write=0) except optionally write ALU result to rd for R-type
    // Detect R-type opcode 0110011 -> write result back
    always_comb begin
        reg_write = 1'b0;
        write_data = 32'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        // opcode R-type
        if (instr[6:0] == 7'b0110011) begin
            reg_write = 1'b1;
            write_data = alu_result;
        end
        // for other opcodes you'd handle I-type, loads/stores etc.
    end

    // Data memory (unused for now but instantiated)
    data_memory dmem (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .addr(alu_result),
        .write_data(read_data2),
        .read_data(mem_read_data)
    );

    // Output debug signals
    assign instr_out = instr;
    assign rd1_out = read_data1;
    assign rd2_out = read_data2;
    assign regs_flat_out = regs_flat;

    // Provide a mem_sample (first 8 words) for debug display
    // dmem.mem is internal; instead we return zeros here or you can modify data_memory to provide sample bus.
    assign mem_sample_out = 256'h0; // placeholder, you can extend data_memory to export sample bytes

endmodule
