module au_top(
    input clk,
    input rst_n,
    input[4:0] io_button,
    input usb_rx,
    input[2:0][7:0] io_dip,

    output[7:0] led,
    output[2:0][7:0] io_led,
    output usb_tx

    );
    
    wire rst_btn;
    wire rst;

    wire[15:0] reg_value;

    btn_conditionner #(
        .STAGES(4)
    ) rst_cond (
        .clk(clk),
        .in(~rst_n),
        .out(rst_btn)
    );

    wire slow_clock;
    wire slower_clock;
    

    clk_divider #(
        .divider(4096)
    ) clk_divider_instance (
        .clk(clk),
        .rst(rst),
        .out(slow_clock)
    );

    clk_divider #(
        .divider(4096)
    ) slow_div (
        .clk(slow_clock),
        .rst(rst),
        .out(slower_clock)
    );

    wire user_we_btn;

    btn_conditionner #(
        .STAGES(4)
    ) btn_conditionner_instance (
        .clk(slower_clock),
        .in(io_button[1]),
        .out(user_we_btn)
    );

    
    

    localparam SLOT_COUNT = 1;
    


    wire hedios_rst;
    wire[32*SLOT_COUNT-1:0] hedios_slots;

    localparam VARLESS_ACTION_COUNT = 1;
    localparam VAR_ACTION_COUNT = 1;

    wire [VARLESS_ACTION_COUNT-1:0] varless_action;
    wire [VAR_ACTION_COUNT-1:0] var_action;
    wire [VAR_ACTION_COUNT*32-1:0] var_action_parameters;

    HediosEndpoint #(
        .CLK_RATE(100_000_000),
        .BAUD_RATE(1_000_000),
        .SLOT_COUNT(SLOT_COUNT),
        .VAR_ACTION_COUNT(VAR_ACTION_COUNT),
        .VARLESS_ACTION_COUNT(VARLESS_ACTION_COUNT)
    ) HediosEndpoint_instance (
        .clk(clk),
        .rst(rst),
        .rx_line(usb_rx),
        .tx_line(usb_tx),
        .hedios_slots(hedios_slots),
        .rst_device(hedios_rst),
        .varless_action_out(varless_action),
        .var_action_parameters(var_action_parameters),
        .var_action_out(var_action)
    );

    HediosRegister #(
        .DEPTH(16)
    ) HediosRegister_instance (
        .clk(clk),
        .rst(rst),
        .hedios_in(var_action_parameters[15:0]),
        .hedios_we(var_action[0]),
        .user_in({io_dip[1], io_dip[0]}),
        .user_we(user_we_btn | varless_action[0]),
        .out(reg_value),
        .race_condition()
    );

    assign io_led[1:0] = reg_value;
    




    
    
    

endmodule