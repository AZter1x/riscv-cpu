// rtl/core/writeback.v

module writeback (
    // Inputs from MEM/WB register
    input  [31:0] wb_alu_result,
    input  [31:0] wb_read_data,
    input  [4:0]  wb_rd,
    input         wb_reg_write,
    input         wb_mem_to_reg,
    // Outputs back to decode (register file write port)
    output [31:0] wb_data,
    output [4:0]  rd_out,
    output        reg_write_out
);
    assign wb_data      = wb_mem_to_reg ? wb_read_data : wb_alu_result;
    assign rd_out       = wb_rd;
    assign reg_write_out = wb_reg_write;
endmodule
