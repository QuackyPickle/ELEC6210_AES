module top(
   input       i_rx,
   input       clk,
   output      o_tx,
   input       rst
   );

    wire        rx_valid;
    wire        tx_done;
    wire        tx_busy;
    wire        rx_busy;
    reg  [2:0]  state;
    reg         start_tx;

    wire  [255:0] my_256bit_bus;
    reg  [127:0] my_128bit_bus;
    reg  [255:0] bus_256;
    reg  [127:0] out_bus_1;
    reg  [127:0] out_bus_2;

    uart_sm #(.BAUD(115200), .CLK_SPEED(12_000_000)) UART_LINK (
        .clk(clk),
        .reset(rst),
        .i_rx(i_rx),
        .o_tx(o_tx),
        .tx_start(start_tx),
        .tx_done(tx_done),
        .tx_busy(tx_busy),
        .rx_busy(rx_busy),
        .rx_done_really(rx_valid),
        .rx_words(my_256bit_bus),
        .tx_words(my_128bit_bus)
    );

    localparam RST      = 3'b000,
               WAIT     = 3'b001,
               COMPUTE  = 3'b010,
               START_TX = 3'b011,
               WAIT_TX1 = 3'b100,
               START_TX2= 3'b101,
               WAIT_TX2 = 3'b110;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= WAIT;
            start_tx    <= 1'b0;
            bus_256     <= 256'b0;
            out_bus_1   <= 128'b0;
            out_bus_2   <= 128'b0;
            my_128bit_bus <= 128'b0;
        end else begin
            case (state)
                WAIT: begin
                    start_tx <= 1'b0;
                    if (rx_valid) begin
                        bus_256 <= my_256bit_bus;
                        state   <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    out_bus_1      <= my_256bit_bus[255:128];
                    out_bus_2      <= my_256bit_bus[127:0];
                    my_128bit_bus  <= my_256bit_bus[255:128];
                    start_tx       <= 1'b1;    // pulse start
                    state          <= START_TX;
                end

                START_TX: begin
                    start_tx <= 1'b0;          // pulse done
                    if (tx_done)               // first TX done
                        state <= WAIT_TX1;
                end

                WAIT_TX1: begin
                    if (!tx_done && !tx_busy) begin
                        my_128bit_bus <= out_bus_2; // next half
                        start_tx      <= 1'b1;      // pulse start again
                        state         <= START_TX2;
                    end
                end

                START_TX2: begin
                    start_tx <= 1'b0;
                    if (tx_done)
                        state <= WAIT_TX2;
                end

                WAIT_TX2: begin
                    if (!tx_done && !tx_busy)
                        state <= WAIT;
                end
            endcase
        end
    end
endmodule
