/**
 * @file coeff_rom.v
 * @brief 梅尔滤波器系数�?�读存储器
 * @details
 *  - 存储预先计算好的稀�?滤波器系数。
 *  - 在综�?�时通过外部的 .mem 文件进行�?始化。
 *  - .mem 文件应由Python脚本(如使用librosa)生�?。
 *  - 格�?: 257行, �?行44�? {mel_idx_1[5:0], weight_1[15:0], mel_idx_2[5:0], weight_2[15:0]}
 */
module ROM #(
    parameter DATA_WIDTH   = 44,
    parameter ADDR_WIDTH   = 9  // For 512-point FFT, we have 257 bins (0 to 256)
)(
    input                      clk,
    input  [ADDR_WIDTH-1:0]    addr,
    output [DATA_WIDTH-1:0]    data
);

    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    // ROM的�?始化
    // 综�?�工具会查找�?��??的.mem或.hex文件�?�填充这个ROM
    // 例如: initial $readmemh("mel_coeffs.mem", mem);
    initial begin
        $readmemb("mel_fb_idx_change_indicators.txt", mem);
    end

    // ROM的读�?作是组�?�逻辑或寄存器输出，这里用寄存器输出以获得更好的时�?
    reg [DATA_WIDTH-1:0] data_reg;
    assign data = data_reg;

    always @(posedge clk) begin
        data_reg <= mem[addr];
    end

endmodule