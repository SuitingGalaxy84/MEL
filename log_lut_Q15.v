`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2025 12:24:04
// Design Name: 
// Module Name: log_lut
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module LOG_LUT_Q15 (
    input wire clk, rst,
    input wire [7:0] in,
    output reg [7:0] out
);
    // 13-entry LUT for log10(1) to log10(13)
    reg [7:0] log_table [0:12];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            log_table[0]  <= 16'd0;      // log10(1)   = 0 * 32768
            log_table[1]  <= 16'd9872;   // log10(2)   ≈ 0.3010 * 32768
            log_table[2]  <= 16'd15636;  // log10(3)   ≈ 0.4771 * 32768
            log_table[3]  <= 16'd19723;  // log10(4)   ≈ 0.6020 * 32768
            log_table[4]  <= 16'd22899;  // log10(5)   ≈ 0.6990 * 32768
            log_table[5]  <= 16'd25489;  // log10(6)   ≈ 0.7782 * 32768
            log_table[6]  <= 16'd27681;  // log10(7)   ≈ 0.8451 * 32768
            log_table[7]  <= 16'd29577;  // log10(8)   ≈ 0.9031 * 32768
            log_table[8]  <= 16'd31254;  // log10(9)   ≈ 0.9542 * 32768
            out <= 8'd0;
        end else begin
            if (in <= 8'd0) begin
                out <= 8'd0;
            end else begin
                // Use top 4 bits for better coverage (0-12)
                out <= log_table[in[7:4] > 12 ? 12 : in[7:4]];
            end
        end
    end
endmodule