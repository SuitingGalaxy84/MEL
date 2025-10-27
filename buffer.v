module buffer #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 128,
    parameter ADDR_WIDTH = $clog2(DEPTH) // Should be ceil(log2(DEPTH))
) (
    input clk,
    input rst,
    input reg_write,
    input [ADDR_WIDTH-1:0] read_addr,
    input [ADDR_WIDTH-1:0] write_addr,
    input [DATA_WIDTH-1:0] write_data,
    output [DATA_WIDTH-1:0] read_data
);

    // Register array declaration
    reg [DATA_WIDTH-1:0] reg_array [DEPTH-1:0];

    // Synchronous write operation
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Optional: Reset all registers to zero
            for (i=0; i < DEPTH; i=i+1) begin
                reg_array[i] <= 0;
            end
        end else if (reg_write) begin
            reg_array[write_addr] <= write_data;
        end else begin
            for (i=0; i < DEPTH; i=i+1) begin
                reg_array[i] <= reg_array[i];
            end
        end
    end

    // Asynchronous read operations
    assign read_data = reg_array[read_addr];

endmodule
