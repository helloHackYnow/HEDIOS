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

    // Single tick pulse on the i_th bit when the corresponding action is received
    output [VAR_ACTION_COUNT-1:0] var_action_out, 

    // Single tick pulse on the i_th bit when the corresponding action is received
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



    HediosSerial_TX #(
        .CLK_RATE(CLK_RATE),
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

    HediosSerial_RX#(
        .CLK_RATE(CLK_RATE),
        .BAUD_RATE(BAUD_RATE)
    )  HediosSerial_RX_instance (
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
        .var_actions(var_action_out),
        .varless_actions(varless_action_out),
        .var_action_parameter(var_action_parameters)

    );

    
endmodule
