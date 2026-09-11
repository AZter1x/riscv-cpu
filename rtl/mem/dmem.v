// RISC V _ CPU/rtl/mem/dmem.v

module dmem (
    input        clk,
    input  [3:0] we,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata
);
    reg [31:0] mem [0:4095]; // 16KB

    assign rdata = mem[addr[13:2]];

    always @(posedge clk) begin
        if (we[0]) mem[addr[13:2]][7:0]   <= wdata[7:0];
        if (we[1]) mem[addr[13:2]][15:8]  <= wdata[15:8];
        if (we[2]) mem[addr[13:2]][23:16] <= wdata[23:16];
        if (we[3]) mem[addr[13:2]][31:24] <= wdata[31:24];
    end
endmodule