// RISC V _ CPU/rtl/core/fetch.v

module fetch (
    input        clk, rst, stall,
    input        branch_taken,
    input  [31:0] branch_target,
    input        jalr_taken,
    input  [31:0] jalr_target,
    // Port B forwarded from memory stage for rodata / constants
    input  [31:0] data_addr,
    output [31:0] data_rdata,
    output reg [31:0] pc,
    output [31:0] instr, pc_plus4
);
    wire [31:0] next_pc;
    assign pc_plus4 = pc + 4;

    // JALR takes highest priority, then branch, then normal increment
    assign next_pc = jalr_taken   ? jalr_target  :
                     branch_taken ? branch_target :
                     pc_plus4;

    always @(posedge clk or posedge rst)
        if (rst)         pc <= 32'h0000_0000;
        else if (!stall) pc <= next_pc;

    imem imem0 (
        .addr      (pc),
        .instr     (instr),
        .data_addr (data_addr),
        .data_rdata(data_rdata)
    );
endmodule