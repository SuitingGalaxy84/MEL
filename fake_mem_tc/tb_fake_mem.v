`timescale 1ns / 1ps

//=============================================================================
// Testbench for fake_mem module
// Tests memory read operations with various addresses
//=============================================================================

module tb_fake_mem;

    // Parameters matching the DUT
    localparam MEM_DEPTH  = 256;
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 32;
    localparam CLK_PERIOD = 10;

    // Testbench signals
    reg                             clk;
    reg                             rst_n;
    reg                             wr_en;
    reg [ADDR_WIDTH-1:0]           program_counter;
    wire [4*DATA_WIDTH-1:0]        data_out;

    // File handles for logging
    integer output_file;
    integer error_count;
    integer test_count;

    // Instantiate the DUT (Device Under Test)
    fake_mem_gen #(
        .MEM_DEPTH(MEM_DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .program_counter(program_counter),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // VCD dump for waveform viewing
    initial begin
        $dumpfile("tb_fake_mem.vcd");
        $dumpvars(0, tb_fake_mem);
    end

    // Main test sequence
    initial begin
        // Open output file
        output_file = $fopen("output.txt", "w");
        error_count = 0;
        test_count = 0;

        // Initialize signals
        $display("========================================");
        $display("Starting fake_mem testbench...");
        $display("========================================");
        
        rst_n = 0;
        wr_en = 0;
        program_counter = 0;
        
        // Apply reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD);
        
        $display("Reset released. Starting memory read tests.");
        
        // Test Case 1: Read from various addresses
        $display("\n[Test 1] Reading from sequential addresses...");
        test_read(0);
        test_read(4);
        test_read(8);
        test_read(12);
        test_read(16);
        
        // Test Case 2: Read from mid-range addresses
        $display("\n[Test 2] Reading from mid-range addresses...");
        test_read(32);
        test_read(64);
        test_read(96);
        test_read(128);
        
        // Test Case 3: Read from upper addresses
        $display("\n[Test 3] Reading from upper addresses...");
        test_read(192);
        test_read(252);
        
        // Test Case 4: Test with wr_en disabled
        $display("\n[Test 4] Testing with wr_en disabled...");
        wr_en = 0;
        program_counter = 0;
        #(CLK_PERIOD);
        $display("  PC=%d, wr_en=%b, data_out=0x%08h (should be previous or zero)", 
                 program_counter, wr_en, data_out);
        
        // Test Case 5: Rapid address changes
        $display("\n[Test 5] Testing rapid address changes...");
        wr_en = 1;
        for (integer i = 0; i < 20; i = i + 8) begin
            program_counter = i;
            #(CLK_PERIOD);
            $display("  PC=%3d, data_out=0x%08h", program_counter, data_out);
            $fwrite(output_file, "%08h\n", data_out);
        end
        
        // Summary
        #(CLK_PERIOD * 5);
        $display("\n========================================");
        $display("Testbench completed!");
        $display("Total tests: %0d", test_count);
        if (error_count == 0) begin
            $display("Result: PASS - All tests completed");
        end else begin
            $display("Result: FAIL - %0d errors detected", error_count);
        end
        $display("========================================");
        
        // Close file and finish
        $fclose(output_file);
        $finish;
    end

    // Task to test memory read
    task test_read;
        input [ADDR_WIDTH-1:0] addr;
        begin
            test_count = test_count + 1;
            wr_en = 1;
            program_counter = addr;
            #(CLK_PERIOD);
            $display("  PC=%3d, data_out=0x%08h [%02h %02h %02h %02h]", 
                     program_counter, 
                     data_out,
                     data_out[31:24],
                     data_out[23:16],
                     data_out[15:8],
                     data_out[7:0]);
            $fwrite(output_file, "%08h\n",data_out);
        end
    endtask

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 1000);
        $display("\n[ERROR] Testbench timeout!");
        $fclose(output_file);
        $finish;
    end

endmodule
