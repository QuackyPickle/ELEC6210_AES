`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// DUT wrapper: one AES "round core" without AddRoundKey
// state_out = MixColumns( ShiftRows( SubBytes(state_in) ) )
// -----------------------------------------------------------------------------
module round_chain (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    // SubBytes: 16 parallel S-boxes, byte-wise
    wire [127:0] subbytes_out;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : G_SBOX
            wire [7:0] in_b  = state_in[127 - 8*i -: 8];
            wire [7:0] out_b;
            s_box u_sbox (.in_byte(in_b), .out_byte(out_b));
            assign subbytes_out[127 - 8*i -: 8] = out_b;
        end
    endgenerate

    // ShiftRows
    wire [127:0] sr_out;
    shift_rows U_SR (.in(subbytes_out), .out(sr_out));

    // MixColumns (128-bit variant that applies mix_column per 32-bit column)
    wire [127:0] mc_out;
    mix_columns U_MC (.in(sr_out), .out(mc_out));

    assign state_out = mc_out;
endmodule

// -----------------------------------------------------------------------------
// Testbench
// -----------------------------------------------------------------------------
module tb_all_together;
    // No clock required: the chain is purely combinational
    reg  [127:0] in_state;
    wire [127:0] out_state;

    // DUT: only the three transforms
    round_chain DUT (
        .state_in(in_state),
        .state_out(out_state)
    );

    // Pretty-print a 128-bit state as 16 bytes
    task show_state;
        input [127:0] s;
        begin
            $display("%02h %02h %02h %02h  %02h %02h %02h %02h  %02h %02h %02h %02h  %02h %02h %02h %02h",
                     s[127:120], s[119:112], s[111:104], s[103:96],
                     s[95:88],   s[87:80],   s[79:72],   s[71:64],
                     s[63:56],   s[55:48],   s[47:40],   s[39:32],
                     s[31:24],   s[23:16],   s[15:8],    s[7:0]);
        end
    endtask

    // Simple "not-X" check
    task assert_no_x;
        input [127:0] v;
        input [127:0] exp_mask;
        begin
            if ((^v) === 1'bx) begin
                $display("FAIL: X detected in vector!");
                $fatal;
            end
        end
    endtask

    initial begin
        $display("==== tb_top (SubBytes -> ShiftRows -> MixColumns) ====");

        // Test 1: byte ramp
        in_state = 128'h00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F;
        #1;
        $display("T1 in :"); show_state(in_state);
        $display("T1 out:"); show_state(out_state);
        assert_no_x(out_state, 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF);

        // Test 2: FIPS-like pattern (used in many AES examples)
        in_state = 128'hD4_E0_B8_1E_BF_B4_41_27_5D_52_11_98_30_AE_F1_E5;
        #1;
        $display("T2 in :"); show_state(in_state);
        $display("T2 out:"); show_state(out_state);
        assert_no_x(out_state, 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF);

        // Test 3: all equal bytes
        in_state = {16{8'hAA}};
        #1;
        $display("T3 in :"); show_state(in_state);
        $display("T3 out:"); show_state(out_state);
        assert_no_x(out_state, 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF);

        $display("tb_top completed (visual check).");
        $finish;
    end
endmodule
