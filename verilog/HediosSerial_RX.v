module HediosSerial_RX
    #(
        parameter CLK_RATE = 100_000_000,
        parameter BAUD_RATE = 1_000_000
    )(
    input clk,
    input rst,

    input rx_line,

    input pop_packet,
    output[7:0] packet_command,
    output[31:0] packet_data,

    output queue_full,
    output reg lost_data,
    output queue_empty

);

    // fsm state
    localparam  IDLE = 3'b000,
                RECEIVING = 3'b001,
                PUSH = 3'b010,
                LOST_ERROR = 3'b011;
    

    reg fifo_push;
    wire[7:0] fifo_in_command;
    wire[31:0] fifo_in_data;
    wire fifo_full;
    wire fifo_empty;

    wire rx_receiving;
    wire rx_done;
    wire[7:0] rx_data;


    reg[2:0] sm_state;


    // TODO : implement checking the validity of the received packet
    // Maybe the fpga could send as data the received command to assert reception
    reg[39:0] current_data;
    reg[2:0] received_bytes;


    HediosFIFO #(
        .max_capacity(16)
    ) HediosFIFO_instance (
        .clk(clk),
        .rst(rst),
        .push_packet(fifo_push),
        .i_packet_command(fifo_in_command),
        .i_packet_data(fifo_in_data),
        .pop_packet(pop_packet),
        .o_packet_command(packet_command),
        .o_packet_data(packet_data),
        .empty(fifo_empty),
        .full(fifo_full)
    );

    serial_rx #(
        .clk_rate(CLK_RATE),
        .baud_rate(BAUD_RATE),
        .data_bit_count(8)
    ) serial_rx_instance (
        .clk(clk),
        .rst(rst),
        .rx(rx_line),
        .o_data(rx_data),
        .o_receiving(rx_receiving),
        .o_done(rx_done)
    );



    always @(posedge clk or posedge rst) begin // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
        if (rst) begin
            sm_state <= IDLE;
            received_bytes <= 0;
            fifo_push <= 0;
            lost_data <= 0;
        end

        else begin
            fifo_push <= 0;
            lost_data <= 0;
            case (sm_state)
                IDLE : begin
                    received_bytes <= 0;
                    if (rx_receiving) begin
                        sm_state <= RECEIVING;
                    end
                end

                RECEIVING : begin
                    if (received_bytes >= 5) begin
                        sm_state <= PUSH;
                    end
                    else if (rx_done) begin
                        current_data <= {rx_data, current_data[39:8]};
                        received_bytes <= received_bytes + 1;
                    end
                end

                PUSH : begin
                    if (fifo_full) begin
                        sm_state <= LOST_ERROR;
                    end
                    else begin
                        fifo_push <= 1;
                        sm_state <= IDLE;
                    end
                end

                LOST_ERROR : begin
                    lost_data <= 1;
                    sm_state <= IDLE;
                end
            endcase
        end
    end

    assign fifo_in_command = current_data[7:0];
    assign fifo_in_data = current_data[39:8];
    assign queue_full = fifo_full;
    assign queue_empty = fifo_empty;
    
    
    
endmodule
