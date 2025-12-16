`timescale 1ns/1ps

module uart_rx #(
    parameter CLK_FREQ = 50_000_000, // Hz
    parameter BAUD     = 9600
)(
    input  wire clk,
    input  wire rst,

    input  wire rx_line,        // serial input
    output reg  [7:0] rx_data,  // received byte
    output reg  rx_valid        // pulse when byte received
);

    // -------------------------------------------------
    // Baud rate generator (same as TX)
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
    // UART RX FSM
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
            state    <= IDLE;
            bit_idx  <= 0;
            shift_reg<= 0;
            rx_data  <= 0;
            rx_valid <= 0;
        end else begin
            rx_valid <= 1'b0; // default

            case (state)

                // ---------------- IDLE ----------------
                IDLE: begin
                    if (rx_line == 1'b0) begin
                        // Detect start bit
                        state   <= START;
                        baud_cnt<= 0;
                    end
                end

                // ---------------- START ----------------
                START: begin
                    if (baud_tick) begin
                        // Sample in middle of bit
                        if (rx_line == 1'b0) begin
                            bit_idx <= 0;
                            state   <= DATA;
                        end else begin
                            state <= IDLE; // false start
                        end
                    end
                end

                // ---------------- DATA ----------------
                DATA: begin
                    if (baud_tick) begin
                        shift_reg <= {rx_line, shift_reg[7:1]};
                        bit_idx   <= bit_idx + 1'b1;

                        if (bit_idx == 3'd7) begin
                            state <= STOP;
                        end
                    end
                end

                // ---------------- STOP ----------------
                STOP: begin
                    if (baud_tick) begin
                        if (rx_line == 1'b1) begin
                            rx_data  <= shift_reg;
                            rx_valid <= 1'b1; // byte received
                        end
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
