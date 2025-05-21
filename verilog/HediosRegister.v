// Register with synchronous reset

module HediosRegister#(parameter DEPTH = 8)(
    input clk,
    input rst,

    input[DEPTH-1:0] hedios_in,
    input hedios_we,

    input[DEPTH-1:0] user_in,
    input user_we,

    output[DEPTH-1:0] out,
    output reg race_condition
);

reg[DEPTH-1:0] memory;

always @(clk) begin
    if (rst) begin
        memory <= {DEPTH{1'b0}};
        race_condition <= 0;
    end

    else begin
        
        race_condition <= 0;

        case({hedios_we, user_we})
            
            
            2'b00 : ; // Do nothing

            2'b10 : memory <= hedios_in;

            2'b01 : memory <= user_in;

            default : begin
                memory <= user_in;
                race_condition <= 1;
            end

        endcase
        
    end
end

assign out = memory;

    
endmodule
