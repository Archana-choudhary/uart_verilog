// UART transmitter, 8N1, LSB first
module uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 9600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       start,     // pulse high for 1 clock to send
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift;

    always @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            tx      <= 1'b1;
            busy    <= 1'b0;
            clk_cnt <= 0;
            bit_idx <= 0;
            shift   <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (start) begin
                        shift   <= data;
                        busy    <= 1'b1;
                        clk_cnt <= 0;
                        state   <= START;
                    end else
                        busy <= 1'b0;
                end

                START: begin
                    tx <= 1'b0;                        // start bit
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        bit_idx <= 0;
                        state   <= DATA;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                DATA: begin
                    tx <= shift[bit_idx];              // LSB first
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end

                STOP: begin
                    tx <= 1'b1;                        // stop bit
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        state <= IDLE;
                        busy  <= 1'b0;
                    end else
                        clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule
