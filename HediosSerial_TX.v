module HediosSerial_TX #(parameter BAUD_RATE = 1_000_000) (
    input clk,
    input rst,

    input[7:0] packet_command,
    input[31:0] packet_data,
    input push_packet,

    output queue_full,
    output queue_empty,
    output tx_line
);

    localparam  IDLE = 3'b000,
                START_PACKET = 3'b001,
                SENDING_PACKET = 3'b010,
                WAITING_BTWN_PACKET = 3'b011;

    wire[7:0] tx_data;
    wire tx_command;
    wire tx_busy;
    wire tx_done;

    wire str_busy;
    wire str_done;
    reg str_command;

    reg fifo_pop;
    wire[7:0] fifo_command_out;
    wire[31:0] fifo_data_out;
    wire fifo_empty;
    wire fifo_full;
    
    reg[2:0] sm_state;

    HediosFIFO #(
        .max_capacity(8)
    ) HediosFIFO_instance (
        .clk(clk),
        .rst(rst),
        .push_packet(push_packet),
        .i_packet_command(packet_command),
        .i_packet_data(packet_data),
        .pop_packet(fifo_pop),
        .o_packet_command(fifo_command_out),
        .o_packet_data(fifo_data_out),
        .empty(fifo_empty),
        .full(fifo_full)
    );  

    serial_str #(
        .max_m_len(5)
    ) serial_str_instance (
        .clk(clk),
        .rst(rst),
        .command(str_command),
        .message({fifo_data_out, fifo_command_out}),
        .len(5),
        .tx_data(tx_data),
        .tx_start(tx_command),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .busy(str_busy),
        .done(str_done)
    );

    serial_tx #(
        .clk_rate(100_000_000),
        .baud_rate(BAUD_RATE),
        .data_bit_count(8)
    ) serial_tx_instance (
        .clk(clk),
        .i_data(tx_data),
        .i_start(tx_command),
        .rst(rst),
        .tx(tx_line),
        .o_active(tx_busy),
        .o_done(tx_done)
    );

    always @(posedge clk) begin // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
        if(rst) begin
            sm_state <= IDLE;
            fifo_pop     <= 0;
            str_command  <= 0;
        end
        else begin

            fifo_pop    <= 1'b0;
            str_command <= 1'b0;
            case (sm_state)

                IDLE : begin
                    str_command <= 0;
                    if(~fifo_empty) begin
                        sm_state <= START_PACKET;
                        fifo_pop <= 1;
                    end
                end

                START_PACKET : begin
                    if (~str_busy) begin
                        str_command <= 1;
                        sm_state <= SENDING_PACKET;
                    end               
                end
                SENDING_PACKET : begin
                    if (~str_busy) begin
                        sm_state <= WAITING_BTWN_PACKET;
                    end
                end   

                WAITING_BTWN_PACKET : begin
                    sm_state <= IDLE;
                end
                
                default : sm_state <= IDLE;
            endcase
            
        end
    end
    

    assign queue_empty = fifo_empty;
    assign queue_full = fifo_full;
    
endmodule