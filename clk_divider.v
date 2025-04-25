module clk_divider #(parameter divider = 8)(
    input clk,
    input rst,
    output reg out
    );
    
    localparam half_clk = divider >> 1;
    reg[$clog2(half_clk):0] clk_counter = 0;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin 
            clk_counter <= 0; 
            out <= 0; 
        end else if (clk_counter == half_clk-1) begin
            clk_counter <= 0;
            out <= ~out;
        end else clk_counter <= clk_counter + 1;
    end   
endmodule
