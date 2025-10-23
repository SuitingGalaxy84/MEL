`timescale 1ns / 1ps

module tb_Mel_fbank;

    // Parameters
    parameter WIDTH = 16;
    parameter N_MEL = 40;
    parameter N_FFT = 512;
    parameter NZ_MEL_SRAM_DEPTH = 257;
    parameter CLK_PERIOD = 10; // 100MHz clock

    // Testbench signals
    reg clk;
    reg rst_n;
    reg fft_bin_vld;
    reg [WIDTH-1:0] fft_bin;
    reg [8:0] fft_bin_idx;
    
    wire mel_spec_vld;
    wire [WIDTH-1:0] mel_spec;
    wire [7:0] mel_cnt;
    
    // Internal signals for ROM and SRAM
    wire [1:0] mac_bits;
    wire [2*WIDTH-1:0] mel_fbank_weight;

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    // Load change indicator directly from file
    reg [1:0] mac_bits_mem [0:NZ_MEL_SRAM_DEPTH-1];

    initial begin
        $readmemb("convert/mac_bits.txt", mac_bits_mem);
        $display("Loaded mac_bits from mac_bits.txt");
    end

    assign mac_bits = mac_bits_mem[fft_bin_idx];


    // SRAM for mel filterbank weights
    reg [2*WIDTH-1:0] mel_fbank_mem [0:NZ_MEL_SRAM_DEPTH-1];
    
    // FFT bin values from file
    reg [WIDTH-1:0] fft_bin_mem [0:NZ_MEL_SRAM_DEPTH-1];
    
    initial begin
        $readmemh("convert/mac_q15_hex.txt", mel_fbank_mem);
        $display("Loaded mel filterbank weights from mac_q15_hex.txt");
        
        $readmemh("random_fft_bins_q15.txt", fft_bin_mem);
        $display("Loaded FFT bin values from random_fft_bins_q15.txt");
    end
    
    assign mel_fbank_weight = mel_fbank_mem[fft_bin_idx];

    // DUT instantiation
    MEL_FBANK #(.WIDTH(WIDTH), .N_MEL(N_MEL)) 
    dut (
        .clk(clk),
        .rst_n(rst_n),
        .fft_bin_vld(fft_bin_vld),
        .fft_bin(fft_bin),
        .fft_bin_idx(fft_bin_idx),
        .mel_fbank_weight(mel_fbank_weight),
        .mac_bits(mac_bits),
        .mel_spec_vld(mel_spec_vld),
        .mel_spec(mel_spec),
        .mel_cnt(mel_cnt)
    );

    // Test stimulus and simulation control
    integer i;
    integer output_file;
    integer log_file;
    
    initial begin
        // Initialize signals
        rst_n = 0;
        fft_bin_vld = 0;
        fft_bin = 0;
        fft_bin_idx = 0;
        
        // Open output files
        output_file = $fopen("mel_output.txt", "w");
        log_file = $fopen("mel_output.log", "w");
        
        // VCD dump for waveform viewing
        $dumpfile("tb_Mel_fbank.vcd");
        $dumpvars(0, tb_Mel_fbank);
        
        // Apply Reset
        #(CLK_PERIOD*5);
        rst_n = 1;
        #(CLK_PERIOD*2);
        
        // Write Log Header
        $fwrite(log_file, "\n=== Starting MEL_FBANK Test ===\n");
        $fwrite(log_file, "Time\t\tIdx\tFFT_Bin\t\tMAC_Bits\tWeight[31:16]\tWeight[15:0]\tMel_Spec\tVld\n");
        $fwrite(log_file, "-------------------------------------------------------------------------------------------\n");
        
        // Test: Feed all 257 FFT bins into the filterbank
        for (i = 0; i < 257; i = i + 1) begin
            @(posedge clk);
            fft_bin_vld = 1;
            fft_bin_idx = i;
            fft_bin = fft_bin_mem[i];
        end
        
        // After sending all inputs, de-assert valid signal
        @(posedge clk);
        fft_bin_vld = 0;
        
        // *** CHANGE START: Correctly wait for the simulation to finish ***
        // Wait until the DUT has produced all N_MEL outputs
        $display ("\\n=== All inputs sent. Waiting for final %0d outputs... ===\\n", N_MEL);
        wait(mel_cnt == N_MEL);
        
        // Wait a couple more cycles for the last log message to be written
        #(CLK_PERIOD * 2);
        // *** CHANGE END ***

        // Clean up and finish
        $fclose(output_file);
        $fclose(log_file);
        
        $display("\\n=== Test Completed: %0d outputs received. ===\\n", mel_cnt);
        $display("Log written to mel_output.log");
        $display("Output written to mel_output.txt");
        $finish;
    end
    
    // *** NEW: Event-driven block for logging INPUTS when they are valid ***
    always @(posedge clk) begin
        // Use #1 to log the values *after* they have propagated in the current cycle
        #1; 
        if (fft_bin_vld) begin
            $fwrite(log_file, "%0t\t\t%d\t%h\t\t%b\t\t\t%h\t\t\t%h\t\t\t%h\t\t\t%b\n",
                     $time, fft_bin_idx, fft_bin, mac_bits, 
                     mel_fbank_weight[31:16], mel_fbank_weight[15:0],
                     mel_spec, mel_spec_vld);
        end
    end
    
    // Monitor for valid mel spectrum OUTPUTS
    always @(posedge clk) begin
        if (mel_spec_vld) begin
             // This logic correctly distinguishes between valid and excess outputs
            if(mel_cnt < N_MEL) begin
                $fwrite(log_file, "*** Valid Mel Spectrum Output [%0d]: %h at time %0t\n", mel_cnt, mel_spec, $time);
                $fwrite(output_file, "%h\n", mel_spec);
            end else begin
                $fwrite(log_file, "*** Mel Spectrum Output [%0d] (not recorded - exceeded N_MEL): %h at time %0t\n", mel_cnt, mel_spec, $time);
            end
        end
    end
    
    // Timeout watchdog
    initial begin
        #500000; // 500us timeout, increased to be safe
        $display("ERROR: Simulation timeout!");
        $fclose(output_file);
        $fclose(log_file);
        $finish;
    end

    // REMOVED: No longer need the external stimulus file
    // `include "stim_fbank.v"

endmodule
