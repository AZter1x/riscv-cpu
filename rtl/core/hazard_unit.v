// rtl/core/hazard_unit.v

module hazard_unit (
    input        id_ex_mem_read,
    input  [4:0] id_ex_rd,
    input  [4:0] if_id_rs1, if_id_rs2,
    output       stall,
    output       flush_id_ex
);
    // Load-use hazard: stall one cycle
    assign stall      = id_ex_mem_read &&
                        ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));
    assign flush_id_ex = stall;
endmodule