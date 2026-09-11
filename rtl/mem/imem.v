// RISC V _ CPU/rtl/mem/imem.v

module imem (
    // Port A: Instruction Fetch
    input  [31:0] addr,
    output [31:0] instr,
    // Port B: Data Read (.rodata / constants)
    input  [31:0] data_addr,
    output [31:0] data_rdata
);
    reg [7:0] mem [0:16383];  // 16KB instruction memory
    initial $readmemh("prog/test.hex", mem);

    wire [13:0] base_instr = {addr[13:2], 2'b00};
    assign instr = {mem[base_instr+3], mem[base_instr+2], mem[base_instr+1], mem[base_instr]};

    wire [13:0] base_data = {data_addr[13:2], 2'b00};
    assign data_rdata = {mem[base_data+3], mem[base_data+2], mem[base_data+1], mem[base_data]};
endmodule