module S2SRAM #(
    parameter MEL_BAND = 40,
    parameter WRITE_WIDTH = MEL_BAND * 16, // N_MEL * READ_WIDTH
    parameter READ_WIDTH = 16,
    parameter WRITE_DEPTH = 101,       // SR / HOP_LEN + 1
    parameter READ_DEPTH = MEL_BAND * WRITE_DEPTH,
    parameter WRITE_ADDR_WIDTH = 7,    // ceil(log2(WRITE_DEPTH))
    parameter READ_ADDR_WIDTH = 13     // ceil(log2(READ_DEPTH))
)(
    input clk,
    input rst_n,

    // Write Port
    input wr_en,
    input [WRITE_ADDR_WIDTH-1:0] wr_addr,
    input [WRITE_WIDTH-1:0] wr_data,

    // Read Port
    input rd_en,
    input [READ_ADDR_WIDTH-1:0] rd_addr,
    output reg [READ_WIDTH-1:0] rd_data
);

    // Memory array
    reg [WRITE_WIDTH-1:0] mem [0:WRITE_DEPTH-1];

    // Write operation: synchronous write
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // Read operation: synchronous read with read-after-write behavior
    // Split read address into mel band and write address
    wire [WRITE_ADDR_WIDTH-1:0] raddr_word = rd_addr % WRITE_DEPTH;
    wire [5:0] raddr_band = rd_addr / WRITE_DEPTH; // 6 bits for up to 64 bands

    always @(posedge clk) begin
        if (rd_en) begin
            if (wr_en && (wr_addr == raddr_word)) begin
                rd_data <= wr_data[raddr_band*READ_WIDTH +: READ_WIDTH];
            end else begin
                rd_data <= mem[raddr_word][raddr_band*READ_WIDTH +: READ_WIDTH];
            end
        end
    end

endmodule