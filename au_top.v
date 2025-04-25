module au_top(
    input clk,
    input rst_n,
    input[4:0] io_button,
    input usb_rx,
    input[2:0][7:0] io_dip,

    output[3:0] io_select,
    output[7:0] io_segment,
    output[2:0][7:0] io_led,
    output usb_tx

    );
    
    wire rst_btn;
    wire rst;
    wire send_ping;
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

    btn_conditionner #(
        .STAGES(4)
    ) btn_conditionner_instance (
        .clk(slow_clock),
        .in(~io_button[1]),
        .out(send_ping)
    );


    wire [7:0] packet_sent;
    HediosEndpoint #(
        .CLK_RATE(100_000_000),
        .BAUD_RATE(1_000_000),
        .SLOT_COUNT(5),
        .ACTION_COUNT(0)
    ) HediosEndpoint_instance (
        .clk(clk),
        .rst(rst),
        .rx_line(usb_rx),
        .tx_line(usb_tx),
        .hedios_slots(hedios_slots),
        .hedios_actions(),
        .action_argument(),
        .send_ping(send_ping),
        .rst_device(hedios_rst),
        .last_command(io_led[2]),
        .packet_sent(packet_sent)
    );

    display display_instance (
        .clk(clk),
        .in({8'b0, packet_sent}),
        .io_select(io_select),
        .io_segment(io_segment)
    );

    always @(posedge slower_clock or posedge rst) begin
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

    
    
    

endmodule