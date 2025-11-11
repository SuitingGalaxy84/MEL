`timescale 1ns / 1ps
module tb_cpu_feb;
    reg             clk;
    reg             rst_n;
     // 50 MHz
    parameter DW   = 32;
    wire [31:0]      inst;
    wire [31:0] imem_addr;
    wire [31:0] debug_wb_data;  // 从CPU引出
    wire [4:0]  debug_wb_rd;    // 从CPU引出
    
    cpu_top u_top(
    .clk(clk),
    .rst_n(rst_n),
    .if_id_instruction(inst),//读出的指令
    .imem_addr(imem_addr),//输出的指令地址

    .debug_wb_data(debug_wb_data),  // 连接调试信号
    .debug_wb_rd(debug_wb_rd)       // 连接调试信号
    );
    
    fake_mem_gen u_imem(
        .clk(clk),
        .rst_n(rst_n),
        .program_counter(imem_addr),
        .data_out(inst)
    );
    
    
/* 时钟生成 */
    initial begin
        clk = 0;
        forever #(10) clk = ~clk;
    end
    
    initial begin
            rst_n   = 0;        // 上电复位
            #20;
            rst_n = 1;
            #1000;
            $finish;
    end
    initial begin
            $dumpfile("feb_cpu_wave.vcd");  // 指定VCD文件名
            $dumpvars(2, tb_cpu_feb);       // 记录所有层次的信号

    end
endmodule