`timescale 1ns / 1ps

module tb_BRR_PP;

    // Parameters matching the DUT and verification script
    localparam ADDR_WIDTH = 7;
    localparam DATA_WIDTH = 16;
    localparam DEPTH      = 1 << ADDR_WIDTH; // Should be 128
    localparam CLK_PERIOD = 10;

    // Testbench signals
    reg                      clk;
    reg                      rst;
    reg                      wr_en;
    reg                      rd_en;
    reg  [DATA_WIDTH-1:0]    data_in;

    wire [DATA_WIDTH-1:0]    data_out;
    wire                     buffer_full;
    wire                     buffer_empty;

    // Instantiate the DUT (Device Under Test)
    BRR_PP #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .buffer_full(buffer_full),
        .buffer_empty(buffer_empty)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Main stimulus block
    initial begin
        // 1. Initialize and Reset
        $display("Starting testbench...");
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;
        #(CLK_PERIOD * 5);
        rst = 0;
        #(CLK_PERIOD);

        // Wait for reset to de-assert
        @(posedge clk);
        $display("Reset released. Starting data transmission.");

        // 2. Write the first frame of data (to Buffer A)
        $display("Writing Frame 0...");
        write_frame(0);

        // After writing, the 'other' buffer is now ready for reading.
        // We must wait one cycle for the read address to be registered.
        @(posedge clk);

        // 3. Simultaneously READ Frame 0 (from Buffer A) and WRITE Frame 1 (to Buffer B)
        $display("Concurrently Reading Frame 0 and Writing Frame 1...");
        fork
            read_frame();
            write_frame(1);
        join
        
        // Wait one cycle for read address to be registered.
        @(posedge clk);

        // 4. Read the second frame of data (from Buffer B)
        $display("Reading Frame 1...");
        read_frame();

        // End of test
        #(CLK_PERIOD * 10);
        $display("Test finished.");
        $finish;
    end

    function [ADDR_WIDTH-1:0] bit_reverse;
        input [ADDR_WIDTH-1:0] in;
        integer i;
        begin
            for (i = 0; i < ADDR_WIDTH; i = i + 1)
                bit_reverse[i] = in[ADDR_WIDTH-1-i];
        end
    endfunction

    // Task to write one frame of data
    task write_frame;

        
        input integer frame_num;
        integer i;
        begin
            wr_en = 1;
            #CLK_PERIOD;
            for (i = 0; i < DEPTH; i = i + 1) begin
                
                // Send sequential data values
                data_in = bit_reverse(i) + frame_num * DEPTH;
                #CLK_PERIOD;
            end
            @(posedge clk);
            wr_en = 0;
        end
    endtask

    // Task to read one frame of data
    task read_frame;
        integer i;
        begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                @(posedge clk);
                rd_en = 1;
            end
            @(posedge clk);
            rd_en = 0;
        end
    endtask

    // Monitor: Save output data to a file for verification
    integer outfile;
    initial begin
        // Setup simulation dump
        $dumpfile("tb_brr_pp.vcd");
        $dumpvars(0, tb_BRR_PP);

        // Open file for output
        outfile = $fopen("output.txt", "w");
        
        // Forever loop to monitor the output
        forever @(posedge clk) begin
            // Data is valid on the cycle that rd_en is high
            if (rd_en) begin
                #CLK_PERIOD; // Wait for data_out to stabilize
                $fdisplay(outfile, "%d %d", data_out, 0);
            end
        end
    end

endmodule
