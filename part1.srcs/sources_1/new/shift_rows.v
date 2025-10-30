`timescale 1ns / 1ps

module shift_rows(
    input  wire [127:0] in,
    output wire [127:0] out
);
    wire [7:0] s [0:15];
    assign {
        s[0],  s[1],  s[2],  s[3],
        s[4],  s[5],  s[6],  s[7],
        s[8],  s[9],  s[10], s[11],
        s[12], s[13], s[14], s[15]
    } = in;

    assign out = {
        // Row 0 (no shift)
        s[0],  s[4],  s[8],  s[12],
        // Row 1 (shift left 1)
        s[5],  s[9],  s[13], s[1],
        // Row 2 (shift left 2)
        s[10], s[14], s[2],  s[6],
        // Row 3 (shift left 3)
        s[15], s[3],  s[7],  s[11]
    };

endmodule
