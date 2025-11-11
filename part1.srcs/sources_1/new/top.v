`timescale 1ns / 1ps

module top(
    input        i_rx,
    input        clk,
    output       o_tx,
    input        rst
);
	
	// UART signals
   reg         tx_start;
   wire        rx_valid, tx_done, tx_busy;
   reg  [127:0] tx_byte;
   wire [255:0] rx_byte;

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
    localparam RST      = 2'b00,
               WAIT     = 2'b01,
               COMPUTE  = 2'b10,
               START_TX = 2'b11;

    reg [1:0] state;

    reg  [127:0] plaintext_reg;
    reg  [127:0] key_in;
    wire [127:0] ciphertext;

    wire [127:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;

    key_generator u_keygen (
        .key_in(key_in),
        .k0(k0), .k1(k1), .k2(k2), .k3(k3), .k4(k4),
        .k5(k5), .k6(k6), .k7(k7), .k8(k8), .k9(k9), .k10(k10)
    );

    wire [127:0] r0_out, r1_out, r2_out, r3_out, r4_out, r5_out, r6_out, r7_out, r8_out, r9_out, r10_out;

    assign r0_out = plaintext_reg ^ k0;

    aes_round r1 (.clk(clk), .in(r0_out), .key(k1), .out(r1_out));
    aes_round r2 (.clk(clk), .in(r1_out), .key(k2), .out(r2_out));
    aes_round r3 (.clk(clk), .in(r2_out), .key(k3), .out(r3_out));
    aes_round r4 (.clk(clk), .in(r3_out), .key(k4), .out(r4_out));
    aes_round r5 (.clk(clk), .in(r4_out), .key(k5), .out(r5_out));
    aes_round r6 (.clk(clk), .in(r5_out), .key(k6), .out(r6_out));
    aes_round r7 (.clk(clk), .in(r6_out), .key(k7), .out(r7_out));
    aes_round r8 (.clk(clk), .in(r7_out), .key(k8), .out(r8_out));
    aes_round r9 (.clk(clk), .in(r8_out), .key(k9), .out(r9_out));

    aes_final_round r10 (.clk(clk), .in(r9_out), .key(k10), .out(r10_out));

    assign ciphertext = r10_out;

    // State-Machine logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= RST;
            tx_start <= 0;
            tx_words <= 0;
            plaintext_reg <= 0;
            key_in <= 0;
        end else begin
            tx_start <= 0;
            case (state)
                RST: begin
                    if (rx_valid) begin
                        plaintext_reg <= rx_words[127:0];
                        key_in        <= rx_words[255:128];
                        state <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    tx_words <= ciphertext;
                    state <= START_TX;
                end

                START_TX: begin
                    if (!tx_busy) begin
                        tx_start <= 1'b1;
                        state <= WAIT;
                    end
                end

                WAIT: begin
                    if (tx_done)
                        state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
