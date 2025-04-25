module display(
        input clk, 
        input[15:0] in,
        output reg [3:0] io_select,
        output[7:0] io_segment
    );
    
    reg[14:0] counter;
    reg[1:0] selected;
    reg[3:0] current_digit;
    
    m_hex_decoder decoder(.in(current_digit), .out(io_segment));
    
    always @ (posedge clk) begin
        if (counter[14]) begin
            counter[14:0] <= 15'b0;
            selected <= selected + 1;
        end
        else begin 
            counter <= counter + 1;
        end
    end
    
         
    always @ (selected) begin
        case(selected)
            2'b00 : begin 
                io_select = 4'b1110; 
                current_digit <= in[3:0];
                end
                
            2'b01 : begin 
                io_select = 4'b1101; 
                current_digit <= in[7:4];
                end
                
            2'b10 : begin 
                io_select = 4'b1011; 
                current_digit <= in[11:8];
                end
                
            2'b11 : begin 
                io_select = 4'b0111; 
                current_digit <= in[15:12];
                end
                
            default : begin 
                io_select = 4'b1111; 
                end
        endcase 
    end
endmodule
