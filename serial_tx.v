module serial_tx #(
    parameter clk_rate = 100_000_000,
    parameter baud_rate = 9_600,
    parameter data_bit_count = 8
)(
    input clk,
    input [data_bit_count-1:0] i_data,
    input i_start,
    input rst,
    output reg tx = 1,
    output reg o_active = 0,
    output reg o_done = 0
);

    localparam TICK_PER_BIT = clk_rate / baud_rate;

    // State definitions
    localparam IDLE     = 3'b000,
               TR_START = 3'b001,
               TR_DATA  = 3'b010,
               TR_STOP  = 3'b011,
               CLEAN    = 3'b100;

    reg [2:0] sm_state = IDLE;
    reg [data_bit_count-1:0] shift_data = 0;
    reg [$clog2(TICK_PER_BIT):0] clk_counter = 0;
    reg [$clog2(data_bit_count):0] sent_counter = 0;

    always @(posedge clk) begin // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
        case (sm_state)
            IDLE: begin
                o_done <= 0;
                o_active <= 0;
                tx <= 1'b1;
                clk_counter <= 0;
                sent_counter <= 0;

                if (i_start) begin
                    o_active <= 1;
                    shift_data <= i_data;
                    sm_state <= TR_START;
                end
            end

            TR_START: begin
                tx <= 1'b0;
                if (clk_counter < TICK_PER_BIT - 1) clk_counter <= clk_counter + 1;
                else begin
                    clk_counter <= 0;
                    sm_state <= TR_DATA;
                end
            end

            TR_DATA: begin
                tx <= shift_data[0];
                if (clk_counter < TICK_PER_BIT - 1)
                    clk_counter <= clk_counter + 1;
                else begin
                    clk_counter <= 0;
                    shift_data <= {1'b0, shift_data[data_bit_count-1:1]};
                    sent_counter <= sent_counter + 1;
                    if (sent_counter == data_bit_count - 1)
                        sm_state <= TR_STOP;
                end
            end

            TR_STOP: begin
                tx <= 1'b1;
                if (clk_counter < TICK_PER_BIT - 1)
                    clk_counter <= clk_counter + 1;
                else begin
                    clk_counter <= 0;
                    sm_state <= CLEAN;
                end
            end

            CLEAN: begin
                o_active <= 0;
                o_done <= 1;
                sm_state <= IDLE;
            end
        endcase
    end

endmodule
