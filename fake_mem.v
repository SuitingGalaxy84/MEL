module fake_mem_gen#(
    parameter MEM_DEPTH  = 20, 
    parameter DATA_WIDTH = 32, // Data width is now 32 bits
    parameter ADDR_WIDTH = $clog2(MEM_DEPTH) // Correctly calculate address width
)(
    input                           clk,
    input                           wr_en,
    input                           rd_en, 
    input [DATA_WIDTH-1:0]          data_in,
    input [ADDR_WIDTH-1:0]          r_addr,
    output reg [DATA_WIDTH-1:0]     data_out
);
    // Memory is now 32 bits wide.
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

`ifndef SYNTHESIS
    initial begin
        // Use a new initialization file for the 32-bit wide memory
        $readmemh("D:\\Desktop\\PG Repo\\MEL\\fake_mem_tc\\fake_mem_init_32bit.txt", mem, 0, MEM_DEPTH);
    end
`endif

    // This is a standard synchronous read, which is easily synthesized to BRAM.
    always @(posedge clk) begin
        if(wr_en) begin
            // Convert byte address to word address by right-shifting by 2 (dividing by 4)
            mem[program_counter >> 2] <= data_in;
        end else if (rd_en) begin
            data_out <= mem[program_counter >> 2];
        end
    end
     
endmodule