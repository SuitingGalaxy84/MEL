`timescale 1ns / 1ps

module tb_Window_lut;

    // Parameters
    localparam CLK_PERIOD = 10;  // 10ns clock period (100MHz)
    localparam WIDTH = 16;
    localparam N_FFT = 512;
    localparam WIN_LEN = 480;
    localparam HOP_LEN = 160;
    localparam BUF_DEPTH = 1 << $clog2(WIN_LEN);
    localparam ADDR_WIDTH = $clog2(BUF_DEPTH);
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg den;
    reg [WIDTH-1:0] din_re;
    reg [WIDTH-1:0] din_im;
    wire dout_en;
    wire [WIDTH-1:0] dout_re;
    wire [WIDTH-1:0] dout_im;
    wire data_full;
    wire data_empty;
    wire [ADDR_WIDTH-1:0] buf_count;
    // File handles
    integer input_file;
    integer output_file;
    integer scan_result;
    integer frame_log_file;

    initial begin
        input_file     = 0;
        output_file    = 0;
        frame_log_file = 0;
    end
    
    // Test control variables
    integer sample_count;
    integer frame_count;
    reg dout_en_q;
    integer frame_sample_counter;
    integer hop_violation_count;
    integer frame_len_violation_count;
    integer prev_frame_start_sample;

    initial begin
        dout_en_q                = 1'b0;
        frame_sample_counter     = 0;
        hop_violation_count      = 0;
        frame_len_violation_count= 0;
        prev_frame_start_sample  = 0;
        frame_count              = 0;
    end

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
        .dout_im(dout_im),
        .data_full(data_full),
        .data_empty(data_empty),
        .buf_count(buf_count)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Output monitor and buffer-control tracking
    always @(posedge clk) begin
        dout_en_q <= dout_en;

        if (frame_log_file != 0) begin
            $fwrite(frame_log_file, "%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%0d\t\t%h\t\t%h\n",
            rst_n, 
            dut.den, dut.dout_en, 
            dut.r_idx_ptr, buf_count, 
            data_full, data_empty, 
            dut.CIRCULAR_BUFFER_inst.write_ptr,dut.CIRCULAR_BUFFER_inst.read_ptr,
            dut.CIRCULAR_BUFFER_inst.init_write_ptr, dut.CIRCULAR_BUFFER_inst.init_read_ptr,
            dut.buf_rd_jump, dut.frm_init,
            dout_re, dout_im);
        end

        if (!rst_n) begin
            frame_sample_counter      <= 0;
            hop_violation_count       <= 0;
            frame_len_violation_count <= 0;
            prev_frame_start_sample   <= 0;
            frame_count               <= 0;
        end else begin
            
            if (dout_en) begin
                $fwrite(output_file, "%04h %04h\n", dout_re, dout_im);
                // $display("Time %0t: Output [%0d] - RE: %d (0x%h), IM: %d (0x%h)", 
                        //  $time, frame_sample_counter, $signed(dout_re), dout_re, $signed(dout_im), dout_im);
            end
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
        output_file = $fopen("output.txt", "w");
        if (output_file == 0) begin
            $display("ERROR: Could not open output.txt");
            $finish;
        end

        // Frame log for buffer analysis
        frame_log_file = $fopen("frame_log.txt", "w");
        $fwrite(frame_log_file, "rst_n\t\tdien\t\tdoen\t\tptr\t\tcnt\t\tfull\t\tempty\t\tw_ptr\t\tr_ptr\t\tiw_ptr\t\tir_ptr\t\tjump\t\tinit\t\tre\t\tim\n");
        if (frame_log_file == 0) begin
            $display("ERROR: Could not open frame_log.txt");
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
        input_file = $fopen("input.txt", "r");
        if (input_file == 0) begin
            $display("ERROR: Could not open input.txt");
            $fclose(output_file);
            $fclose(frame_log_file);
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
                // $display("Time %0t: Input [%0d] - RE: %d (0x%h), IM: %d (0x%h)", 
                        //  $time, sample_count, $signed(din_re), din_re, $signed(din_im), din_im);
                
                sample_count = sample_count + 1;
                @(posedge clk);
            end else begin
                $display("Warning: Failed to read input at sample %0d", sample_count);
            end
        end

        // Continue for a few more cycles to capture any remaining outputs
        den = 0;
        repeat(N_FFT + 1000) @(posedge clk);

        // Close files
        $fclose(input_file);
        input_file = 0;
        $fclose(output_file);
        output_file = 0;
        $fclose(frame_log_file);
        frame_log_file = 0;

        $display("\n=== Test Completed ===");
        $display("Total input samples: %0d", sample_count);
        $display("Observed frames: %0d", frame_count);
        $display("Hop violations   : %0d", hop_violation_count);
        $display("Frame length errs : %0d", frame_len_violation_count);
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
        output_file = 0;
        if (frame_log_file != 0) begin
            $fclose(frame_log_file);
            frame_log_file = 0;
        end
        $finish;
    end

    // Optional: Generate VCD for waveform viewing
    initial begin
        $dumpfile("tb_window_lut.vcd");
        $dumpvars(0, tb_Window_lut);
    end

endmodule
