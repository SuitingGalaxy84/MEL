`timescale 1ns / 1ps

module tb_PP_BUFFER;

    // Parameters
    localparam CLK_PERIOD = 10; // Clock period: 10 ns
    localparam BUFFER_SIZE = 128;
    localparam DATA_WIDTH = 8;

    // Testbench Signals
    reg clk;
    reg rst_n;
    reg [DATA_WIDTH-1:0] data_in;
    reg data_valid;
    wire [DATA_WIDTH-1:0] data_out;
    wire data_ready;
    wire empty, full;

    // Instantiate the Device Under Test (DUT)
    PP_BUFFER dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_out),
        .data_ready(data_ready),
        .empty(empty),
        .full(full)
    );

    // 1. Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    localparam ADDR_WIDTH = $clog2(128);
    
    // Task to write a full frame of data
    function [ADDR_WIDTH-1:0] bit_reverse;
        input [ADDR_WIDTH-1:0] in;
        integer i;
        begin
            // Build the reversed-bit vector bit-by-bit
            for (i = 0; i < ADDR_WIDTH; i = i + 1)
                bit_reverse[i] = in[ADDR_WIDTH-1-i];
        end
    endfunction
    
    task write_frame;
        input integer start_value;
        integer i;
        begin
            $display("Task: Starting to write a new frame at time %0t", $time);
            data_valid = 1;
            for (i = 0; i < BUFFER_SIZE; i = i + 1) begin
                data_in = start_value + bit_reverse(i);
                @(posedge clk);
            end
            data_valid = 0;
            $display("Task: Finished writing frame at time %0t", $time);
        end
    endtask

    // 2. Main Test Sequence
    initial begin
        // --- Reset Phase ---
        $display("Starting Testbench...");
        rst_n = 1; // De-assert reset initially
        data_valid = 0;
        data_in = 0;
        #5;
        rst_n = 0; // Assert active-low reset
        $display("Reset Applied (rst_n = 0)");
        #(CLK_PERIOD * 2);
        rst_n = 1; // Release reset
        $display("Reset Released (rst_n = 1)");
        @(posedge clk);

        // --- Test Phase 1: Write to Buffer 1 ---
        // During this time, the DUT is reading from Buffer 2, which contains
        // default/zero values since it hasn't been written to yet.
        $display("Beginning to write Frame 1 into Buffer 1...");
        write_frame(0); // Write values 10, 11, ..., 137 into Buffer 1

        // After the write, the buffers will switch. Writing will now target Buffer 2,
        // and reading will start from Buffer 1 (which now holds our data).
        // Let's wait a few cycles to clearly see the switch in the simulation.
        #(CLK_PERIOD * 3);
        $display("Switch complete. Reading from Buffer 1 should now begin.");
        
        // --- Test Phase 2: Write to Buffer 2 and Read from Buffer 1 ---
        // We will start writing the next frame into Buffer 2.
        // Simultaneously, data_out should be showing the contents of Buffer 1.
        $display("Beginning to write Frame 2 (into Buffer 2) and read Frame 1.");
        write_frame(150); // Write values 150, 151, ... into Buffer 2

        // After this write, the buffers switch again.
        #(CLK_PERIOD * 3);
        $display("Switch complete. Reading from Buffer 2 should now begin.");

        // --- Test Phase 3: Idle and verify reading from Buffer 2 ---
        // Let the simulation run for a while to observe the output from Buffer 2.
        $display("Verifying output of Frame 2 from Buffer 2...");
        #(CLK_PERIOD * (BUFFER_SIZE + 5));

        // --- End Simulation ---
        $display("Test Complete.");
        $finish;
    end

    // 3. Monitor Block
    // This will display the values of the signals whenever they change.
    initial begin
        $monitor("Time=%0t | rst_n=%b data_valid=%b write_ptr=%d read_ptr=%d active_buf=%b | data_in=%d data_out=%d data_ready=%b | empty=%b full=%b",
                 $time, rst_n, data_valid, dut.write_ptr, dut.read_ptr, dut.active_buffer, data_in, data_out, data_ready, empty, full);
    end

endmodule
