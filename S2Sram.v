module S2SRAM #(
    parameter DEPTH = 512, 
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = $clog2(DEPTH) // ceil(log2(READ_DEPTH))
)(
    input clk,
    input rst_n,

    // Write Port
    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [WIDTH-1:0] wr_data,

    // Read Port
    input rd_en,
    input [ADDR_WIDTH-1:0] rd_addr,
    output reg [WIDTH-1:0] rd_data
);

    // Memory array
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Write operation: synchronous write
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin    
            rd_data <= 0;
        end else if (rd_en) begin
            rd_data <= rd_addr == wr_addr ? wr_data : mem[rd_addr];
        end 
    end 

endmodule