`timescale 1ns/1ps

module uart_loopback_tb;

    // -----------------------------
    // Clock & reset
    // -----------------------------
    reg clk;
    reg rst;

    // -----------------------------
    // TX signals
    // -----------------------------
    reg        tx_start;
    reg [7:0]  tx_data;
    wire       tx_line;
    wire       tx_busy;

    // -----------------------------
    // RX signals
    // -----------------------------
    wire [7:0] rx_data;
    wire       rx_valid;

    // -----------------------------
    // Instantiate UART TX
    // -----------------------------
    uart_tx #(
        .CLK_FREQ(50_000_000),
        .BAUD(9600)
    ) tx (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_line(tx_line),
        .tx_busy(tx_busy)
    );

    // -----------------------------
    // Instantiate UART RX
    // -----------------------------
    uart_rx #(
        .CLK_FREQ(50_000_000),
        .BAUD(9600)
    ) rx (
        .clk(clk),
        .rst(rst),
        .rx_line(tx_line),   // 🔁 LOOPBACK CONNECTION
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    // -----------------------------
    // Clock generation (50 MHz)
    // -----------------------------
    always #10 clk = ~clk;

    // -----------------------------
    // Test sequence
    // -----------------------------
    initial begin
        // Waveform
        $dumpfile("uart_loopback.vcd");
        $dumpvars(0, uart_loopback_tb);

        // Init
        clk      = 0;
        rst      = 1;
        tx_start = 0;
        tx_data  = 8'h00;

        // Reset
        #100;
        rst = 0;

        // Wait
        #200;

        // Send byte
        tx_data  = 8'hA5;
        tx_start = 1;
        #20;
        tx_start = 0;

        // Wait for RX
        wait (rx_valid);

        #50;
        $finish;
    end

    // -----------------------------
    // Monitor
    // -----------------------------
    initial begin
        $monitor(
            "t=%0t | tx_busy=%b | rx_valid=%b rx_data=0x%02h",
            $time, tx_busy, rx_valid, rx_data
        );
    end

endmodule
