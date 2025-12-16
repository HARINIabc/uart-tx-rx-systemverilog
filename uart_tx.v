`timescale 1ns/1ps

module uart_tx #(
    parameter CLK_FREQ = 50_000_000, // Hz
    parameter BAUD     = 9600
)(
    input  wire clk,
    input  wire rst,

    input  wire tx_start,        // pulse to start transmission
    input  wire [7:0] tx_data,   // byte to send

    output reg  tx_line,         // UART TX line
    output reg  tx_busy          // high while transmitting
);

    // -------------------------------------------------
    // Baud rate generator
    // -------------------------------------------------
    localparam integer BAUD_DIV = CLK_FREQ / BAUD;

    reg [$clog2(BAUD_DIV)-1:0] baud_cnt;
    reg baud_tick;

    always @(posedge clk) begin
        if (rst) begin
            baud_cnt  <= 0;
            baud_tick <= 1'b0;
        end else if (baud_cnt == BAUD_DIV - 1) begin
            baud_cnt  <= 0;
            baud_tick <= 1'b1;
        end else begin
            baud_cnt  <= baud_cnt + 1'b1;
            baud_tick <= 1'b0;
        end
    end

    // -------------------------------------------------
    // UART TX FSM
    // -------------------------------------------------
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            tx_line   <= 1'b1;   // idle high
            tx_busy   <= 1'b0;
            bit_idx   <= 3'd0;
            shift_reg <= 8'd0;
        end else begin
            case (state)

                // ---------------- IDLE ----------------
                IDLE: begin
                    tx_line <= 1'b1;
                    tx_busy <= 1'b0;

                    if (tx_start) begin
                        shift_reg <= tx_data;
                        state     <= START;
                        tx_busy   <= 1'b1;
                    end
                end

                // ---------------- START ----------------
                START: begin
                    if (baud_tick) begin
                        tx_line <= 1'b0;  // start bit
                        bit_idx <= 3'd0;
                        state   <= DATA;
                    end
                end

                // ---------------- DATA ----------------
                DATA: begin
                    if (baud_tick) begin
                        tx_line   <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;
                        bit_idx   <= bit_idx + 1'b1;

                        if (bit_idx == 3'd7) begin
                            state <= STOP;
                        end
                    end
                end

                // ---------------- STOP ----------------
                STOP: begin
                    if (baud_tick) begin
                        tx_line <= 1'b1;  // stop bit
                        state   <= IDLE;
                        tx_busy <= 1'b0;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
