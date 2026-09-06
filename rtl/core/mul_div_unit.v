// rtl/core/mul_div_unit.v

module mul_div_unit (
    input        clk, rst,
    input        start,
    input  [2:0] funct3,
    input  [31:0] a, b,
    output reg [31:0] result,
    output reg done
);
    localparam MUL    = 3'b000;
    localparam MULH   = 3'b001;
    localparam MULHSU = 3'b010;
    localparam MULHU  = 3'b011;
    localparam DIV    = 3'b100;
    localparam DIVU   = 3'b101;
    localparam REM    = 3'b110;
    localparam REMU   = 3'b111;

    localparam IDLE    = 2'b00;
    localparam RUNNING = 2'b01;
    localparam FINISH  = 2'b10;

    reg [1:0]  state;
    reg [63:0] mul_result;
    reg [31:0] dividend, divisor, quotient, remainder;
    reg [31:0] partial;           // moved outside always block
    reg [4:0]  div_cycle;
    reg        neg_quotient, neg_remainder;
    reg [2:0]  saved_funct3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            done      <= 0;
            result    <= 0;
            div_cycle <= 0;
        end else begin
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        saved_funct3 <= funct3;
                        case (funct3)
                            MUL: begin
                                mul_result <= $signed(a) * $signed(b);
                                state      <= FINISH;
                            end
                            MULH: begin
                                mul_result <= $signed({{32{a[31]}}, a}) *
                                              $signed({{32{b[31]}}, b});
                                state      <= FINISH;
                            end
                            MULHSU: begin
                                mul_result <= $signed({{32{a[31]}}, a}) *
                                              {32'd0, b};
                                state      <= FINISH;
                            end
                            MULHU: begin
                                mul_result <= {32'd0, a} * {32'd0, b};
                                state      <= FINISH;
                            end
                            DIV: begin
                                if (b == 0) begin
                                    result <= 32'hFFFFFFFF;
                                    done   <= 1;
                                end else if (a == 32'h80000000 && b == 32'hFFFFFFFF) begin
                                    result <= 32'h80000000;
                                    done   <= 1;
                                end else begin
                                    neg_quotient  <= a[31] ^ b[31];
                                    neg_remainder <= a[31];
                                    dividend      <= a[31] ? -a : a;
                                    divisor       <= b[31] ? -b : b;
                                    quotient      <= 0;
                                    remainder     <= 0;
                                    div_cycle     <= 0;
                                    state         <= RUNNING;
                                end
                            end
                            DIVU: begin
                                if (b == 0) begin
                                    result <= 32'hFFFFFFFF;
                                    done   <= 1;
                                end else begin
                                    neg_quotient  <= 0;
                                    neg_remainder <= 0;
                                    dividend      <= a;
                                    divisor       <= b;
                                    quotient      <= 0;
                                    remainder     <= 0;
                                    div_cycle     <= 0;
                                    state         <= RUNNING;
                                end
                            end
                            REM: begin
                                if (b == 0) begin
                                    result <= a;
                                    done   <= 1;
                                end else if (a == 32'h80000000 && b == 32'hFFFFFFFF) begin
                                    result <= 32'h00000000;
                                    done   <= 1;
                                end else begin
                                    neg_quotient  <= a[31] ^ b[31];
                                    neg_remainder <= a[31];
                                    dividend      <= a[31] ? -a : a;
                                    divisor       <= b[31] ? -b : b;
                                    quotient      <= 0;
                                    remainder     <= 0;
                                    div_cycle     <= 0;
                                    state         <= RUNNING;
                                end
                            end
                            REMU: begin
                                if (b == 0) begin
                                    result <= a;
                                    done   <= 1;
                                end else begin
                                    neg_quotient  <= 0;
                                    neg_remainder <= 0;
                                    dividend      <= a;
                                    divisor       <= b;
                                    quotient      <= 0;
                                    remainder     <= 0;
                                    div_cycle     <= 0;
                                    state         <= RUNNING;
                                end
                            end
                        endcase
                    end
                end

                RUNNING: begin
                    // Iterative restoring division -- one bit per cycle
                    partial   = (remainder << 1) | dividend[31];
                    dividend  <= dividend << 1;
                    if (partial >= divisor) begin
                        remainder <= partial - divisor;
                        quotient  <= (quotient << 1) | 1;
                    end else begin
                        remainder <= partial;
                        quotient  <= quotient << 1;
                    end
                    div_cycle <= div_cycle + 1;
                    if (div_cycle == 31)
                        state <= FINISH;
                end

                FINISH: begin
                    case (saved_funct3)
                        MUL:    result <= mul_result[31:0];
                        MULH:   result <= mul_result[63:32];
                        MULHSU: result <= mul_result[63:32];
                        MULHU:  result <= mul_result[63:32];
                        DIV:    result <= neg_quotient  ? -quotient  : quotient;
                        DIVU:   result <= quotient;
                        REM:    result <= neg_remainder ? -remainder : remainder;
                        REMU:   result <= remainder;
                    endcase
                    done  <= 1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule