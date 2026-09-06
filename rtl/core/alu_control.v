// rtl/core/alu_control.v

module alu_control (
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input        funct7_5,
    input        funct7_1,      // bit 1 of funct7 — flags M-extension
    output reg [3:0] alu_ctrl,
    output reg       is_mul_div // high when this is an M-extension instruction
);
    always @(*) begin
        is_mul_div = 0; // default
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000; // ADD -- load/store address calc
            2'b01: alu_ctrl = 4'b0001; // SUB -- branch comparison
            2'b11: alu_ctrl = 4'b0000; // ADD -- LUI
            2'b10: begin
                if (funct7_1) begin
                    // M-extension -- mul_div_unit handles result
                    alu_ctrl   = 4'b0000;
                    is_mul_div = 1;
                end else begin
                    case (funct3)
                        3'b000: alu_ctrl = funct7_5 ? 4'b0001 : 4'b0000; // SUB/ADD
                        3'b001: alu_ctrl = 4'b0101; // SLL
                        3'b010: alu_ctrl = 4'b1000; // SLT
                        3'b011: alu_ctrl = 4'b1001; // SLTU
                        3'b100: alu_ctrl = 4'b0100; // XOR
                        3'b101: alu_ctrl = funct7_5 ? 4'b0111 : 4'b0110; // SRA/SRL
                        3'b110: alu_ctrl = 4'b0011; // OR
                        3'b111: alu_ctrl = 4'b0010; // AND
                        default: alu_ctrl = 4'b0000;
                    endcase
                end
            end
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule