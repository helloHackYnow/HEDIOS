module HediosController #(
    parameter SLOT_COUNT = 0, 
    parameter VAR_ACTION_COUNT = 0, 
    parameter VARLESS_ACTION_COUNT = 0)
    (
    input clk,
    input rst,
    
    // Hedios serial rx
    input rx_empty,
    input rx_full,
    input rx_lost_data, // (TODO : implement )
    input[7:0] rx_command,
    input[31:0] rx_data,
    output reg rx_pop_packet,

    // Hedios serial tx
    input tx_empty,
    input tx_full,
    output reg [7:0] tx_command,
    output reg [31:0] tx_data,
    output reg tx_push_packet,

    output reg rst_device,

    // Hedios slot (TODO : write documentation for a hedios slot)
    input[SLOT_COUNT-1:0][31:0] slots,

    // Hedios action
    /*
    An hedios action can be of two type :
        - an action with a 32-bit parameter (VAR_ACTION)
        - an simpler action, without any parameter (VARLESS_ACTION)
        
    To toggle an action, the hedios client send the command 0b1pxxxxxx
    If p is high, the action is an action with parameter, else it's a simple action
    The 6 last bits are the action id, which allows for 64 actions of each type.

    If the action is a VAR_ACTION, the packet data contains the 32-bits parameter

    When an action idx is received, the HediosController sends a one tick pulse on var_actions[idx]
    The module HediosActionHandler, instanciated in the HediosEndpoint, toogle on this pulse an output.
    This output can be toggled back by the fpga logic upon completion of the action

    The var_action_parameter[VAR_ACTION_COUNT-1:0][31:0] is directly exposed through the HediosEndpoint to exterior logic
     */
    output reg [VAR_ACTION_COUNT-1:0] var_actions,
    output reg [VAR_ACTION_COUNT-1:0][31:0] var_action_parameter ,
    output reg [VARLESS_ACTION_COUNT-1:0] varless_actions

);

    // Command sent by the client
    localparam  C_PING = 8'h01,
                C_UPDATE_SLOT = 8'h02, // The slot id to update is given by the 7 low bits of the packet data
                C_UPDATE_ALL_SLOT = 8'h03,
                C_ASK_SLOT_COUNT = 8'h04,
                C_ASK_ACTION_COUNT = 8'h05,
                C_RESET = 8'b01010101;

    // Command sent by the endpoint
    localparam  HDC_PING            = 8'h01,
                HDC_DONE            = 8'h02,
                HDC_PONG            = 8'h03,
                HDC_LOG             = 8'h04,
                HDC_SLOT_COUNT      = 8'h05,
                HDC_ACTION_COUNT    = 8'h06,
                HDC_ERROR           = 8'h08,
                HDC_INVALID_SLOT    = 8'h09,
                HDC_INVALID_ACTION  = 8'h0a,
                HDC_UNKNOWN_COMMAND = 8'h0b;
                

    
    

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

    wire[7:0] var_action_count = VAR_ACTION_COUNT;
    wire [7:0] varless_action_count = VARLESS_ACTION_COUNT;

    integer i;
    

    always @(posedge clk or posedge rst) begin // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
        if (rst) begin
            sm_state         <= IDLE;
            slot_counter        <= 0;
            rx_pop_packet       <= 0;
            tx_push_packet      <= 0;
            tx_command          <= 0;
            tx_data             <= 0;
            rst_device          <= 0;
            var_actions         <= 0;
            varless_actions     <= 0;
            for (i = 0; i < VAR_ACTION_COUNT; i  = i + 1) begin
                var_action_parameter[i] <= 0;
            end
            
        end

        else begin

            rx_pop_packet   <= 0;
            tx_push_packet  <= 0;
            rst_device      <= 0;
            var_actions     <= 0;
            varless_actions <= 0;

            
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

                    // HediosAction handling
                    if (rx_command[7]) begin // Check if the packet is an HediosAction packet

                        if (rx_command[6]) begin // Check if it's a var action
                            var_actions[rx_command[5:0]] <= 1;
                            var_action_parameter[rx_command[5:0]] <= rx_data;
                        end
                        else varless_actions[rx_command[5:0]] <= 1;

                        sm_state <= IDLE;
                        
                    end else begin

                    case (rx_command)

                        C_PING : begin
                            sm_state <= CLEAN_EARLY;
                            tx_command <= HDC_PONG;
                            tx_push_packet <= 1;
                        end

                        C_UPDATE_SLOT : begin
                            sm_state <= CLEAN_EARLY;
                            
                            if (fst_byte >= SLOT_COUNT) begin
                                tx_command <= HDC_INVALID_SLOT;
                                
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
                            tx_command <= HDC_SLOT_COUNT; // HDC_SLOT_COUNT
                            tx_data <= {24'b0, SLOT_COUNT};
                            tx_push_packet <= 1;
                            sm_state <= CLEAN_EARLY;
                        end

                        C_ASK_ACTION_COUNT : begin
                            tx_command <= HDC_ACTION_COUNT;
                            tx_data <= {16'b0, varless_action_count, var_action_count};
                            tx_push_packet <= 1;
                            sm_state <= CLEAN_EARLY;
                        end

                        C_RESET : begin
                            rst_device <= 1;
                            sm_state <= CLEAN_EARLY;
                        end

                        default : begin
                            tx_command <= HDC_UNKNOWN_COMMAND; // HDC_UNKNOWN_COMMAND
                            tx_push_packet <= 1;
                            sm_state <= CLEAN_EARLY;
                        end
                    endcase
                end end

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
