// rtl/core/writeback.v

module writeback (
    // Inputs from MEM/WB register
    input  [31:0] wb_alu_result,
    input  [31:0] wb_read_data,
    input  [31:0] wb_mul_div_result,  // M-extension result
    input  [4:0]  wb_rd,
    input         wb_reg_write,
    input         wb_mem_to_reg,
    input         wb_is_mul_div,      // M-extension flag
    // Outputs back to decode (register file write port)
    output [31:0] wb_data,
    output [4:0]  rd_out,
    output        reg_write_out
);
    // Priority: mul/div result > memory read data > ALU result
    assign wb_data = wb_is_mul_div ? wb_mul_div_result :
                     wb_mem_to_reg ? wb_read_data       :
                                     wb_alu_result;

    assign rd_out        = wb_rd;
    assign reg_write_out = wb_reg_write;
endmodule