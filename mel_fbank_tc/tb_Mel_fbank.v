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
        $readmemb("D:\\Desktop\\PG Repo\\MEL\\mel_fbank_tc\\convert\\mac_bits.txt", mac_bits_mem);
        $display("Loaded mac_bits from mac_bits.txt");
        // Debug: Display first few values
        $display("DEBUG: mac_bits_mem[0] = %b", mac_bits_mem[0]);
        $display("DEBUG: mac_bits_mem[3] = %b", mac_bits_mem[3]);
        $display("DEBUG: mac_bits_mem[4] = %b", mac_bits_mem[4]);
        $display("DEBUG: mac_bits_mem[10] = %b", mac_bits_mem[10]);
    end


    assign mac_bits = mac_bits_mem[fft_bin_idx];


    // SRAM for mel filterbank weights
    reg [2*WIDTH-1:0] mel_fbank_mem [0:NZ_MEL_SRAM_DEPTH-1];
    
    // Random Q1.15 FFT bin values
    reg [WIDTH-1:0] fft_bin_mem [0:NZ_MEL_SRAM_DEPTH-1];
    
    // Load mel filterbank values from file
    initial begin
        $readmemh("D:\\Desktop\\PG Repo\\MEL\\mel_fbank_tc\\convert\\mac_q15_hex.txt", mel_fbank_mem);
        $display("Loaded mel filterbank weights from mac_q15_hex.txt");
        
        // Load random Q1.15 FFT bin values
        $readmemh("D:\\Desktop\\PG Repo\\MEL\\mel_fbank_tc\\random_fft_bins_q15.txt", fft_bin_mem);
        $display("Loaded random Q1.15 FFT bin values from random_fft_bins_q15.txt");
    end
    
    // SRAM read operation - COMBINATIONAL (no delay)
    assign mel_fbank_weight = (fft_bin_idx < NZ_MEL_SRAM_DEPTH) ? 
                                mel_fbank_mem[fft_bin_idx] : 32'h0;

    // DUT instantiation
    MEL_FBANK #(
        .WIDTH(WIDTH),
        .N_MEL(N_MEL),
        .N_FFT(N_FFT),
        .NZ_MEL_SRAM_DEPTH(NZ_MEL_SRAM_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .fft_bin_vld(fft_bin_vld),
        .fft_bin(fft_bin),
        .mel_fbank_weight(mel_fbank_weight),
        .mac_bits(mac_bits),
        .mel_spec_vld(mel_spec_vld),
        .mel_spec(mel_spec),
        .mel_cnt(mel_cnt)
    );

    // Test stimulus
    integer i;
    integer output_file;
    
    initial begin
        // Initialize signals
        rst_n = 0;
        fft_bin_vld = 0;
        fft_bin = 0;
        fft_bin_idx = 0;
        
        // Open output file for writing
        output_file = $fopen("mel_output.txt", "w");
        if (output_file == 0) begin
            $display("ERROR: Could not open output.txt for writing");
            $finish;
        end
        
        // VCD dump for waveform viewing
        $dumpfile("tb_Mel_fbank.vcd");
        $dumpvars(0, tb_Mel_fbank);
        
        // Reset
        #(CLK_PERIOD*5);
        rst_n = 1;
        #(CLK_PERIOD*2);
        
        $display("\n=== Starting MEL_FBANK Test ===\n");
        $display("Time\t\tIdx\tFFT_Bin\t\tMAC_Bits\tWeight[31:16]\tWeight[15:0]\tMel_Spec\tVld");
        $display("-------------------------------------------------------------------------------------------");
        
        // Test: Feed FFT bins through the filterbank
        for (i = 0; i < 257; i = i + 1) begin
            @(posedge clk);
            fft_bin_idx = i;
            fft_bin_vld = 1;
            fft_bin = fft_bin_mem[i]; // Use random Q1.15 values from memory
            
            #1; // Small delay for signal propagation before display
            $display("%0t\t%d\t%h\t%b\t\t%h\t%h\t%h\t%b",
                     $time, fft_bin_idx, fft_bin, mac_bits, 
                     mel_fbank_weight[31:16], mel_fbank_weight[15:0],
                     mel_spec, mel_spec_vld);
            
            // Additional debug for indices where we expect 11
            if (i == 3 || i == 4 || i == 10 || i == 11 || i == 12) begin
                $display("  -> DEBUG idx=%d: mac_bits_mem[%d]=%b, mac_bits=%b", 
                         i, i, mac_bits_mem[i], mac_bits);
            end
        end
        
        // Continue for a few more cycles to see final outputs
        fft_bin_vld = 0;
        repeat(10) @(posedge clk);
        
        // Close output file
        $fclose(output_file);
        
        $display("\n=== Test Completed ===\n");
        $display("Output written to mel_output.txt");
        $finish;
    end
    
    // Monitor for valid mel spectrum outputs
    always @(posedge clk) begin
        if (mel_spec_vld && mel_cnt < N_MEL) begin
            $display("*** Valid Mel Spectrum Output [%0d]: %h at time %0t", mel_cnt, mel_spec, $time);
            // Write to output file only until we reach N_MEL outputs
            $fwrite(output_file, "%h\n", mel_spec);
        end else if (mel_spec_vld && mel_cnt >= N_MEL) begin
            $display("*** Mel Spectrum Output [%0d] (not recorded - exceeded N_MEL): %h at time %0t", mel_cnt, mel_spec, $time);
        end
    end
    // Timeout watchdog
    initial begin
        #100000; // 100us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end


// Include external stimuli/logger
`include "stim_fbank.v"

endmodule
