module HediosActionHandler #(
    parameter VAR_ACTION_COUNT = 0,
    parameter VARLESS_ACTION_COUNT = 0
)(
    input clk,
    input rst,

    input [VAR_ACTION_COUNT-1:0] var_action_controller, // Exposed to the HediosController, to toggle high
    input [VAR_ACTION_COUNT-1:0] var_action_device, // Exposed to exterior logic, to toggle low
    output reg [VAR_ACTION_COUNT-1:0] var_action_out, // Output, exposed to exterior logic

    input [VARLESS_ACTION_COUNT-1:0] varless_action_controller, // Exposed to the HediosController, to toggle high
    input [VARLESS_ACTION_COUNT-1:0] varless_action_device, // Exposed to exterior logic, to toggle low
    output reg [VARLESS_ACTION_COUNT-1:0] varless_action_out
);

integer i;

always @(posedge clk) begin // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
    if (rst) begin
        var_action_out <= 0;
        varless_action_out <= 0;
    end
    else begin

        // VAR_ACTION handling
        for (i = 0; i < VAR_ACTION_COUNT; i = i + 1) begin
            case ({var_action_controller[i], var_action_device[i]})
                
                2'b10 : var_action_out[i] <= 1;
                2'b01 : var_action_out[i] <= 0;
                2'b11 : var_action_out[i] <= 1;

                default: var_action_out[i] <= var_action_out[i];
            endcase
            
        end

        // VARLESS_ACTION handling
        for (i = 0; i < VARLESS_ACTION_COUNT; i = i + 1) begin
            case ({varless_action_controller[i], varless_action_device[i]})
                
                2'b10 : varless_action_out[i] <= 1;
                2'b01 : varless_action_out[i] <= 0;
                2'b11 : varless_action_out[i] <= 1;

                default: varless_action_out[i] <= varless_action_out[i];
            endcase
            
        end
        
    end
end

    
endmodule
