`timescale 1ns / 1ps

module tb_Window_lut;

    // Parameters
    localparam CLK_PERIOD = 10;  // 10ns clock period (100MHz)
    localparam WIDTH = 16;
    localparam N_FFT = 512;
    localparam WIN_LEN = 480;
    localparam HOP_LEN = 160;
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg den;
    reg [WIDTH-1:0] din_re;
    reg [WIDTH-1:0] din_im;
    wire dout_en;
    wire [WIDTH-1:0] dout_re;
    wire [WIDTH-1:0] dout_im;
    // File handles
    integer input_file;
    integer output_file;
    integer scan_result;
    
    // Test control variables
    integer sample_count;
    integer frame_count;
    reg [WIDTH-1:0] expected_re, expected_im;

    // Instantiate the DUT (Device Under Test)
    WIN_LUT #(
        .WIDTH(WIDTH),
        .N_FFT(N_FFT),
        .WIN_LEN(WIN_LEN),
        .HOP_LEN(HOP_LEN)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .den(den),
        .din_re(din_re),
        .din_im(din_im),
        .dout_en(dout_en),
        .dout_re(dout_re),
        .dout_im(dout_im)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Monitor output and write to file
    always @(posedge clk) begin
        if (dout_en) begin
            $fwrite(output_file, "%04h %04h\n", dout_re, dout_im);
            $display("Time %0t: Output [%0d] - RE: %d (0x%h), IM: %d (0x%h)", 
                     $time, sample_count, $signed(dout_re), dout_re, $signed(dout_im), dout_im);
        end
    end


    // Main test procedure
    initial begin
        // Initialize signals
        rst_n = 1;
        den = 0;
        din_re = 0;
        din_im = 0;
        sample_count = 0;
        frame_count = 0;

        // Open output file
        output_file = $fopen("D:\\Desktop\\PG Repo\\MEL\\win_lut_tc\\output.txt", "w");
        if (output_file == 0) begin
            $display("ERROR: Could not open output.txt");
            $finish;
        end

        // Apply reset
        $display("=== Applying Reset ===");
        #5;
        rst_n = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        $display("=== Reset Released ===\n");

        // Open input file
        input_file = $fopen("D:\\Desktop\\PG Repo\\MEL\\win_lut_tc\\input.txt", "r");
        if (input_file == 0) begin
            $display("ERROR: Could not open input.txt");
            $fclose(output_file);
            $finish;
        end

        // Test: Feed continuous input samples
        // The module should accumulate WIN_LEN samples, then start outputting
        // windowed frames every HOP_LEN samples
        $display("=== Starting to feed input samples ===\n");
        
        den = 1;
        
        // Feed enough samples to generate multiple frames
        // We'll feed WIN_LEN + 2*HOP_LEN samples to get 3 output frames
        while (!$feof(input_file)) begin
            scan_result = $fscanf(input_file, "%h %h\n", din_re, din_im);
            if (scan_result == 2) begin
                $display("Time %0t: Input [%0d] - RE: %d (0x%h), IM: %d (0x%h)", 
                         $time, sample_count, $signed(din_re), din_re, $signed(din_im), din_im);
                
                sample_count = sample_count + 1;
                @(posedge clk);
            end else begin
                $display("Warning: Failed to read input at sample %0d", sample_count);
            end
        end

        // Continue for a few more cycles to capture any remaining outputs
        den = 0;
        repeat(N_FFT + 10) @(posedge clk);

        // Close files
        $fclose(input_file);
        $fclose(output_file);

        $display("\n=== Test Completed ===");
        $display("Total input samples: %0d", sample_count);
        $display("Output written to output.txt");
        $display("Run verify.py to check results");
        
        #100;
        $finish;
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 100000);  // 1ms timeout
        $display("ERROR: Simulation timeout!");
        $fclose(output_file);
        $finish;
    end

    // Optional: Generate VCD for waveform viewing
    initial begin
        $dumpfile("tb_window_lut.vcd");
        $dumpvars(0, tb_Window_lut);
    end

endmodule
