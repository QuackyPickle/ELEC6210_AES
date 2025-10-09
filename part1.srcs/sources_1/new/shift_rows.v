`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2025 09:50:55 PM
// Design Name: 
// Module Name: shift_rows
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module shift_rows(
    input wire [127:0] in,
    output wire [127:0] out
    );
    
    wire [7:0] s [0:15];
    
    assign { s[0],  s[1],  s[2],  s[3],
             s[4],  s[5],  s[6],  s[7],
             s[8],  s[9],  s[10], s[11],
             s[12], s[13], s[14], s[15] } = in;
    
    assign state_out = {
        s[0],  s[1],  s[2],  s[3],
        s[5],  s[6],  s[7],  s[4],
        s[10], s[11], s[8],  s[9],
        s[15], s[12], s[13], s[14]
    };
    
endmodule
