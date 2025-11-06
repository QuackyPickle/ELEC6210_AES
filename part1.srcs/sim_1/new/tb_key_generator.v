`timescale 1ns/1ps

module tb_key_generator;

    // DUT inputs/outputs
    reg  [127:0] key_in;
    wire [127:0] k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;

    // Instantiate Device Under Test
    key_generator dut (
        .key_in(key_in),
        .k0(k0), .k1(k1), .k2(k2), .k3(k3), .k4(k4),
        .k5(k5), .k6(k6), .k7(k7), .k8(k8), .k9(k9), .k10(k10)
    );

    // Expected round keys for AES-128 with key:
    // 2b7e151628aed2a6abf7158809cf4f3c
    localparam [127:0] EXP_K0  = 128'h2b7e1516_28aed2a6_abf71588_09cf4f3c;
    localparam [127:0] EXP_K1  = 128'ha0fafe17_88542cb1_23a33939_2a6c7605;
    localparam [127:0] EXP_K2  = 128'hf2c295f2_7a96b943_5935807a_7359f67f;
    localparam [127:0] EXP_K3  = 128'h3d80477d_4716fe3e_1e237e44_6d7a883b;
    localparam [127:0] EXP_K4  = 128'hef44a541_a8525b7f_b671253b_db0bad00;
    localparam [127:0] EXP_K5  = 128'hd4d1c6f8_7c839d87_caf2b8bc_11f915bc;
    localparam [127:0] EXP_K6  = 128'h6d88a37a_110b3efd_dbf98641_ca0093fd;
    localparam [127:0] EXP_K7  = 128'h4e54f70e_5f5fc9f3_84a64fb2_4ea6dc4f;
    localparam [127:0] EXP_K8  = 128'head27321_b58dbad2_312bf560_7f8d292f;
    localparam [127:0] EXP_K9  = 128'hac7766f3_19fadc21_28d12941_575c006e;
    localparam [127:0] EXP_K10 = 128'hd014f9a8_c9ee2589_e13f0cc8_b6630ca6;

    integer errors;

    // Simple compare task to reduce boilerplate
    task check_eq;
        input [127:0] got;
        input [127:0] exp;
        input [8*8:1] name; // small string literal like "k0"
    begin
        if (got !== exp) begin
            errors = errors + 1;
            $display("[%0t] ERROR: %s mismatch", $time, name);
            $display("        Got: %032h", got);
            $display("        Exp: %032h", exp);
        end else begin
            $display("[%0t] OK   : %s = %032h", $time, name, got);
        end
    end
    endtask

    initial begin
        errors = 0;

        // Drive the canonical AES-128 key
        key_in = 128'h2b7e1516_28aed2a6_abf71588_09cf4f3c;

        // Wait a delta cycle for combinational propagation
        #1;

        // Check all round keys
        check_eq(k0 , EXP_K0 , "k0" );
        check_eq(k1 , EXP_K1 , "k1" );
        check_eq(k2 , EXP_K2 , "k2" );
        check_eq(k3 , EXP_K3 , "k3" );
        check_eq(k4 , EXP_K4 , "k4" );
        check_eq(k5 , EXP_K5 , "k5" );
        check_eq(k6 , EXP_K6 , "k6" );
        check_eq(k7 , EXP_K7 , "k7" );
        check_eq(k8 , EXP_K8 , "k8" );
        check_eq(k9 , EXP_K9 , "k9" );
        check_eq(k10, EXP_K10, "k10");

        // Final report
        if (errors == 0) begin
            $display("------------------------------------------------------------");
            $display("ALL TESTS PASSED: key_generator matches FIPS-197 (AES-128).");
            $display("------------------------------------------------------------");
        end else begin
            $display("------------------------------------------------------------");
            $display("TESTS FAILED: %0d mismatches detected.", errors);
            $display("------------------------------------------------------------");
        end

        // End simulation
        #5;
        $finish;
    end

endmodule