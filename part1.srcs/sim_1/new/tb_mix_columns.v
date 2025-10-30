
`timescale 1ns/1ps

module tb_mix_column;
    reg  [31:0] in_col;
    wire [31:0] out_col;

    // DUT
    mix_column dut (
        .in(in_col),
        .out(out_col)
    );

    // Helper: pretty print a 32-bit column as four bytes
    task show_vec;
        input [31:0] v;
        begin
            $display("%02h %02h %02h %02h", v[31:24], v[23:16], v[15:8], v[7:0]);
        end
    endtask

    // Known-good GF(2^8) MixColumns example from FIPS-197:
    // Input column [db 13 53 45] -> Output [8e 4d a1 bc]
    // Note: The module declares in as {a0,a1,a2,a3} where a0 is the MSB byte.
    // We'll supply in_col = 32'hdb_13_53_45 and expect 32'h8e_4d_a1_bc.
    initial begin
        // Test 1: FIPS-197 example 1
        in_col = 32'hdb_13_53_45;
        #1;
        if (out_col !== 32'h8e_4d_a1_bc) begin
            $display("FAIL T1: got=");
            show_vec(out_col);
            $display(" exp=8e 4d a1 bc");
            $fatal;
        end else begin
            $display("PASS T1: FIPS column ok");
        end

        // Test 2: All ones -> remains all ones
        // Matrix*[01 01 01 01]^T = [01 01 01 01]^T
        in_col = {4{8'h01}}; // 32'h01_01_01_01
        #1;
        if (out_col !== {4{8'h01}}) begin
            $display("FAIL T2: got=");
            show_vec(out_col);
            $display(" exp=01 01 01 01");
            $fatal;
        end else begin
            $display("PASS T2: all-ones column ok");
        end

        // Test 3: All zeros -> all zeros
        in_col = 32'h00_00_00_00;
        #1;
        if (out_col !== 32'h00_00_00_00) begin
            $display("FAIL T3");
            $fatal;
        end else begin
            $display("PASS T3: all-zeros column ok");
        end

        $display("All mix_column tests passed.");
        $finish;
    end
endmodule
