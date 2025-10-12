module adder_testbench;
    reg  [3:0] a1;
    reg  [3:0] a2;
    reg        c_in;
    wire [3:0] s;
    wire       c_out;

    adder add (
        .a1(a1),
        .a2(a2),
        .c_in(c_in),
        .s(s),
        .c_out(c_out)
    );

    integer i;
    integer j;
    integer k;
    integer errors = 0;

    initial begin
        a1 = 0; a2 = 0; c_in = 0;
        #5;

        // Exhaustive test over all 4-bit inputs and carry-in (16*16*2 = 512 cases)
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    a1   = i[3:0];
                    a2   = j[3:0];
                    c_in = k[0];
                    #1; // allow combinational logic to settle
                    
                    $display("Test: %0d + %0d + %0d = %0d", i, j, k, {c_out, s});
                    
                    if ({c_out, s} !== (i + j + k)) begin
                        $display("ERROR: a1 = %0d (0x%0h) a2 = %0d (0x%0h) c_in = %0d -> got {c_out, s} = %b_%04b expected = %05b", i, i, j, j, k, c_out, s, (i + j + k));
                        errors = errors + 1;
                    end
                end
            end
        end

        if (errors == 0)
            $display("All tests passed!");
        else
            $display("Completed with %0d errors.", errors);

        $finish;
    end
endmodule
