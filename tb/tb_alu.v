`timescale 1ns/1ps
module tb_alu;
    reg  [31:0] a, b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    alu dut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .zero(zero));

    initial begin
        $dumpfile("sim/alu.vcd");
        $dumpvars(0, tb_alu);

        // ADD test
        a = 32'd10; b = 32'd5; alu_ctrl = 4'b0000; #10;
        $display("ADD: %0d + %0d = %0d (expect 15)", a, b, result);

        // SUB test
        a = 32'd10; b = 32'd10; alu_ctrl = 4'b0001; #10;
        $display("SUB: %0d - %0d = %0d, zero=%b (expect 0,1)", a, b, result, zero);

        // SLT test
        a = -32'd1; b = 32'd1; alu_ctrl = 4'b1000; #10;
        $display("SLT signed: result=%0d (expect 1)", result);

        $finish;
    end
endmodule