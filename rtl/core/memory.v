// RISC V _ CPU/rtl/core/memory.v

module memory (
    input        clk, rst,
    input  [31:0] mem_alu_result,
    input  [31:0] mem_rdata2,
    input  [4:0]  mem_rd,
    input  [2:0]  mem_funct3,
    input  [31:0] imem_rdata,     // Data read from IMEM (.rodata)
    input         mem_mem_read,
    input         mem_mem_write,
    input         mem_reg_write,
    input         mem_mem_to_reg,
    output [31:0] alu_result_out,
    output [31:0] read_data,
    output [4:0]  rd_out,
    output        reg_write_out,
    output        mem_to_reg_out,
    output reg       uart_valid,
    output reg [7:0] uart_data
);
    localparam UART_ADDR  = 32'h10000000;
    localparam DMEM_BASE  = 32'h00010000;
    localparam DMEM_MASK  = 32'h00003FFF;

    wire is_uart = (mem_alu_result == UART_ADDR);
    wire is_dmem = (mem_alu_result[31:14] == DMEM_BASE[31:14]);
    wire is_imem = (mem_alu_result < DMEM_BASE);

    // Strip base address to get dmem-local address
    wire [31:0] dmem_addr = mem_alu_result & DMEM_MASK;

    // --- Sub-word Store Logic (SB, SH, SW) ---
    reg [3:0]  dmem_we;
    reg [31:0] dmem_wdata;

    always @(*) begin
        if (mem_mem_write && is_dmem && !is_uart) begin
            case (mem_funct3)
                3'b000: begin // SB
                    case (mem_alu_result[1:0])
                        2'b00: dmem_we = 4'b0001;
                        2'b01: dmem_we = 4'b0010;
                        2'b10: dmem_we = 4'b0100;
                        2'b11: dmem_we = 4'b1000;
                    endcase
                    dmem_wdata = {4{mem_rdata2[7:0]}};
                end
                3'b001: begin // SH
                    dmem_we    = mem_alu_result[1] ? 4'b1100 : 4'b0011;
                    dmem_wdata = {2{mem_rdata2[15:0]}};
                end
                3'b010: begin // SW
                    dmem_we    = 4'b1111;
                    dmem_wdata = mem_rdata2;
                end
                default: begin
                    dmem_we    = 4'b0000;
                    dmem_wdata = mem_rdata2;
                end
            endcase
        end else begin
            dmem_we    = 4'b0000;
            dmem_wdata = 32'd0;
        end
    end

    wire [31:0] dmem_rdata;

    dmem dmem_inst (
        .clk  (clk),
        .we   (dmem_we),
        .addr (dmem_addr),
        .wdata(dmem_wdata),
        .rdata(dmem_rdata)
    );

    // Mux memory source: IMEM for constants/strings (< 0x00010000), DMEM otherwise
    wire [31:0] raw_rdata = is_imem ? imem_rdata : dmem_rdata;

    // --- Sub-word Load Logic (LB, LH, LW, LBU, LHU) ---
    reg [7:0] load_byte;
    always @(*) begin
        case (mem_alu_result[1:0])
            2'b00: load_byte = raw_rdata[7:0];
            2'b01: load_byte = raw_rdata[15:8];
            2'b10: load_byte = raw_rdata[23:16];
            2'b11: load_byte = raw_rdata[31:24];
        endcase
    end

    wire [15:0] load_half = mem_alu_result[1] ? raw_rdata[31:16] : raw_rdata[15:0];

    reg [31:0] mem_read_data_formatted;
    always @(*) begin
        case (mem_funct3)
            3'b000:  mem_read_data_formatted = {{24{load_byte[7]}}, load_byte}; // LB (sign-extended)
            3'b001:  mem_read_data_formatted = {{16{load_half[15]}}, load_half}; // LH (sign-extended)
            3'b010:  mem_read_data_formatted = raw_rdata;                       // LW
            3'b100:  mem_read_data_formatted = {24'd0, load_byte};               // LBU (zero-extended)
            3'b101:  mem_read_data_formatted = {16'd0, load_half};               // LHU (zero-extended)
            default: mem_read_data_formatted = raw_rdata;
        endcase
    end

    // --- UART MMIO Output Register ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            uart_valid <= 0;
            uart_data  <= 8'h00;
        end else begin
            uart_valid <= 0;
            if (mem_mem_write && is_uart) begin
                uart_valid <= 1;
                uart_data  <= mem_rdata2[7:0];
            end
        end
    end

    assign read_data      = is_uart ? 32'h00000001 : mem_read_data_formatted;
    assign alu_result_out = mem_alu_result;
    assign rd_out         = mem_rd;
    assign reg_write_out  = mem_reg_write;
    assign mem_to_reg_out = mem_mem_to_reg;

endmodule