`timescale 1ns / 1ps

module tb_BitRevReorder;

    // Parameters
    localparam N = 128;
    localparam BITS = 7;
    localparam WIDTH = 16;
    localparam CLK_PERIOD = 10;

    // Testbench signals
    reg                 clock;
    reg                 reset;
    reg                 di_en;
    reg  [WIDTH-1:0]    di_re;
    reg  [WIDTH-1:0]    di_im;

    wire                do_en;
    wire [WIDTH-1:0]    do_re;
    wire [WIDTH-1:0]    do_im;

    // Instantiate the DUT
    BitRevReorder #(
        .N(N),
        .BITS(BITS),
        .WIDTH(WIDTH)
    ) DUT (
        .clock(clock),
        .reset(reset),
        .di_en(di_en),
        .di_re(di_re),
        .di_im(di_im),
        .do_en(do_en),
        .do_re(do_re),
        .do_im(do_im)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clock = ~clock;

    // Stimulus
    initial begin
        // Initialize signals
        clock = 0;
        reset = 1;
        di_en = 0;
        di_re = 0;
        di_im = 0;

        // Reset sequence
        #100;
        reset = 0;
        #100;
        reset = 1;
        
        // Wait for reset to propagate
        @(posedge clock);
        reset = 0;
        @(posedge clock);

        // Send two frames of data
        send_frame(0);
        send_frame(1);

        #2000;
        $finish;
    end

    // Task to send one frame of data
    task send_frame;
        input frame_num;
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(posedge clock);
                di_en = 1;
                di_re = i + frame_num * N;
                di_im = N - 1 - i + frame_num * N;
            end
            @(posedge clock);
            di_en = 0;
        end
    endtask

    // Monitor and save output to a file
    initial begin
        // File for verification - Declaration must be before use.
        integer outfile;

        $dumpfile("tb_BitRevReorder.vcd");
        $dumpvars(0, tb_BitRevReorder);
        $monitor("Time: %0t, di_en: %b, di_re: %d, di_im: %d -> do_en: %b, do_re: %d, do_im: %d",
                 $time, di_en, di_re, di_im, do_en, do_re, do_im);
        
        outfile = $fopen("output.txt", "w");
        
        forever @(posedge clock) begin
            if (do_en) begin
                $fdisplay(outfile, "%d %d", do_re, do_im);
            end
        end
    end


endmodule
