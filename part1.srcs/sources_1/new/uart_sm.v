module uart_sm
    #(parameter BAUD = 115200,
      parameter CLK_SPEED = 12_000_000)
    (
        input  wire clk,
        input  wire reset,

        // UART serial I/O
        input  wire i_rx,
        output wire o_tx,

        // Control I/O
        input  wire tx_start,
        input  wire [127:0] tx_words,
        output reg  [255:0] rx_words,

        output reg  tx_done,       // high for one cycle when done sending 16 bytes
        output reg  rx_done_really,// high when 32 bytes received
        output reg  tx_busy,
        output reg  rx_busy
    );

    // ----------------------------------------
    // UART submodules
    // ----------------------------------------
    localparam integer CLKS_PER_BIT = CLK_SPEED / BAUD;

    wire rx_dv;
    wire [7:0] rx_byte;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) U_RX (
        .i_Clock(clk),
        .i_Rx_Serial(i_rx),
        .o_Rx_DV(rx_dv),
        .o_Rx_Byte(rx_byte)
    );

    reg        tx_dv;
    reg [7:0]  tx_byte;
    wire       tx_active;
    wire       tx_done_byte;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) U_TX (
        .i_Clock(clk),
        .i_Tx_DV(tx_dv),
        .i_Tx_Byte(tx_byte),
        .o_Tx_Active(tx_active),
        .o_Tx_Serial(o_tx),
        .o_Tx_Done(tx_done_byte)
    );

    // ----------------------------------------
    // RX STATE MACHINE
    // ----------------------------------------
    reg [7:0] rx_count;
    reg [1:0] rx_state;

    localparam [1:0]
        RX_WAIT  = 2'b00,
        RX_RECV  = 2'b01,
        RX_DONE  = 2'b10;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_state        <= RX_WAIT;
            rx_count        <= 0;
            rx_words        <= 0;
            rx_done_really  <= 0;
            rx_busy         <= 0;
        end else begin
            case (rx_state)
                RX_WAIT: begin
                    rx_done_really <= 1'b0;
                    rx_busy        <= 1'b0;
                    rx_count       <= 0;
                    if (rx_dv) begin
                        rx_busy  <= 1'b1;
                        rx_words <= {rx_words[247:0], rx_byte};
                        rx_count <= 1;
                        rx_state <= RX_RECV;
                    end
                end

                RX_RECV: begin
                    if (rx_dv) begin
                        rx_words <= {rx_words[247:0], rx_byte};
                        rx_count <= rx_count + 1'b1;
                        if (rx_count == 8'd31)
                            rx_state <= RX_DONE;
                    end
                end

                RX_DONE: begin
                    rx_done_really <= 1'b1;
                    rx_busy        <= 1'b0;
                    rx_state       <= RX_WAIT;
                end
            endcase
        end
    end

    // ----------------------------------------
    // TX STATE MACHINE
    // ----------------------------------------
    reg [127:0] tx_shift;
    reg [4:0]   tx_count;
    reg [1:0]   tx_state;

    localparam [1:0]
        TX_IDLE      = 2'b00,
        TX_SENDING   = 2'b01,
        TX_DONE      = 2'b10,
        TX_WAIT_IDLE = 2'b11;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_state  <= TX_IDLE;
            tx_dv     <= 1'b0;
            tx_byte   <= 8'd0;
            tx_shift  <= 128'd0;
            tx_count  <= 5'd0;
            tx_done   <= 1'b0;
            tx_busy   <= 1'b0;
        end else begin
            case (tx_state)
                //---------------------------------
                TX_IDLE: begin
                    tx_done  <= 1'b0;
                    tx_busy  <= 1'b0;
                    tx_dv    <= 1'b0;
                    tx_count <= 0;
    
                    if (tx_start) begin
                        tx_shift <= tx_words;
                        tx_byte  <= tx_words[127:120];  // top byte first
                        tx_dv    <= 1'b1;
                        tx_busy  <= 1'b1;
                        tx_state <= TX_SENDING;
                    end
                end
    
                //---------------------------------
                TX_SENDING: begin
                    tx_dv <= 1'b0;
    
                    if (tx_done_byte) begin
                        // just finished a byte
                        tx_count <= tx_count + 1'b1;
    
                        if (tx_count == 5'd15) begin // tx 16 bytes total
                            tx_state <= TX_DONE;
                        end else begin
                            tx_shift <= {tx_shift[119:0], 8'd0};
                            tx_byte  <= tx_shift[119:112];
                            // wait for transmitter to become idle
                            tx_state <= TX_WAIT_IDLE;
                        end
                    end
                end
    
                //---------------------------------
                TX_WAIT_IDLE: begin
                    tx_dv <= 1'b0;
                    // don't start next byte until UART TX is idle
                    if (!tx_active) begin
                        tx_dv    <= 1'b1;      // pulse start for next byte
                        tx_state <= TX_SENDING; // back to sending
                    end
                end
    
                //---------------------------------
                TX_DONE: begin
                    tx_done <= 1'b1;
                    tx_busy <= 1'b0;
                    tx_state <= TX_IDLE;
                end
            endcase
        end
    end


endmodule
