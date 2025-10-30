
`timescale 1ns/1ps

module tb_shift_rows;
    reg  [127:0] in;
    wire [127:0] out;

    // DUT
    shift_rows dut (
        .in(in),
        .out(out)
    );

    function [127:0] ref_shift_rows;
        input [127:0] x;
        reg [7:0] s [0:15];
        begin
            { s[0],  s[1],  s[2],  s[3],
              s[4],  s[5],  s[6],  s[7],
              s[8],  s[9],  s[10], s[11],
              s[12], s[13], s[14], s[15] } = x;

            ref_shift_rows = {
                s[0],  s[4],  s[8],  s[12],
                s[5],  s[9],  s[13], s[1],
                s[10], s[14], s[2],  s[6],
                s[15], s[3],  s[7],  s[11]
            };
        end
    endfunction

    integer i;
    reg [127:0] exp;

    initial begin
        // Test 1: Identity-friendly ramp bytes 0x00..0x0F placed as {b0..b15}
        in = 128'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        #1;
        exp = ref_shift_rows(in);
        if (out !== exp) begin
            $display("FAIL T1: out=%032h exp=%032h", out, exp);
            $fatal;
        end else begin
            $display("PASS T1: out=%032h", out);
        end

        // Test 2: Random-looking pattern
        in = 128'hD4_E0_B8_1E_BF_B4_41_27_5D_52_11_98_30_AE_F1_E5;
        #1;
        exp = ref_shift_rows(in);
        if (out !== exp) begin
            $display("FAIL T2: out=%032h exp=%032h", out, exp);
            $fatal;
        end else begin
            $display("PASS T2: out=%032h", out);
        end

        // Test 3: All same byte
        in = {16{8'hAA}};
        #1;
        exp = ref_shift_rows(in);
        if (out !== exp) begin
            $display("FAIL T3: out=%032h exp=%032h", out, exp);
            $fatal;
        end else begin
            $display("PASS T3: out=%032h", out);
        end

        $display("All shift_rows tests passed.");
        $finish;
    end
endmodule
