`timescale 1ns / 1ps

module top(
   input       i_rx,
   input       clk,
   output      o_tx,
   input       rst
);
   
   // UART signals
   reg         tx_start;
   wire        rx_valid, tx_done, tx_busy;
   reg [127:0] tx_byte;
   wire [127:0] rx_byte;   
   
   // UART module
   uart_sm #(.BAUD(115200), .CLK_SPEED(12_000_000)) UART_LINK (
        .clk(clk),
        .reset(rst),
        .i_rx(i_rx),
        .o_tx(o_tx),
        .tx_start(tx_start),
        .tx_done(tx_done),
        .tx_busy(tx_busy),
        .rx_done_really(rx_valid),
        .rx_words(rx_byte),
        .tx_words(tx_byte)
    );

    // FSM states
    localparam RST      = 3'b000,
               WAIT     = 3'b001,
               COMPUTE  = 3'b010,
               START_TX = 3'b011,
               WAIT_TX  = 3'b100,
               WAIT2    = 3'b101;

    reg [2:0] state;
    reg [127:0] byte;

    wire [127:0] sub_bytes_out;

    sub_bytes u_sub_bytes (
        .in(byte),
        .out(sub_bytes_out)
    );

    wire [127:0] shift_rows_out;

    shift_rows u_shift_rows (
        .in(sub_bytes_out),
        .out(shift_rows_out)
    );
    
    wire [127:0] mc_out;
    
    mix_columns u_mix_columns (
        .in(shift_rows_out),
        .out(mc_out)
    );

    // --- State Machine ---
    always @(posedge clk) begin
        if (rst) begin
            state     <= RST;
            byte      <= 128'b0;
            tx_byte   <= 128'b0;
            tx_start  <= 1'b0;
        end else begin
            case (state)
                RST: begin
                    state <= WAIT;
                end

                WAIT: begin
                    if (rx_valid) begin
                        byte  <= rx_byte;
                        state <= WAIT2;
                    end
                end

                WAIT2: begin
                    state <= COMPUTE;
                end

                COMPUTE: begin
                    tx_byte <= mc_out;  // Send the full output
                    state   <= START_TX;
                end

                START_TX: begin
                    tx_start <= 1'b1;
                    state <= WAIT_TX;
                end

                WAIT_TX: begin
                    tx_start <= 1'b0;
                    if (tx_done)
                        state <= RST;
                end
            endcase
        end
    end
endmodule



