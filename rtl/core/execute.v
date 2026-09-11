// RISC V _ CPU/rtl/core/execute.v

module execute (
    input        clk, rst,        // needed for mul_div_unit
    // Inputs from ID/EX register
    input  [31:0] ex_pc, ex_rdata1, ex_rdata2, ex_imm,
    input  [4:0]  ex_rs1, ex_rs2, ex_rd,
    input  [2:0]  ex_funct3,
    input         ex_funct7_5,
    input         ex_funct7_1,    // M-extension flag
    input         ex_alu_src, ex_branch,
    input  [1:0]  ex_alu_op,
    input  [6:0]  ex_opcode,
    // Forwarding inputs
    input  [31:0] ex_mem_alu_result,
    input  [31:0] wb_data,
    input  [1:0]  forward_a, forward_b,
    // Outputs
    output [31:0] alu_result,
    output [31:0] branch_target,
    output        branch_taken,
    output [31:0] rdata2_out,
    output        jalr_taken,
    output [31:0] jalr_target,
    output        mul_div_stall,  // stall pipeline while mul/div runs
    output [31:0] mul_div_result, // result from mul_div_unit
    output        ex_is_mul_div   // passes to EX/MEM to flag mul/div writeback
);
    wire [3:0]  alu_ctrl;
    wire        alu_zero;
    wire [31:0] raw_alu_result;
    wire        is_mul_div;
    reg  [31:0] alu_in_a, forwarded_b;

    // Opcode decoding
    wire auipc     = (ex_opcode == 7'b0010111);
    wire lui       = (ex_opcode == 7'b0110111);
    wire jalr      = (ex_opcode == 7'b1100111);
    wire jal       = (ex_opcode == 7'b1101111);
    wire is_branch = (ex_opcode == 7'b1100011);

    // 3-way forwarding mux -- input A
    always @(*) begin
        if (lui) begin
            alu_in_a = 32'd0; // LUI loads 0 + imm (does not use rs1)
        end else begin
            case (forward_a)
                2'b00: alu_in_a = auipc ? ex_pc : ex_rdata1;
                2'b10: alu_in_a = ex_mem_alu_result;
                2'b01: alu_in_a = wb_data;
                default: alu_in_a = ex_rdata1;
            endcase
        end
    end

    // 3-way forwarding mux -- input B
    always @(*) begin
        case (forward_b)
            2'b00: forwarded_b = ex_rdata2;
            2'b10: forwarded_b = ex_mem_alu_result;
            2'b01: forwarded_b = wb_data;
            default: forwarded_b = ex_rdata2;
        endcase
    end

    // alu_src mux -- pick immediate or forwarded rs2
    wire [31:0] alu_in_b = ex_alu_src ? ex_imm : forwarded_b;

    // rdata2_out carries the forwarded rs2 to EX/MEM (used by SW/SH/SB)
    assign rdata2_out = forwarded_b;

    // Branch / JAL target: PC + imm
    assign branch_target = ex_pc + ex_imm;

    // Direct, overflow-safe branch comparisons
    wire beq  = (alu_in_a == forwarded_b);
    wire bne  = !beq;
    wire blt  = ($signed(alu_in_a) < $signed(forwarded_b));
    wire bge  = !blt;
    wire bltu = (alu_in_a < forwarded_b);
    wire bgeu = !bltu;

    reg branch_condition;
    always @(*) begin
        case (ex_funct3)
            3'b000:  branch_condition = beq;
            3'b001:  branch_condition = bne;
            3'b100:  branch_condition = blt;
            3'b101:  branch_condition = bge;
            3'b110:  branch_condition = bltu;
            3'b111:  branch_condition = bgeu;
            default: branch_condition = 1'b0;
        endcase
    end

    // JAL branches unconditionally; conditional branches require branch_condition
    assign branch_taken = jal | (is_branch & branch_condition);

    // JALR target -- rs1 + imm, LSB forced to 0 per RISC-V spec
    assign jalr_taken  = jalr;
    assign jalr_target = (alu_in_a + ex_imm) & 32'hFFFFFFFE;

    // Return address link: JAL and JALR write PC + 4 to rd; all other ops write ALU result
    assign alu_result = (jal | jalr) ? (ex_pc + 32'd4) : raw_alu_result;

    // mul/div stall and execution flag
    wire mul_div_done;
    reg  mul_div_running;
    reg  start_pulse;

    always @(posedge clk or posedge rst) begin
        if (rst)
            mul_div_running <= 0;
        else if (start_pulse)
            mul_div_running <= 1;
        else if (mul_div_done)
            mul_div_running <= 0;
    end

    always @(*) begin
        start_pulse = is_mul_div && !mul_div_running && !mul_div_done;
    end

    assign mul_div_stall = is_mul_div && !mul_div_done;
    assign ex_is_mul_div = is_mul_div;

    alu_control alu_ctrl_unit (
        .alu_op(ex_alu_op),
        .funct3(ex_funct3),
        .funct7_5(ex_funct7_5),
        .funct7_1(ex_funct7_1),
        .alu_ctrl(alu_ctrl),
        .is_mul_div(is_mul_div)
    );

    alu alu_unit (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(alu_ctrl),
        .result(raw_alu_result),
        .zero(alu_zero)
    );

    mul_div_unit mdu (
        .clk(clk),
        .rst(rst),
        .start(start_pulse),
        .funct3(ex_funct3),
        .a(alu_in_a),
        .b(forwarded_b),
        .result(mul_div_result),
        .done(mul_div_done)
    );

endmodule