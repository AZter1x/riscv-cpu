// rtl/core/decode.v

module regfile (
    input        clk,
    input        we,
    input  [4:0] rs1, rs2, rd,
    input  [31:0] wdata,
    output [31:0] rdata1, rdata2
);
    reg [31:0] regs [0:31];
    assign rdata1 = (rs1 == 0) ? 32'd0 : regs[rs1];
    assign rdata2 = (rs2 == 0) ? 32'd0 : regs[rs2];
    always @(posedge clk)
        if (we && rd != 0) regs[rd] <= wdata;
endmodule


module control (
    input  [6:0] opcode,
    output reg reg_write, mem_read, mem_write,
    output reg branch, alu_src, mem_to_reg,
    output reg [1:0] alu_op
);
    always @(*) begin
        {reg_write, mem_read, mem_write, branch, alu_src, mem_to_reg} = 6'b0;
        alu_op = 2'b00;
        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1; alu_op = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                reg_write = 1; alu_src = 1; alu_op = 2'b10;
            end
            7'b0000011: begin // LOAD
                reg_write = 1; mem_read = 1; alu_src = 1; mem_to_reg = 1;
            end
            7'b0100011: begin // STORE
                mem_write = 1; alu_src = 1;
            end
            7'b1100011: begin // BRANCH
                branch = 1; alu_op = 2'b01;
            end
            7'b0110111: begin // LUI
                reg_write = 1; alu_src = 1; alu_op = 2'b11;
            end
            7'b1101111: begin // JAL
                reg_write = 1; branch = 1;
            end
            7'b1100111: begin // JALR
                reg_write = 1; alu_src = 1; alu_op = 2'b00;
            end
            7'b0010111: begin // AUIPC
                reg_write = 1; alu_src = 1; alu_op = 2'b00;
            end
        endcase
    end
endmodule


module imm_gen (
    input  [31:0] instr,
    output reg [31:0] imm
);
    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011,
            7'b0000011,
            7'b1100111:
                imm = {{20{instr[31]}}, instr[31:20]};

            7'b0100011:
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            7'b1100011:
                imm = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};

            7'b0110111,
            7'b0010111:
                imm = {instr[31:12], 12'b0};

            7'b1101111:
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                       instr[20], instr[30:21], 1'b0};

            default: imm = 32'd0;
        endcase
    end
endmodule


module decode (
    input        clk,
    input  [31:0] instr,
    // Writeback inputs
    input        reg_write,
    input  [4:0] wb_rd,
    input  [31:0] wb_data,
    // Decoded register outputs
    output [31:0] rdata1, rdata2, imm,
    // Instruction fields
    output [4:0]  rs1, rs2, rd,
    output [2:0]  funct3,
    output        funct7_5,
    output [6:0]  opcode,
    // Control signals
    output        reg_write_out, mem_read, mem_write,
    output        branch, alu_src, mem_to_reg,
    output [1:0]  alu_op
);
    assign rs1      = instr[19:15];
    assign rs2      = instr[24:20];
    assign rd       = instr[11:7];
    assign funct3   = instr[14:12];
    assign funct7_5 = instr[30];
    assign opcode   = instr[6:0];

    regfile rf (
        .clk(clk),
        .we(reg_write),
        .rs1(rs1), .rs2(rs2), .rd(wb_rd),
        .wdata(wb_data),
        .rdata1(rdata1), .rdata2(rdata2)
    );

    control ctrl (
        .opcode(instr[6:0]),
        .reg_write(reg_write_out),
        .mem_read(mem_read), .mem_write(mem_write),
        .branch(branch), .alu_src(alu_src),
        .mem_to_reg(mem_to_reg), .alu_op(alu_op)
    );

    imm_gen ig (
        .instr(instr),
        .imm(imm)
    );
endmodule