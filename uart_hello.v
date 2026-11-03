// Sends "hi i am archana" + CR + LF repeatedly
module uart_hello #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD       = 9600,
    parameter PAUSE_CLKS = 50_000_000                  // delay between messages
)(
    input  wire clk,
    input  wire rst,
    output wire tx
);
    localparam MSG_LEN   = 15;                         // "hi i am archana"
    localparam TOTAL_LEN = MSG_LEN + 2;                // + CR + LF
    localparam [8*MSG_LEN-1:0] MSG = "hi i am archana";

    reg        start;
    reg  [7:0] data;
    wire       busy;

    // Character at position i (CR and LF after the text)
    function [7:0] char_at(input [4:0] i);
        begin
            if (i < MSG_LEN)       char_at = MSG[8*(MSG_LEN-1-i) +: 8];
            else if (i == MSG_LEN) char_at = 8'h0D;    // carriage return
            else                   char_at = 8'h0A;    // line feed
        end
    endfunction

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) TX (
        .clk(clk), .rst(rst),
        .start(start), .data(data),
        .tx(tx), .busy(busy)
    );

    localparam S_LOAD = 2'd0, S_WAIT_BUSY = 2'd1,
               S_WAIT_DONE = 2'd2, S_PAUSE = 2'd3;

    reg [1:0]  state;
    reg [4:0]  idx;
    reg [31:0] pause_cnt;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_LOAD; idx <= 0; start <= 1'b0;
            data <= 8'h00;   pause_cnt <= 0;
        end else begin
            case (state)
                S_LOAD: begin
                    data  <= char_at(idx);
                    start <= 1'b1;
                    state <= S_WAIT_BUSY;
                end
                S_WAIT_BUSY: begin
                    start <= 1'b0;
                    if (busy) state <= S_WAIT_DONE;
                end
                S_WAIT_DONE: begin
                    if (!busy) begin
                        if (idx == TOTAL_LEN - 1) begin
                            idx <= 0; pause_cnt <= 0; state <= S_PAUSE;
                        end else begin
                            idx <= idx + 1; state <= S_LOAD;
                        end
                    end
                end
                S_PAUSE: begin
                    if (pause_cnt == PAUSE_CLKS - 1) state <= S_LOAD;
                    else pause_cnt <= pause_cnt + 1;
                end
            endcase
        end
    end
endmodule
