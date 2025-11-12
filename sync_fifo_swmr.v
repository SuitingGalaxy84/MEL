// module sync fifo single write multiple read
module SYNC_FIFO_SWMR#(
    parameter W_WIDTH   = 32,
    parameter W_DEPTH   = 16,
    parameter W_ADDR_WIDTH = $clog2(W_DEPTH),
    
    parameter R_WIDTH   = 16,
    parameter R_DEPTH   = W_DEPTH * W_WIDTH / R_WIDTH,
    parameter R_ADDR_WIDTH = $clog2(R_DEPTH)
)(
    input                   clk,
    input                   rst_n,
    
    // Write interface
    input                   wr_en,
    input  [W_WIDTH-1:0]    wr_data,
    output                  full,
    
    // Read interface
    input                   rd_en,
    output [R_WIDTH-1:0]    rd_data,
    output                  empty
);

    localparam RATIO = W_WIDTH / R_WIDTH;
    reg [R_WIDTH-1:0] mem [0:R_DEPTH-1];
    reg [W_ADDR_WIDTH:0] wr_ptr;
    reg [R_ADDR_WIDTH:0] rd_ptr;

    // write logic
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
            // write data into memory
            for (i = 0; i < RATIO; i = i + 1) begin
                mem[wr_ptr * RATIO + i] <= wr_data[(i+1)*R_WIDTH-1 -: R_WIDTH];
            end
        end
    end 

    // read logic
    assign rd_data = mem[rd_ptr];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // empty and full signals
    assign empty = wr_ptr * RATIO <= rd_ptr; 
    assign full  = ((wr_ptr - rd_ptr * RATIO) == R_DEPTH);
endmodule