// tb/tb_top.v
`timescale 1ns/1ps

module tb_top;

    // ── DUT signals ──────────────────────────────────────────
    reg clk, rst;

    // ── Instantiate DUT ──────────────────────────────────────
    top dut (
        .clk(clk),
        .rst(rst)
    );

    // ── Clock: 10ns period ───────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Reset then run ───────────────────────────────────────
    initial begin
        $dumpfile("sim/cpu.vcd");
        $dumpvars(0, tb_top);

        rst = 1;
        #20;
        rst = 0;

        // Run for enough cycles to execute the full test program
        #2000;
        $display("Simulation complete.");
        $finish;
    end

    // ── Cycle counter ────────────────────────────────────────
    integer cycle = 0;
    always @(posedge clk) cycle = cycle + 1;

    // ── Per-cycle monitor ────────────────────────────────────
    always @(posedge clk) begin
        if (!rst) begin
            $display("────────────────────────────────────────────────────────");
            $display("Cycle %0d | t=%0t ns", cycle, $time);

            // IF stage
            $display("  [IF]  PC       = 0x%08h", dut.if_pc);
            $display("  [IF]  INSTR    = 0x%08h", dut.if_instr);

            // ID stage
            $display("  [ID]  PC       = 0x%08h", dut.id_pc);
            $display("  [ID]  INSTR    = 0x%08h", dut.id_instr);
            $display("  [ID]  rs1=%0d  rs2=%0d  rd=%0d",
                        dut.id_rs1, dut.id_rs2, dut.id_rd);
            $display("  [ID]  rdata1   = 0x%08h", dut.id_rdata1);
            $display("  [ID]  rdata2   = 0x%08h", dut.id_rdata2);
            $display("  [ID]  imm      = 0x%08h", dut.id_imm);

            // EX stage
            $display("  [EX]  ALU_result = 0x%08h", dut.ex_alu_result);
            $display("  [EX]  branch_taken=%b  branch_target=0x%08h",
                        dut.ex_branch_taken, dut.ex_branch_target);
            $display("  [EX]  forward_a=%b  forward_b=%b",
                        dut.forward_a, dut.forward_b);

            // MEM stage
            $display("  [MEM] alu_result = 0x%08h", dut.mem_alu_result);
            $display("  [MEM] read_data  = 0x%08h", dut.mem_read_data);
            $display("  [MEM] mem_write=%b  mem_read=%b",
                        dut.mem_mem_write, dut.mem_mem_read);

            // WB stage
            $display("  [WB]  wb_data = 0x%08h  rd=%0d  reg_write=%b",
                        dut.wb_data, dut.wb_rd_out, dut.wb_reg_write_out);

            // Hazard signals
            $display("  [HZD] stall=%b  flush_if_id=%b  flush_id_ex=%b",
                        dut.stall, dut.flush_if_id, dut.flush_id_ex);
        end
    end

        // ── Pass/Fail checker ────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (!rst && dut.wb_reg_write_out && dut.wb_rd_out == 5'd28) begin
            if (dut.wb_data == 32'd99) begin
                $display("\n*** PASS: x28 = 99 written - all hazard tests passed ***\n");
                #20 $finish;
            end else if (dut.wb_data == 32'd1) begin
                $display("\n*** FAIL: x28 = 1 written - test failed ***\n");
                #20 $finish;
            end
        end
    end

endmodule
