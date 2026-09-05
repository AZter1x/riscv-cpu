module dmem (
    input        clk,
    input        we,
    input  [31:0] addr, wdata,
    output [31:0] rdata
);
    reg [31:0] mem [0:255];
    assign rdata = mem[addr[9:2]];
    always @(posedge clk)
        if (we) mem[addr[9:2]] <= wdata;
endmodule