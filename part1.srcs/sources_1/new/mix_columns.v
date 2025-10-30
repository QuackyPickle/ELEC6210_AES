`timescale 1ns / 1ps

module x_time ( //gallois field multiplication
    input  wire [7:0] a,
    output wire [7:0] b
);
    wire [7:0] shifted     = {a[6:0], 1'b0};
    wire [7:0] conditional = 8'h1B & {8{a[7]}}; //check if the first bit was a 1
    assign b = shifted ^ conditional;
endmodule

module mix_column (
    input  wire [31:0] in,   // {a0,a1,a2,a3}
    output wire [31:0] out   // {b0,b1,b2,b3}
);
    //unpack columns
    wire [7:0] a0 = in[31:24];
    wire [7:0] a1 = in[23:16];
    wire [7:0] a2 = in[15:8];
    wire [7:0] a3 = in[7:0];

    wire [7:0] t = a0 ^ a1 ^ a2 ^ a3;
    wire [7:0] u = a0;

    // compute xtime for the pairs used
    wire [7:0] xt0, xt1, xt2, xt3;
    x_time xtime0(.a(a0 ^ a1), .b(xt0));
    x_time xtime1(.a(a1 ^ a2), .b(xt1));
    x_time xtime2(.a(a2 ^ a3), .b(xt2));
    x_time xtime3(.a(a3 ^ u ), .b(xt3));

    // correctly combine to produce outputs
    wire [7:0] b0 = a0 ^ t ^ xt0;
    wire [7:0] b1 = a1 ^ t ^ xt1;
    wire [7:0] b2 = a2 ^ t ^ xt2;
    wire [7:0] b3 = a3 ^ t ^ xt3;

    assign out = {b0, b1, b2, b3};
endmodule

module mix_columns (
    input  wire [127:0] in,
    output wire [127:0] out
);
    //extract column ordering
    wire [7:0] s [0:15];
    assign {
        s[0],  s[4],  s[8],  s[12],
        s[1],  s[5],  s[9],  s[13],
        s[2],  s[6],  s[10], s[14],
        s[3],  s[7],  s[11], s[15]
    } = in;

    //build column words
    wire [31:0] col0 = {s[0],  s[1],  s[2],  s[3]};
    wire [31:0] col1 = {s[4],  s[5],  s[6],  s[7]};
    wire [31:0] col2 = {s[8],  s[9],  s[10], s[11]};
    wire [31:0] col3 = {s[12], s[13], s[14], s[15]};

    wire [31:0] col0_out, col1_out, col2_out, col3_out;
    mix_column mc0(.in(col0), .out(col0_out));
    mix_column mc1(.in(col1), .out(col1_out));
    mix_column mc2(.in(col2), .out(col2_out));
    mix_column mc3(.in(col3), .out(col3_out));

    //reassemble output
    assign out = {
        col0_out[31:24], col0_out[23:16], col0_out[15:8], col0_out[7:0],
        col1_out[31:24], col1_out[23:16], col1_out[15:8], col1_out[7:0],
        col2_out[31:24], col2_out[23:16], col2_out[15:8], col2_out[7:0],
        col3_out[31:24], col3_out[23:16], col3_out[15:8], col3_out[7:0]
    };
endmodule
