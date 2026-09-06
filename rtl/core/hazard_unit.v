// rtl/core/hazard_unit.v

module hazard_unit (
    input        id_ex_mem_read,
    input        mul_div_stall,   // stall from mul/div unit
    input  [4:0] id_ex_rd,
    input  [4:0] if_id_rs1, if_id_rs2,
    output       stall,
    output       flush_id_ex
);
    // Load-use hazard: stall one cycle
    wire load_use_stall = id_ex_mem_read &&
                          ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

    // Stall for either load-use hazard or mul/div in progress
    assign stall       = load_use_stall | mul_div_stall;

    // Only flush ID/EX on load-use stall, not on mul/div stall
    // During mul/div stall the ID/EX register must hold the
    // mul/div instruction steady until the unit finishes
    assign flush_id_ex = load_use_stall;
endmodule