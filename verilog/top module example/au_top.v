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
    reg[7:0] counter;
    
    btn_conditionner #(
        .STAGES(4)
    ) rst_cond (
        .clk(clk),
        .in(~rst_n),
        .out(rst_btn)
    );

    wire slow_clock;
    wire slower_clock;
    wire hedios_rst;
    wire[32*5-1:0] hedios_slots;

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

    localparam VARLESS_ACTION_COUNT = 5;
    wire [VARLESS_ACTION_COUNT-1:0] varless_action;

    HediosEndpoint #(
        .CLK_RATE(100_000_000),
        .BAUD_RATE(1_000_000),
        .SLOT_COUNT(5),
        .VAR_ACTION_COUNT(0),
        .VARLESS_ACTION_COUNT(VARLESS_ACTION_COUNT)
    ) HediosEndpoint_instance (
        .clk(clk),
        .rst(rst),
        .rx_line(usb_rx),
        .tx_line(usb_tx),
        .hedios_slots(hedios_slots),
        .rst_device(hedios_rst),
        .varless_action_out(varless_action)
    );

    always @(posedge slower_clock or posedge rst) begin // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
        if (rst) counter <= 0;
        else counter <= counter + 1;
    end

    assign rst = rst_btn || hedios_rst;
    assign io_led[0] = counter;
    assign hedios_slots[7:0] = io_dip[0];
    assign hedios_slots[39:32] = io_dip[1];
    assign hedios_slots[71:64] = io_dip[2];
    assign hedios_slots[103:96] = counter;
    assign hedios_slots[135:128] = counter;
    assign led = {8{varless_action[0]}};

    
    
    

endmodule