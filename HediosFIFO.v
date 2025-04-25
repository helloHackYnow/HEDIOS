module HediosFIFO #(
    parameter max_capacity = 8
)(
    input clk,
    input rst,
    input push_packet,
    input [7:0] i_packet_command,
    input [31:0] i_packet_data,
    input pop_packet,
    output reg [7:0] o_packet_command,
    output reg [31:0] o_packet_data,
    output empty,
    output full 
);

    // Calculate address width based on max_capacity
    localparam ADDR_WIDTH = $clog2(max_capacity);
    
    // Memory array to store packet data
    reg [7:0] command_mem [0:max_capacity-1];
    reg [31:0] data_mem [0:max_capacity-1];
    
    // Pointers for read and write operations
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    
    // Status counter
    reg [ADDR_WIDTH:0] count;
    
    // FIFO status signals
    assign empty = (count == 0);
    assign full = (count == max_capacity);
    
    // Write pointer logic
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if ((push_packet && !full) || (push_packet && pop_packet)) begin
            command_mem[wr_ptr] <= i_packet_command;
            data_mem[wr_ptr] <= i_packet_data;
            wr_ptr <= (wr_ptr == max_capacity-1) ? 0 : wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            o_packet_command <= 0;
            o_packet_data <= 0;
        end else if (pop_packet && !empty) begin
            o_packet_command <= command_mem[rd_ptr];
            o_packet_data <= data_mem[rd_ptr];
            rd_ptr <= (rd_ptr == max_capacity-1) ? 0 : rd_ptr + 1;
        end
    end
    
    // FIFO count logic
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end else begin
            case ({push_packet && !full, pop_packet && !empty})
                2'b10: count <= count + 1; // Push only
                2'b01: count <= count - 1; // Pop only
                2'b11: count <= count;     // Push and pop simultaneously
                default: count <= count;   // No operation
            endcase
        end
    end

endmodule