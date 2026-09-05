// rtl/core/memory.v

module memory (
    input        clk,
    // Inputs from EX/MEM register
    input  [31:0] mem_alu_result,
    input  [31:0] mem_rdata2,
    input  [4:0]  mem_rd,
    input         mem_mem_read,
    input         mem_mem_write,
    input         mem_reg_write,
    input         mem_mem_to_reg,
    // Output to MEM/WB register
    output [31:0] alu_result_out,
    output [31:0] read_data,
    output [4:0]  rd_out,
    output        reg_write_out,
    output        mem_to_reg_out
);
    dmem dmem_inst (
        .clk   (clk),
        .we    (mem_mem_write),
        .addr  (mem_alu_result),
        .wdata (mem_rdata2),
        .rdata (read_data)
    );

    // Pass-through signals to MEM/WB
    assign alu_result_out = mem_alu_result;
    assign rd_out         = mem_rd;
    assign reg_write_out  = mem_reg_write;
    assign mem_to_reg_out = mem_mem_to_reg;
endmodule