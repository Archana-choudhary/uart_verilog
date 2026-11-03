`timescale 1ns/1ps

module tb_hello;
    reg        clk = 0, rst = 1;
    wire       line, valid;
    wire [7:0] rx_data;

    // Scaled-down values to keep simulation short
    uart_hello #(
        .CLK_FREQ  (1_000_000),
        .BAUD      (100_000),
        .PAUSE_CLKS(2_000)
    ) DUT (
        .clk(clk), .rst(rst), .tx(line)
    );

    uart_rx #(.CLK_FREQ(1_000_000), .BAUD(100_000)) RX (
        .clk(clk), .rst(rst), .rx(line),
        .data(rx_data), .valid(valid)
    );

    always #500 clk = ~clk;                            // 1 MHz clock

    // Print every received character (CR is skipped, LF gives a new line)
    always @(posedge clk)
        if (valid) begin
            if (rx_data == 8'h0D)      ;
            else if (rx_data == 8'h0A) $write("\n");
            else                       $write("%c", rx_data);
        end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_hello);
        #3000 rst = 0;
        #8_000_000 $finish;                            // about 2 messages
    end
endmodule
