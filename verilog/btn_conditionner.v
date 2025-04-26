`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2025 09:40:23 AM
// Design Name: 
// Module Name: btn_conditionner
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module btn_conditionner #(
    parameter integer STAGES = 4  // Number of debouncing stages
)(
    input  wire              clk,  // Clock input
    input  wire              in,   // Raw button input (active high)
    output reg               out   // Debounced output
);

    // Shift register for filtering: each bit is one stage
    reg [STAGES-1:0] stage_q;

    // Initialize shift register to all ones
    initial begin
        stage_q = {STAGES{1'b1}};
    end

    always @(posedge clk) begin // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
        if (in) begin
            // If button is high, reset all stages to 1
            stage_q <= {STAGES{1'b1}};
        end else begin
            // Otherwise shift in a 0, dropping the oldest bit
            stage_q <= {stage_q[STAGES-2:0], 1'b0};
        end
        // Output is the MSB: remains high until STAGES cycles of low in
        out <= stage_q[STAGES-1];
    end

endmodule
