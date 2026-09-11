// tb/tb_top.v
`timescale 1ns/1ps

module tb_top;

    reg clk, rst;
    wire uart_valid;
    wire [7:0] uart_data;

    top dut (
        .clk       (clk),
        .rst       (rst),
        .uart_valid(uart_valid),
        .uart_data (uart_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/cpu.vcd");
        $dumpvars(0, tb_top);
        rst = 1; #20;
        rst = 0;
        #500000;
        $display("\nSimulation timeout.");
        $finish;
    end

    // Print UART output as characters
    always @(posedge clk) begin
        if (uart_valid)
            $write("%c", uart_data);
    end

    // Finish after newline received
    always @(posedge clk) begin
        if (uart_valid && uart_data == 8'h0A) begin
            #100;
            $finish;
        end
    end

endmodule