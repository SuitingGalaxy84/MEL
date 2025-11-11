module fake_mem_gen#(
    parameter MEM_DEPTH  = 2**32,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = $clog2(MEM_DEPTH)
)(
    input                           clk,
    input                           rst_n,
    input                           wr_en,
    input [ADDR_WIDTH-1:0]          program_counter,
    output reg [4*DATA_WIDTH-1:0]     data_out
);
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];   
    initial begin
        $readmemh("fake_mem_init.txt", mem);
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out <= {4{8'h00}};
        end else if(wr_en) begin
            data_out <= {mem[program_counter], mem[program_counter+1], mem[program_counter+2], mem[program_counter+3]};
        end
    end
    

endmodule