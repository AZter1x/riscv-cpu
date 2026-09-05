// rtl/core/top.v

module top (
    input clk, rst
);
    // ── IF stage wires ─────────────────────────────────
    wire [31:0] if_pc, if_instr, if_pc_plus4;

    // ── IF/ID register outputs ──────────────────────────
    wire [31:0] id_pc, id_instr;

    // ── ID stage wires ──────────────────────────────────
    wire [31:0] id_rdata1, id_rdata2, id_imm;
    wire [4:0]  id_rs1, id_rs2, id_rd;
    wire [2:0]  id_funct3;
    wire        id_funct7_5;
    wire [6:0]  id_opcode;                                   // ← ADDED
    wire        id_reg_write, id_mem_read, id_mem_write;
    wire        id_branch, id_alu_src, id_mem_to_reg;
    wire [1:0]  id_alu_op;

    // ── ID/EX register outputs ──────────────────────────
    wire [31:0] ex_pc, ex_rdata1, ex_rdata2, ex_imm;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;
    wire [2:0]  ex_funct3;
    wire        ex_funct7_5;
    wire [6:0]  ex_opcode;                                   // ← ADDED
    wire        ex_reg_write, ex_mem_read, ex_mem_write;
    wire        ex_branch, ex_alu_src, ex_mem_to_reg;
    wire [1:0]  ex_alu_op;

    // ── EX stage wires ───────────────────────────────────
    wire [31:0] ex_alu_result, ex_branch_target, ex_rdata2_fwd;
    wire        ex_branch_taken;
    wire        ex_jalr_taken;                               // ← ADDED
    wire [31:0] ex_jalr_target;                              // ← ADDED

    // ── EX/MEM register outputs ──────────────────────────
    wire [31:0] mem_branch_target, mem_alu_result, mem_rdata2;
    wire [4:0]  mem_rd;
    wire        mem_branch_taken;
    wire        mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg;

    // ── MEM stage wires ──────────────────────────────────
    wire [31:0] mem_alu_result_out, mem_read_data;
    wire [4:0]  mem_rd_out;
    wire        mem_reg_write_out, mem_mem_to_reg_out;

    // ── MEM/WB register outputs ──────────────────────────
    wire [31:0] wb_alu_result, wb_read_data;
    wire [4:0]  wb_rd;
    wire        wb_reg_write, wb_mem_to_reg;

    // ── WB stage wires ───────────────────────────────────
    wire [31:0] wb_data;
    wire [4:0]  wb_rd_out;
    wire        wb_reg_write_out;

    // ── Hazard and forwarding wires ──────────────────────
    wire        stall, flush_id_ex;
    wire [1:0]  forward_a, forward_b;
    wire        flush_if_id = mem_branch_taken | ex_jalr_taken; // ← UPDATED

    // ── Stage Instantiations ─────────────────────────────

    fetch fetch_stage (
        .clk          (clk),
        .rst          (rst),
        .stall        (stall),
        .branch_taken (mem_branch_taken),
        .branch_target(mem_branch_target),
        .jalr_taken   (ex_jalr_taken),                       // ← ADDED
        .jalr_target  (ex_jalr_target),                      // ← ADDED
        .pc           (if_pc),
        .instr        (if_instr),
        .pc_plus4     (if_pc_plus4)
    );

    if_id_reg if_id (
        .clk      (clk), .rst   (rst),
        .flush    (flush_if_id), .stall(stall),
        .if_pc    (if_pc),       .if_instr(if_instr),
        .id_pc    (id_pc),       .id_instr(id_instr)
    );

    decode decode_stage (
        .clk          (clk),
        .instr        (id_instr),
        .reg_write    (wb_reg_write_out),
        .wb_rd        (wb_rd_out),
        .wb_data      (wb_data),
        .rdata1       (id_rdata1), .rdata2(id_rdata2), .imm(id_imm),
        .rs1          (id_rs1),    .rs2   (id_rs2),    .rd (id_rd),
        .funct3       (id_funct3), .funct7_5(id_funct7_5),
        .opcode       (id_opcode),                           // ← ADDED
        .reg_write_out(id_reg_write), .mem_read (id_mem_read),
        .mem_write    (id_mem_write), .branch   (id_branch),
        .alu_src      (id_alu_src),   .mem_to_reg(id_mem_to_reg),
        .alu_op       (id_alu_op)
    );

    id_ex_reg id_ex (
        .clk(clk), .rst(rst), .flush(flush_id_ex),
        .id_pc       (id_pc),       .id_rdata1(id_rdata1),
        .id_rdata2   (id_rdata2),   .id_imm   (id_imm),
        .id_rs1      (id_rs1),      .id_rs2   (id_rs2),   .id_rd(id_rd),
        .id_funct3   (id_funct3),   .id_funct7_5(id_funct7_5),
        .id_opcode   (id_opcode),                           // ← ADDED
        .id_reg_write(id_reg_write), .id_mem_read (id_mem_read),
        .id_mem_write(id_mem_write), .id_branch   (id_branch),
        .id_alu_src  (id_alu_src),   .id_mem_to_reg(id_mem_to_reg),
        .id_alu_op   (id_alu_op),
        .ex_pc       (ex_pc),       .ex_rdata1(ex_rdata1),
        .ex_rdata2   (ex_rdata2),   .ex_imm   (ex_imm),
        .ex_rs1      (ex_rs1),      .ex_rs2   (ex_rs2),   .ex_rd(ex_rd),
        .ex_funct3   (ex_funct3),   .ex_funct7_5(ex_funct7_5),
        .ex_opcode   (ex_opcode),                           // ← ADDED
        .ex_reg_write(ex_reg_write), .ex_mem_read (ex_mem_read),
        .ex_mem_write(ex_mem_write), .ex_branch   (ex_branch),
        .ex_alu_src  (ex_alu_src),   .ex_mem_to_reg(ex_mem_to_reg),
        .ex_alu_op   (ex_alu_op)
    );

    execute execute_stage (
        .ex_pc            (ex_pc),
        .ex_rdata1        (ex_rdata1),  .ex_rdata2    (ex_rdata2),
        .ex_imm           (ex_imm),     .ex_rs1       (ex_rs1),
        .ex_rs2           (ex_rs2),     .ex_rd        (ex_rd),
        .ex_funct3        (ex_funct3),  .ex_funct7_5  (ex_funct7_5),
        .ex_opcode        (ex_opcode),                      // ← ADDED
        .ex_alu_src       (ex_alu_src), .ex_branch    (ex_branch),
        .ex_alu_op        (ex_alu_op),
        .ex_mem_alu_result(mem_alu_result),
        .wb_data          (wb_data),
        .forward_a        (forward_a),  .forward_b    (forward_b),
        .alu_result       (ex_alu_result),
        .branch_target    (ex_branch_target),
        .branch_taken     (ex_branch_taken),
        .rdata2_out       (ex_rdata2_fwd),
        .jalr_taken       (ex_jalr_taken),                  // ← ADDED
        .jalr_target      (ex_jalr_target)                  // ← ADDED
    );

    ex_mem_reg ex_mem (
        .clk(clk), .rst(rst),
        .ex_branch_target(ex_branch_target), .ex_alu_result(ex_alu_result),
        .ex_rdata2       (ex_rdata2_fwd),    .ex_rd        (ex_rd),
        .ex_branch_taken (ex_branch_taken),
        .ex_reg_write    (ex_reg_write),  .ex_mem_read  (ex_mem_read),
        .ex_mem_write    (ex_mem_write),  .ex_mem_to_reg(ex_mem_to_reg),
        .mem_branch_target(mem_branch_target), .mem_alu_result(mem_alu_result),
        .mem_rdata2      (mem_rdata2),    .mem_rd       (mem_rd),
        .mem_branch_taken(mem_branch_taken),
        .mem_reg_write   (mem_reg_write), .mem_mem_read (mem_mem_read),
        .mem_mem_write   (mem_mem_write), .mem_mem_to_reg(mem_mem_to_reg)
    );

    memory memory_stage (
        .clk           (clk),
        .mem_alu_result(mem_alu_result),
        .mem_rdata2    (mem_rdata2),
        .mem_rd        (mem_rd),
        .mem_mem_read  (mem_mem_read),
        .mem_mem_write (mem_mem_write),
        .mem_reg_write (mem_reg_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .alu_result_out(mem_alu_result_out),
        .read_data     (mem_read_data),
        .rd_out        (mem_rd_out),
        .reg_write_out (mem_reg_write_out),
        .mem_to_reg_out(mem_mem_to_reg_out)
    );

    mem_wb_reg mem_wb (
        .clk(clk), .rst(rst),
        .mem_alu_result(mem_alu_result_out),
        .mem_rdata     (mem_read_data),
        .mem_rd        (mem_rd_out),
        .mem_reg_write (mem_reg_write_out),
        .mem_mem_to_reg(mem_mem_to_reg_out),
        .wb_alu_result (wb_alu_result),
        .wb_rdata      (wb_read_data),
        .wb_rd         (wb_rd),
        .wb_reg_write  (wb_reg_write),
        .wb_mem_to_reg (wb_mem_to_reg)
    );

    writeback writeback_stage (
        .wb_alu_result (wb_alu_result),
        .wb_read_data  (wb_read_data),
        .wb_rd         (wb_rd),
        .wb_reg_write  (wb_reg_write),
        .wb_mem_to_reg (wb_mem_to_reg),
        .wb_data       (wb_data),
        .rd_out        (wb_rd_out),
        .reg_write_out (wb_reg_write_out)
    );

    hazard_unit hazard (
        .id_ex_mem_read(ex_mem_read),
        .id_ex_rd      (ex_rd),
        .if_id_rs1     (id_rs1), .if_id_rs2(id_rs2),
        .stall         (stall),  .flush_id_ex(flush_id_ex)
    );

    forwarding_unit fwd (
        .id_ex_rs1       (ex_rs1),        .id_ex_rs2       (ex_rs2),
        .ex_mem_rd       (mem_rd),         .mem_wb_rd       (wb_rd),
        .ex_mem_reg_write(mem_reg_write),  .mem_wb_reg_write(wb_reg_write),
        .forward_a       (forward_a),      .forward_b       (forward_b)
    );

endmodule