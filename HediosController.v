module HediosController #(parameter SLOT_COUNT = 0, parameter ACTION_COUNT = 0)
    (
    input clk,
    input rst,
    
    // Hedios serial rx
    input rx_empty,
    input rx_full,
    input rx_lost_data,
    input[7:0] rx_command,
    input[31:0] rx_data,
    output reg rx_pop_packet,

    // Hedios serial tx
    input tx_empty,
    input tx_full,
    output reg [7:0] tx_command,
    output reg [31:0] tx_data,
    output reg tx_push_packet,

    // Hedios action
    input send_ping,
    input[SLOT_COUNT-1:0][31:0] slots,
    output reg rst_device,
    output reg [ACTION_COUNT-1:0] configurable_actions,
    output reg [31:0] action_argument,

    output reg [7:0] last_command

);

    // Command sent by the client
    localparam  C_PING = 8'h01,
                C_UPDATE_SLOT = 8'h02, // The slot id to update is given by the 7 low bits of the packet data
                C_UPDATE_ALL_SLOT = 8'h03,
                C_ASK_SLOT_COUNT = 8'h04,
                C_RESET = 8'b10101010;
    

    // FSM states
    localparam  IDLE = 5'b00000,
                POP_PACKET = 5'b00011,
                DECODE_PACKET = 5'b00001,
                PUSH_PACKET = 5'b00100,
                CLEAN_EARLY = 5'b00101,
                EXEC_UPDATE_ALL_SLOT = 5'b00110,
                WAIT_BTWN_SLOTS = 5'b00111,
                CLEAN = 5'b11111;

    reg[4:0] sm_state;
    reg[7:0] slot_counter;
    wire[7:0] fst_byte = rx_data[7:0];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sm_state         <= IDLE;
            slot_counter        <= 0;
            rx_pop_packet       <= 0;
            tx_push_packet      <= 0;
            tx_command          <= 0;
            tx_data             <= 0;
            rst_device          <= 0;
            configurable_actions<= 0;
            action_argument     <= 0;
            last_command        <= 0;
        end

        else begin

            rx_pop_packet   <= 0;
            tx_push_packet  <= 0;
            rst_device      <= 0;

            
            case (sm_state)
                IDLE : begin
                    tx_data <= 0;
                    tx_command <= 0;
                    if (~rx_empty) begin
                        sm_state <= POP_PACKET;
                        rx_pop_packet <= 1;
                    end
                end

                POP_PACKET : begin
                    rx_pop_packet <= 0;
                    
                    sm_state <= DECODE_PACKET;
                end

                DECODE_PACKET : begin

                    last_command <= rx_command;
                    case (rx_command)

                        C_PING : begin
                            sm_state <= CLEAN_EARLY;
                            tx_command <= 8'b00000011; // Send a pong HDC_PONG
                            tx_push_packet <= 1;
                        end

                        C_UPDATE_SLOT : begin
                            sm_state <= CLEAN_EARLY;
                            
                            if (fst_byte >= SLOT_COUNT) begin
                                tx_command <= 8'b00001001; // Send invalid slot HDC_INVALID_SLOT
                                
                            end else begin
                                tx_command <= {1, fst_byte[6:0]}; // Send an update slot, with slot id (HDC_UPDATE_VALUE)
                                tx_data <= slots[fst_byte];
                            end
                            tx_push_packet <= 1;

                            
                        end

                        C_UPDATE_ALL_SLOT : begin
                            sm_state <= EXEC_UPDATE_ALL_SLOT;
                            slot_counter <= 0;
                        end

                        C_ASK_SLOT_COUNT : begin
                            tx_command <= 8'b00000101; // HDC_SLOT_COUNT
                            tx_data <= {24'b0, SLOT_COUNT};
                            tx_push_packet <= 1;
                            sm_state <= CLEAN_EARLY;
                        end

                        C_RESET : begin
                            rst_device <= 1;
                            sm_state <= CLEAN_EARLY;
                        end

                        default : begin
                            tx_command <= 8'b00001100; // HDC_UNKNOWN_COMMAND
                            tx_push_packet <= 1;
                            sm_state <= CLEAN_EARLY;
                        end
                    endcase
                end

                CLEAN_EARLY : begin
                    tx_push_packet <= 0;
                    sm_state <= IDLE;
                end

                EXEC_UPDATE_ALL_SLOT : begin

                    // Exit if all the slot have been updated
                    if (slot_counter >= SLOT_COUNT) begin
                        sm_state <= CLEAN;

                    end
                    else begin
                        // Send a packet if the queue not filled
                        if (!rx_full && !tx_push_packet) begin
                            tx_push_packet <= 1;
                            tx_command <= {1, slot_counter[6:0]};
                            last_command <= {1, slot_counter[6:0]};
                            tx_data <= slots[slot_counter];
                            slot_counter <= slot_counter + 1;
                            sm_state <= WAIT_BTWN_SLOTS;
                        end
                    end
                end

                WAIT_BTWN_SLOTS : begin
                    sm_state <= EXEC_UPDATE_ALL_SLOT;
                end

                CLEAN : begin
                    sm_state <= IDLE;
                    tx_push_packet <= 0;
                end

                default : begin
                    sm_state <= IDLE;
                end 

            endcase
            
        end
    end
    
endmodule
