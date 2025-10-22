//----------------------------------------------------------------------
// Test Stimuli for MEL_FBANK
//----------------------------------------------------------------------

initial begin : STIM
    wait (rst_n == 1);
    wait (rst_n == 1); // ensure reset asserted
    repeat(10) @(posedge clk);

    fork
        begin : FFT_BIN_FEED
            integer i;
            // Feed 257 FFT bins sequentially using generated random Q1.15 values
            for (i = 0; i < 257; i = i + 1) begin
                @(posedge clk);
                fft_bin_idx = i;
                fft_bin_vld = 1;
                fft_bin = fft_bin_mem[i];  // Use pre-loaded random FFT bin values
            end
            fft_bin_vld = 0;
        end
        begin : MEL_SPEC_CAPTURE
            // Capture mel_spec outputs for 300 cycles
            integer n;
            n = 0;
            while (n < 300) begin
                @(posedge clk);
                if (mel_spec_vld) begin
                    $fdisplay(1, "%0d %h", $time, mel_spec);
                end
                n = n + 1;
            end
        end
    join

    repeat(10) @(posedge clk);
    $finish;
end

initial begin : TIMEOUT
    repeat(10000) #10; // timeout
    $display("[FAILED] MEL_FBANK simulation timed out.");
    $finish;
end
