module serial_str#(
    parameter max_m_len = 32
    )
    (
        input clk,
        input rst,
        input command,
        input[max_m_len*8-1:0] message,
        input[$clog2(max_m_len):0] len,
        
        // The serial transmetter ctrl
        output reg[7:0] tx_data,
        output reg tx_start,
        input tx_busy,
        input tx_done,
        
        // State of the module
        output reg busy,
        output reg done
    );
    
    // FSM
    localparam IDLE         = 3'b000,
               INIT         = 3'b001,
               START_PACKET = 3'b010,
               SENDING      = 3'b011,
               END_PACKET   = 3'b100;
    
    integer i;

    reg[$clog2(max_m_len):0] sent_packet_c = 0; // Counter
    reg[2:0] sm_state = IDLE;
    
    reg [8*max_m_len - 1:0] m_message;
    reg[$clog2(max_m_len):0] m_len = 0;
    
    
    always @ (posedge clk or posedge rst) begin // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
        if(rst) begin // Reset block
            tx_data <= 0;
            tx_start <= 0;
            done <= 0;
            sent_packet_c <= 0;
            m_message <= 0;
            m_len <= 0;
            busy <= 0;
            sm_state <= IDLE;
        end
        
        else begin 
            case(sm_state) // FSM processing
                IDLE : begin
                    done <= 0;
                    busy <= 0;
                    tx_start <= 0;
                    if(command) begin
                        sm_state <= INIT;
                    end
                end
                
                
                INIT : begin
                    busy <= 1;
                    sent_packet_c <= 0;
                    sm_state <= START_PACKET;
                    m_message <= message;
                    m_len <= len;
                end
                
                
                START_PACKET : begin              
                    if (sent_packet_c < m_len) begin
                        
                        if (~tx_busy) begin // Wait for the serial transmetter to be begin
                            tx_data <= m_message[7:0];
                            tx_start <= 1;
                            sm_state <= SENDING;
                        end else begin sm_state <= START_PACKET; end
                        
                    end else begin
                        done <= 1;
                        sm_state <= IDLE;
                    end
                end
                
                
                SENDING : begin
                    if(~tx_busy) sm_state <= END_PACKET;
                    else sm_state <= SENDING;
                    tx_start <= 0;
                end
                
                
                END_PACKET : begin
                    sent_packet_c <= sent_packet_c + 1;
                    m_message <= {8'b0, m_message[(max_m_len*8)-1:8]};
                    sm_state <= START_PACKET;
                end
            endcase   
        end 
    end          
endmodule
