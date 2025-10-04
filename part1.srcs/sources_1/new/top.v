module top(
   input       i_rx,
   input       clk,
   output      o_tx,
   input       rst
   );
   
   reg tx_start;
   wire rx_done;
   wire tx_done;
   wire tx_busy;
   reg [7:0] tx_byte;
   wire [7:0] rx_byte;   
   
   parameter integer baud = 115200;
   parameter integer clk_speed = 12_000_000;
   parameter integer clk_per_baud = clk_speed / baud;
   
        
        uart_tx #(.CLKS_PER_BIT(clk_per_baud)) U_TX (
        .i_Clock(clk),
        .i_Tx_DV(tx_start),
        .i_Tx_Byte(tx_byte),
        .o_Tx_Active(tx_busy),
        .o_Tx_Serial(o_tx),
        .o_Tx_Done(tx_done)
        );
        
        uart_rx #(.CLKS_PER_BIT(clk_per_baud)) U_RX (
        .i_Clock(clk),
        .i_Rx_Serial(i_rx),
        .o_Rx_DV(rx_done),
        .o_Rx_Byte(rx_byte)
    );
   

    localparam RST      = 3'b000,
               WAIT     = 3'b001,
               COMPUTE  = 3'b010,
               START_TX = 3'b011,
               WAIT_TX  = 3'b100,
               WAIT2    = 3'b101;
    reg [2:0] state;
    reg [3:0] a, b;
    wire cout;
    wire [3:0] sum;
    
    adder add(.a1(a), .a2(b), .c_in(1'b0), .s(sum), .c_out(cout));
    
    always @(posedge clk) begin
        if (rst) begin
            state <= RST;
        end else begin
        
            case (state)
                RST: begin
                    a             <= 4'b0;
                    b             <= 4'b0;
                    tx_byte       <= 8'b0;
                    tx_start      <= 1'b0;
                    state         <= WAIT;
                end
                
                WAIT: begin
                    if (rx_done) begin
                        a <= rx_byte[7:4];
                        b <= rx_byte[3:0];
                        state <= WAIT2;
                    end
                end
                
                WAIT2: begin
                    state <= COMPUTE;
                end
                
                COMPUTE: begin
                    tx_byte <= {3'b000, cout, sum};
                    state <= START_TX;
                end
                
                START_TX: begin
                    tx_start <= 1'b1;
                    state <= WAIT_TX;
                end
                
                WAIT_TX: begin
                    tx_start <= 1'b0;
                    if (tx_done == 1'b1) begin                    
                        state <= RST;
                    end
                end
            endcase
        end
    end
endmodule
   
   
module adder(
    input [3:0] a1,
    input [3:0] a2,
    input c_in,
    output [3:0] s,
    output c_out
    );
    
    assign {c_out, s} = a1 + a2 + c_in;
     
endmodule