`timescale 1ns/1ps

module tp_module_top_replica (
    input              clk,
    input              rst,
    input              start,
    input      [127:0] key_in,
    input      [127:0] byte_in,
    output reg [127:0] tx_word,
    output reg         tx_word_valid
);

    // Key expansion
    wire [127:0] k0, k1;
    wire [127:0] dummy [2:10];

    key_generator u_keygen (
        .key_in(key_in),
        .k0(k0), .k1(k1),
        .k2(dummy[2]), .k3(dummy[3]), .k4(dummy[4]),
        .k5(dummy[5]), .k6(dummy[6]), .k7(dummy[7]),
        .k8(dummy[8]), .k9(dummy[9]), .k10(dummy[10])
    );

    // AES first-round data path (as in top.v)
    wire [127:0] sub_bytes_out;
    wire [127:0] shift_rows_out;
    wire [127:0] mix_columns_out;

    sub_bytes  u_sub_bytes  (.in(byte_in),        .out(sub_bytes_out));
    shift_rows u_shift_rows (.in(sub_bytes_out),  .out(shift_rows_out));
    mix_columns u_mix_cols  (.in(shift_rows_out), .out(mix_columns_out));

    // Latch result on 'start' to mirror COMPUTE -> START_TX handoff point
    always @(posedge clk) begin
        if (rst) begin
            tx_word       <= 128'b0;
            tx_word_valid <= 1'b0;
        end else begin
            tx_word_valid <= 1'b0;
            if (start) begin
                tx_word       <= mix_columns_out ^ k1;
                tx_word_valid <= 1'b1;
            end
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Testbench: tb_top_sans_uart
// Drives key and plaintext directly.
// Prints the 128-bit tx_word produced by the replicated pipeline.
// -----------------------------------------------------------------------------
module tb_top_all_modules;

    // Clock/reset
    reg clk;
    reg rst;

    // Stimulus
    reg         start;
    reg [127:0] key_in;
    reg [127:0] byte_in;

    // Outputs from DUT
    wire [127:0] tx_word;
    wire         tx_word_valid;

    tp_module_top_replica dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .key_in(key_in),
        .byte_in(byte_in),
        .tx_word(tx_word),
        .tx_word_valid(tx_word_valid)
    );

    localparam integer CLK_HZ     = 12_000_000;
    localparam integer CLK_PERIOD = 1_000_000_000 / CLK_HZ; // ns

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        #10_000_000;
        $display("[%0t] TIMEOUT: ending simulation via watchdog.", $time);
        $finish;
    end

    // Pretty-print helper
    task print128;
        input [127:0] v;
        integer i;
        reg [7:0] b [0:15];
    begin
        {b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
         b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]} = v;
        $write("0x");
        for (i = 0; i < 16; i = i + 1) $write("%02x", b[i]);
    end
    endtask

    initial begin
        // Reset
        start   = 1'b0;
        key_in  = 128'b0;
        byte_in = 128'b0;

        rst = 1'b1;
        repeat (8) @(posedge clk);
        rst = 1'b0;
        repeat (4) @(posedge clk);

        // ---------------- Test Case 1 ----------------
        key_in  = 128'h2b7e1516_28aed2a6_abf71588_09cf4f3c;
        byte_in = 128'h3243f6a8_885a308d_313198a2_e0370734;

        // Pulse 'start' for 1 cycle
        @(posedge clk); start <= 1'b1;
        @(posedge clk); start <= 1'b0;

        wait (tx_word_valid === 1'b1);
        #1;

        $write("[%0t] TX_WORD (Test 1) = ", $time);
        print128(tx_word);
        $write("\n");

        // ---------------- Test Case 2 ----------------
        key_in  = 128'h00000000_00000000_00000000_00000000;
        byte_in = 128'h00000000_00000000_00000000_00000000;

        @(posedge clk); start <= 1'b1;
        @(posedge clk); start <= 1'b0;

        wait (tx_word_valid === 1'b1);
        #1;

        $write("[%0t] TX_WORD (Test 2) = ", $time);
        print128(tx_word);
        $write("\n");

        // Grace delay then finish
        #(10*CLK_PERIOD);
        $display("[%0t] TB done. Calling $finish.", $time);
        $finish;
    end

endmodule
