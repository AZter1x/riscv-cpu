// rtl/mem/imem.v
module imem (
    input  [31:0] addr,
    output [31:0] instr
);
    reg [7:0] mem [0:1023];  // byte-addressed, 1KB
    initial $readmemh("prog/test.hex", mem);

    // Reconstruct 32-bit little-endian word from 4 bytes
    wire [9:0] base = {addr[9:2], 2'b00};
    assign instr = {mem[base+3], mem[base+2], mem[base+1], mem[base]};
endmodule
