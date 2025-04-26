module HediosEndpoint #(
    parameter CLK_RATE = 100_000_000,
    parameter BAUD_RATE = 1_000_000,
    parameter SLOT_COUNT = 0,
    parameter VAR_ACTION_COUNT = 0,
    parameter VARLESS_ACTION_COUNT = 0
    ) 
    (
    input clk,
    input rst,

    input rx_line,
    output tx_line,

    input[SLOT_COUNT-1:0][31:0] hedios_slots,

    // HediosAction
    input [VAR_ACTION_COUNT-1:0] var_action_device, // Exposed to exterior logic, set by the device to toggle down a accounted for action signal
    input [VARLESS_ACTION_COUNT-1:0] varless_action_device, // Idem

    output [VAR_ACTION_COUNT-1:0] var_action_out,
    output [VARLESS_ACTION_COUNT-1:0] varless_action_out,

    output [VAR_ACTION_COUNT-1:0][31:0] var_action_parameters,
    output rst_device
);

    // serial rx wires
    wire rx_empty, rx_full, rx_pop_packet, rx_lost_data;
    wire[7:0] rx_command;
    wire[31:0] rx_data;

    // serial tx wires
    wire tx_empty, tx_full, tx_push_packet;
    wire[7:0] tx_command;
    wire[31:0] tx_data;

    // HediosAction wires
    wire [VAR_ACTION_COUNT-1:0] var_action_inside;
    wire [VARLESS_ACTION_COUNT-1:0] varless_action_inside;



    HediosSerial_TX #(
        .BAUD_RATE(BAUD_RATE)
    ) HediosSerial_TX_instance (
        .clk(clk),
        .rst(rst),
        .packet_command(tx_command),
        .packet_data(tx_data),
        .push_packet(tx_push_packet),
        .queue_full(tx_full),
        .queue_empty(tx_empty),
        .tx_line(tx_line)
    );

    HediosSerial_RX HediosSerial_RX_instance (
        .clk(clk),
        .rst(rst),
        .rx_line(rx_line),
        .pop_packet(rx_pop_packet),
        .packet_command(rx_command),
        .packet_data(rx_data),
        .queue_full(rx_full),
        .lost_data(rx_lost_data),
        .queue_empty(rx_empty)
    );

    HediosController #(
        .SLOT_COUNT(SLOT_COUNT),
        .VAR_ACTION_COUNT(VAR_ACTION_COUNT),
        .VARLESS_ACTION_COUNT(VARLESS_ACTION_COUNT)
    ) HediosController_instance (
        .clk(clk),
        .rst(rst),
        .rx_empty(rx_empty),
        .rx_full(rx_full),
        .rx_lost_data(rx_lost_data),
        .rx_command(rx_command),
        .rx_data(rx_data),
        .rx_pop_packet(rx_pop_packet),
        .tx_empty(tx_empty),
        .tx_full(tx_full),
        .tx_command(tx_command),
        .tx_data(tx_data),
        .tx_push_packet(tx_push_packet),
        .slots(hedios_slots),
        .rst_device(rst_device),
        .var_actions(var_action_inside),
        .varless_actions(varless_action_inside),
        .var_action_parameter(var_action_parameters)

    );

    HediosActionHandler #(
        .VAR_ACTION_COUNT(VAR_ACTION_COUNT),
        .VARLESS_ACTION_COUNT(VARLESS_ACTION_COUNT)
    ) HediosActionHandler_instance (
        .clk(clk),
        .rst(rst),
        .var_action_controller(var_action_inside),
        .var_action_device(var_action_device),
        .var_action_out(var_action_out),
        .varless_action_controller(varless_action_inside),
        .varless_action_device(varless_action_device),
        .varless_action_out(varless_action_out)
    );

    
endmodule
