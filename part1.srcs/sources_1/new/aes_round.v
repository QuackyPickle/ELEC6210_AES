`timescale 1ns / 1ps
module aes_round(input clk, input [127:0] in, input [127:0] key, output [127:0] out);
    wire [127:0] sb, sr, mc;
    sub_bytes  u_sb (.in(in),  .out(sb));
    shift_rows u_sr (.in(sb),  .out(sr));
    mix_columns u_mc (.in(sr), .out(mc));
    assign out = mc ^ key;

endmodule

module aes_final_round(
    input  clk,
    input  [127:0] in,
    input  [127:0] key,
    output [127:0] out
);
	// Sub bytes and shift rows
    wire [127:0] sb, sr;
    sub_bytes  u_sb (.in(in),  .out(sb));
    shift_rows u_sr (.in(sb),  .out(sr));

	// Fix the byte ordering for the final round
    wire [7:0] s [0:15];
    assign {
        s[0],  s[1],  s[2],  s[3],
        s[4],  s[5],  s[6],  s[7],
        s[8],  s[9],  s[10], s[11],
        s[12], s[13], s[14], s[15]
    } = sr;

    wire [127:0] sr_fips = {
        s[0],  s[4],  s[8],  s[12],
        s[1],  s[5],  s[9],  s[13],
        s[2],  s[6],  s[10], s[14],
        s[3],  s[7],  s[11], s[15]
    };

    assign out = sr_fips ^ key;
endmodule

