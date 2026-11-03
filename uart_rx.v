// UART receiver, 8N1, LSB first (used in the testbench)
module uart_rx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 9600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid      // 1-clock pulse when a byte is received
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg        rx_d1, rx_s;      // 2-flop synchronizer

    always @(posedge clk) begin
        rx_d1 <= rx;
        rx_s  <= rx_d1;
    end

    always @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            valid   <= 1'b0;
            data    <= 8'h00;
            clk_cnt <= 0;
            bit_idx <= 0;
        end else begin
            valid <= 1'b0;
            case (state)
                IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_s == 1'b0)                  // start bit detected
                        state <= START;
                end

                START: begin                           // check middle of start bit
                    if (clk_cnt == (CLKS_PER_BIT/2) - 1) begin
                        clk_cnt <= 0;
                        if (rx_s == 1'b0)
                            state <= DATA;
                        else
                            state <= IDLE;             // false start
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt       <= 0;
                        data[bit_idx] <= rx_s;         // LSB first
                        if (bit_idx == 7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        valid <= 1'b1;
                        state <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule
