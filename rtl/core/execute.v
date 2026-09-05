// rtl/core/execute.v

module execute (
    // Inputs from ID/EX register
    input  [31:0] ex_pc, ex_rdata1, ex_rdata2, ex_imm,
    input  [4:0]  ex_rs1, ex_rs2, ex_rd,
    input  [2:0]  ex_funct3,
    input         ex_funct7_5,
    input         ex_alu_src, ex_branch,
    input  [1:0]  ex_alu_op,
    input  [6:0]  ex_opcode,
    // Forwarding inputs
    input  [31:0] ex_mem_alu_result,
    input  [31:0] wb_data,
    input  [1:0]  forward_a, forward_b,
    // Outputs
    output [31:0] alu_result,
    output [31:0] branch_target,
    output        branch_taken,
    output [31:0] rdata2_out,
    output        jalr_taken,
    output [31:0] jalr_target
);
    wire [3:0] alu_ctrl;
    wire       alu_zero;
    reg  [31:0] alu_in_a, forwarded_b;

    // AUIPC and JALR opcode detection
    wire auipc = (ex_opcode == 7'b0010111);
    wire jalr  = (ex_opcode == 7'b1100111);

    // 3-way forwarding mux -- input A
    // AUIPC uses PC as input A instead of rs1
    always @(*) begin
        case (forward_a)
            2'b00: alu_in_a = auipc ? ex_pc : ex_rdata1;
            2'b10: alu_in_a = ex_mem_alu_result;
            2'b01: alu_in_a = wb_data;
            default: alu_in_a = ex_rdata1;
        endcase
    end

    // 3-way forwarding mux -- input B
    always @(*) begin
        case (forward_b)
            2'b00: forwarded_b = ex_rdata2;
            2'b10: forwarded_b = ex_mem_alu_result;
            2'b01: forwarded_b = wb_data;
            default: forwarded_b = ex_rdata2;
        endcase
    end

    // alu_src mux -- pick immediate or forwarded rs2
    wire [31:0] alu_in_b = ex_alu_src ? ex_imm : forwarded_b;

    // rdata2_out carries the forwarded rs2 to EX/MEM (used by SW)
    assign rdata2_out = forwarded_b;

    // Branch target and taken
    assign branch_target = ex_pc + ex_imm;

    reg branch_condition;
    always @(*) begin
        case (ex_funct3)
            3'b000: branch_condition = alu_zero;
            3'b001: branch_condition = ~alu_zero;
            3'b100: branch_condition = alu_result[31];
            3'b101: branch_condition = ~alu_result[31] | alu_zero;
            3'b110: branch_condition = alu_result[31];
            3'b111: branch_condition = ~alu_result[31] | alu_zero;
            default: branch_condition = 1'b0;
        endcase
    end

    assign branch_taken = ex_branch & branch_condition;

    // JALR target -- rs1 + imm, LSB forced to 0 per RISC-V spec
    assign jalr_taken  = jalr;
    assign jalr_target = (alu_in_a + ex_imm) & 32'hFFFFFFFE;

    alu_control alu_ctrl_unit (
        .alu_op(ex_alu_op),
        .funct3(ex_funct3),
        .funct7_5(ex_funct7_5),
        .alu_ctrl(alu_ctrl)
    );

    alu alu_unit (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(alu_zero)
    );
endmodule