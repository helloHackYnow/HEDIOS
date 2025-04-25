module serial_rx #(
    parameter clk_rate = 100_000_000,
    parameter baud_rate = 9_600,
    parameter data_bit_count = 8
    )(
    input clk,
    input rst,
    input rx,
    output reg[data_bit_count-1:0] o_data,
    output reg o_receiving,
    output reg o_done
    );
    
    localparam TICK_PER_BIT = clk_rate / baud_rate;
    
    
    reg[$clog2(TICK_PER_BIT)-1:0] clk_counter = 0;
    reg[$clog2(data_bit_count):0] received_bit_count = 0;
    
    
    
    // FSM
    localparam  IDLE = 3'b000,
                R_START = 3'b001,
                R_DATA = 3'b010,
                R_STOP = 3'b011,
                CLEAN = 3'b100;
                
    reg[2:0] sm_state = IDLE;
        
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin    
            o_receiving <= 0;
            o_done <= 0;
            o_data <= 0;
            clk_counter <= 0;
            received_bit_count <= 0;
            sm_state <= IDLE;
        end
        else begin    
            case(sm_state)
                
                IDLE : begin
                    clk_counter <= 0;
                    o_done <= 0;
                    received_bit_count <= 0;
                    if ( rx == 0 ) sm_state <= R_START; 
                end
                
                R_START : begin
                    o_receiving <= 1;
                    if (clk_counter < TICK_PER_BIT - 1) clk_counter <= clk_counter + 1;
                    else begin
                        clk_counter <= 0;
                        sm_state <= R_DATA;
                    end 
                end
                
                R_DATA : begin
                    o_receiving <= 1;
                    if ( received_bit_count < data_bit_count ) begin
                        if (clk_counter == TICK_PER_BIT >> 1) o_data <= {rx, o_data[data_bit_count-1:1]};
                        if (clk_counter < TICK_PER_BIT - 1) clk_counter <= clk_counter + 1;
                        else begin
                            received_bit_count <= received_bit_count + 1;
                            clk_counter <= 0;
                        end 
                    end
                    else begin
                        sm_state <= R_STOP;
                        clk_counter <= 0;
                    end 
                end
                
                R_STOP : begin
                    o_receiving <= 1;
                    if (clk_counter < TICK_PER_BIT - 1) clk_counter <= clk_counter + 1;
                    else begin
                        if (rx == 1) sm_state <= CLEAN; // valid stop bit
                        else sm_state <= IDLE; // framing error - discard
                    end
                end
                
                CLEAN : begin
                    o_receiving <= 0;
                    o_done <= 1;
                    clk_counter <= 0;
                    received_bit_count <= 0;
                    sm_state <= IDLE;
                end
            endcase
        end 
    end              
endmodule