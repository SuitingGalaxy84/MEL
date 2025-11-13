// 文件名: sram_model.v

module SRAM #(
    parameter DATA_WIDTH = 16,   // 数据宽度（每个存储单元的位数）
    parameter ADDR_WIDTH = 4    // 地址宽度（决定SRAM的深度）
) (
    input                       clk,   // 时钟信号
    input                       rstn,  // 异步复位，低电平有效
    input                       cs,    // Chip Select (片选)，高电平有效
    input                       we,    // Write Enable (写使能)，高电平写，低电平读
    input      [ADDR_WIDTH-1:0] r_addr,  // 读地址线
    input      [ADDR_WIDTH-1:0] w_addr,  // 写地址线
    input      [DATA_WIDTH-1:0] din,   // 写入的数据 (Data In)
    output reg [DATA_WIDTH-1:0] dout   // 读出的数据 (Data Out)
);


    localparam ADDR_DEPTH = 1 << ADDR_WIDTH; // 2^ADDR_WIDTH
    reg [DATA_WIDTH-1:0] mem [0:ADDR_DEPTH-1];
    integer i; // Move integer declaration outside the always block

    // --- Write Operation: Asynchronous Reset, Synchronous Write ---
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 异步复位：清空SRAM内容
            for (i = 0; i < ADDR_DEPTH; i = i + 1) begin
                mem[i] <= 0;
                dout   <= 0;
            end
        end else if (cs && we) begin
            mem[w_addr] <= din;
        end
    end

    // --- Read Operation: Synchronous Read ---
    always @(posedge clk) begin
        if (cs) begin
            if (we && (w_addr == r_addr)) begin
                // *Read-after-write hazard handling
                dout <= din;
            end else begin
                dout <= mem[r_addr];
            end
        end
    end

endmodule