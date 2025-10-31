`timescale 1ns / 1ps

module key_generator(
    input  [127:0] key_in,
    output [127:0] k0,
    output [127:0] k1,
    output [127:0] k2,
    output [127:0] k3,
    output [127:0] k4,
    output [127:0] k5,
    output [127:0] k6,
    output [127:0] k7,
    output [127:0] k8,
    output [127:0] k9,
    output [127:0] k10
    );

    // Round constants
    localparam [7:0] RC1  = 8'h01;
    localparam [7:0] RC2  = 8'h02;
    localparam [7:0] RC3  = 8'h04;
    localparam [7:0] RC4  = 8'h08;
    localparam [7:0] RC5  = 8'h10;
    localparam [7:0] RC6  = 8'h20;
    localparam [7:0] RC7  = 8'h40;
    localparam [7:0] RC8  = 8'h80;
    localparam [7:0] RC9  = 8'h1B;
    localparam [7:0] RC10 = 8'h36;

    // Round key 0 = original key
    assign k0 = key_in;

    // Sequential key expansion chain
    key_schedule r1  (.in(k0),  .RC(RC1),  .out(k1));
    key_schedule r2  (.in(k1),  .RC(RC2),  .out(k2));
    key_schedule r3  (.in(k2),  .RC(RC3),  .out(k3));
    key_schedule r4  (.in(k3),  .RC(RC4),  .out(k4));
    key_schedule r5  (.in(k4),  .RC(RC5),  .out(k5));
    key_schedule r6  (.in(k5),  .RC(RC6),  .out(k6));
    key_schedule r7  (.in(k6),  .RC(RC7),  .out(k7));
    key_schedule r8  (.in(k7),  .RC(RC8),  .out(k8));
    key_schedule r9  (.in(k8),  .RC(RC9),  .out(k9));
    key_schedule r10 (.in(k9),  .RC(RC10), .out(k10));

endmodule


module key_schedule(
    input [127:0] in,
    input [7:0] RC,
    output [127:0] out
    );
    
    wire [31:0] w0 = in[127:96];
    wire [31:0] w1 = in[95:64];
    wire [31:0] w2 = in[63:32];
    wire [31:0] w3 = in[31:0];
    
    wire [31:0] w3_g;
    g g_module(.in(w3), .RC(RC), .out(w3_g));
    
    wire [31:0] w0_out = w0 ^ w3_g;
    wire [31:0] w1_out = w1 ^ w0_out;
    wire [31:0] w2_out = w2 ^ w1_out;
    wire [31:0] w3_out = w3 ^ w2_out;
    
    assign out = {w0_out, w1_out, w2_out, w3_out};
    
    
    
endmodule

module g(
    input [31:0] in,
    input [7:0] RC,
    output [31:0] out
    );
    
    wire [7:0] v [0:3];
    assign { v[0], v[1], v[2], v[3] } = in;
    
    wire [7:0] s0, s1, s2, s3;
    s_box sb0 (v[1], s0);
    s_box sb1 (v[2], s1);
    s_box sb2 (v[3], s2);
    s_box sb3 (v[0], s3);

    assign out = {s0 ^ RC, s1, s2, s3};
    
endmodule