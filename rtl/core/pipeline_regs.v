// rtl/core/pipeline_regs.v

// --- IF/ID Register -----------------------------------------------------------
module if_id_reg (
    input        clk, rst,
    input        flush, stall,
    input  [31:0] if_pc, if_instr,
    output reg [31:0] id_pc, id_instr
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            id_pc    <= 32'd0;
            id_instr <= 32'h00000013; // NOP: addi x0, x0, 0
        end else if (!stall) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
        end
    end
endmodule

// --- ID/EX Register -----------------------------------------------------------
module id_ex_reg (
    input        clk, rst,
    input        flush,
    // Data inputs
    input  [31:0] id_pc, id_rdata1, id_rdata2, id_imm,
    input  [4:0]  id_rs1, id_rs2, id_rd,
    input  [2:0]  id_funct3,
    input         id_funct7_5,
    input         id_funct7_1,        // M-extension flag
    input  [6:0]  id_opcode,
    // Control inputs
    input         id_reg_write, id_mem_read, id_mem_write,
    input         id_branch, id_alu_src, id_mem_to_reg,
    input  [1:0]  id_alu_op,
    // Data outputs
    output reg [31:0] ex_pc, ex_rdata1, ex_rdata2, ex_imm,
    output reg [4:0]  ex_rs1, ex_rs2, ex_rd,
    output reg [2:0]  ex_funct3,
    output reg        ex_funct7_5,
    output reg        ex_funct7_1,    // M-extension flag
    output reg [6:0]  ex_opcode,
    // Control outputs
    output reg        ex_reg_write, ex_mem_read, ex_mem_write,
    output reg        ex_branch, ex_alu_src, ex_mem_to_reg,
    output reg [1:0]  ex_alu_op
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            ex_pc        <= 32'd0;
            ex_rdata1    <= 32'd0; ex_rdata2   <= 32'd0; ex_imm <= 32'd0;
            ex_rs1       <= 5'd0;  ex_rs2      <= 5'd0;  ex_rd  <= 5'd0;
            ex_funct3    <= 3'd0;  ex_funct7_5 <= 1'd0;
            ex_funct7_1  <= 1'd0;                        // M-extension flag
            ex_opcode    <= 7'b0110011;
            ex_reg_write <= 0; ex_mem_read  <= 0; ex_mem_write <= 0;
            ex_branch    <= 0; ex_alu_src   <= 0; ex_mem_to_reg <= 0;
            ex_alu_op    <= 2'd0;
        end else begin
            ex_pc        <= id_pc;
            ex_rdata1    <= id_rdata1; ex_rdata2  <= id_rdata2; ex_imm <= id_imm;
            ex_rs1       <= id_rs1;    ex_rs2     <= id_rs2;    ex_rd  <= id_rd;
            ex_funct3    <= id_funct3; ex_funct7_5 <= id_funct7_5;
            ex_funct7_1  <= id_funct7_1;                 // M-extension flag
            ex_opcode    <= id_opcode;
            ex_reg_write <= id_reg_write; ex_mem_read  <= id_mem_read;
            ex_mem_write <= id_mem_write; ex_branch    <= id_branch;
            ex_alu_src   <= id_alu_src;   ex_mem_to_reg <= id_mem_to_reg;
            ex_alu_op    <= id_alu_op;
        end
    end
endmodule

// --- EX/MEM Register ----------------------------------------------------------
module ex_mem_reg (
    input        clk, rst,
    // Data inputs
    input  [31:0] ex_branch_target, ex_alu_result, ex_rdata2,
    input  [31:0] ex_mul_div_result, // M-extension result
    input  [4:0]  ex_rd,
    input         ex_branch_taken,
    // Control inputs
    input         ex_reg_write, ex_mem_read, ex_mem_write, ex_mem_to_reg,
    input         ex_is_mul_div,     // M-extension flag
    // Data outputs
    output reg [31:0] mem_branch_target, mem_alu_result, mem_rdata2,
    output reg [31:0] mem_mul_div_result, // M-extension result
    output reg [4:0]  mem_rd,
    output reg        mem_branch_taken,
    // Control outputs
    output reg        mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg,
    output reg        mem_is_mul_div  // M-extension flag
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_branch_target  <= 32'd0; mem_alu_result <= 32'd0;
            mem_rdata2         <= 32'd0; mem_rd         <= 5'd0;
            mem_branch_taken   <= 1'd0;
            mem_mul_div_result <= 32'd0;
            mem_reg_write  <= 0; mem_mem_read   <= 0;
            mem_mem_write  <= 0; mem_mem_to_reg <= 0;
            mem_is_mul_div <= 0;
        end else begin
            mem_branch_target  <= ex_branch_target;
            mem_alu_result     <= ex_alu_result;
            mem_rdata2         <= ex_rdata2;
            mem_rd             <= ex_rd;
            mem_branch_taken   <= ex_branch_taken;
            mem_mul_div_result <= ex_mul_div_result;
            mem_reg_write      <= ex_reg_write;
            mem_mem_read       <= ex_mem_read;
            mem_mem_write      <= ex_mem_write;
            mem_mem_to_reg     <= ex_mem_to_reg;
            mem_is_mul_div     <= ex_is_mul_div;
        end
    end
endmodule

// --- MEM/WB Register ----------------------------------------------------------
module mem_wb_reg (
    input        clk, rst,
    // Data inputs
    input  [31:0] mem_alu_result, mem_rdata,
    input  [31:0] mem_mul_div_result, // M-extension result
    input  [4:0]  mem_rd,
    // Control inputs
    input         mem_reg_write, mem_mem_to_reg,
    input         mem_is_mul_div,     // M-extension flag
    // Data outputs
    output reg [31:0] wb_alu_result, wb_rdata,
    output reg [31:0] wb_mul_div_result, // M-extension result
    output reg [4:0]  wb_rd,
    // Control outputs
    output reg        wb_reg_write, wb_mem_to_reg,
    output reg        wb_is_mul_div   // M-extension flag
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_alu_result     <= 32'd0; wb_rdata <= 32'd0;
            wb_mul_div_result <= 32'd0;
            wb_rd             <= 5'd0;
            wb_reg_write      <= 0; wb_mem_to_reg <= 0;
            wb_is_mul_div     <= 0;
        end else begin
            wb_alu_result     <= mem_alu_result;
            wb_rdata          <= mem_rdata;
            wb_mul_div_result <= mem_mul_div_result;
            wb_rd             <= mem_rd;
            wb_reg_write      <= mem_reg_write;
            wb_mem_to_reg     <= mem_mem_to_reg;
            wb_is_mul_div     <= mem_is_mul_div;
        end
    end
endmodule