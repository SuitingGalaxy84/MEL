`timescale 1ns/1ps

`include "icb_master_bfm.sv"
`include "icb_slave_bfm.sv"

module tb_icb;

    logic clk;
    logic rst_n;

    // Instantiate the interface
    icb_interface icb_if(clk, rst_n);

    // Instantiate the master and slave BFMs
    icb_master_bfm master (
        .icb(icb_if.master)
    );

    icb_slave_bfm #(
        .MEM_DEPTH(256) // 256 words of 32-bit memory
    ) slave (
        .icb(icb_if.slave)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Main test sequence
    initial begin
        clk = 0;
        rst_n = 0;
        #10;
        rst_n = 1;
        #10;

        $display("Test Started");

        // Perform a write operation
        $display("--- Performing Write Operation ---");
        master.write_word(32'h0000_0010, 32'hDEADBEEF);
        #20;

        // Perform a read operation
        $display("--- Performing Read Operation ---");
        master.read_word(32'h0000_0010);
        #20;
        
        // Perform another write operation
        $display("--- Performing Write Operation 2 ---");
        master.write_word(32'h0000_0024, 32'h12345678);
        #20;

        // Perform another read operation
        $display("--- Performing Read Operation 2 ---");
        master.read_word(32'h0000_0024);
        #20;

        $display("Test Finished");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_icb.vcd");
        $dumpvars(0, tb_icb);
    end

endmodule
