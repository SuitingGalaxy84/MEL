module WIN_BUFFER #(
    parameter DATA_WIDTH = 16,
    parameter WIN_LEN = 480,      // Window length
    parameter HOP_LEN = 160,      // Hop length (WIN_LEN/HOP_LEN must be integer)
    parameter ADDR_WIDTH = $clog2(WIN_LEN)
)(
    input wire clk,
    input wire rst_n,
    
    // Write interface - HOP_LEN samples at a time
    input wire write_en,                    // Enable writing HOP_LEN samples
    input wire [DATA_WIDTH-1:0] data_in,    // Input data (one sample per cycle)
    input wire data_valid,                  // Data valid signal for current sample
    
    // Read interface - Read WIN_LEN samples
    input wire read_en,                     // Enable reading
    input wire [ADDR_WIDTH-1:0] read_addr,  // Read address (0 to WIN_LEN-1)
    output reg [DATA_WIDTH-1:0] data_out,   // Output data
    
    // Status signals
    output reg buffer_ready,                // Buffer has valid WIN_LEN window
    output reg write_ready,                 // Ready to accept new HOP_LEN samples
    output reg frame_available              // Complete frame available for processing
);

    // Calculate number of hop segments in window
    localparam NUM_HOPS = WIN_LEN / HOP_LEN;
    
    // Internal buffer storage
    reg [DATA_WIDTH-1:0] buffer [0:WIN_LEN-1];
    
    // Write state tracking
    reg [ADDR_WIDTH-1:0] write_count;       // Count samples written in current hop
    reg [$clog2(NUM_HOPS):0] hops_written;  // Number of hops written
    reg first_frame_done;                    // Flag indicating first frame completion
    
    // Generate initial value check at compile time
    initial begin
        if (WIN_LEN % HOP_LEN != 0) begin
            $display("ERROR: WIN_LEN (%0d) must be divisible by HOP_LEN (%0d)", WIN_LEN, HOP_LEN);
            $finish;
        end
    end
    
    // Write logic - shift buffer and write new HOP_LEN samples
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_count <= 0;
            hops_written <= 0;
            first_frame_done <= 0;
            write_ready <= 1;
            buffer_ready <= 0;
            frame_available <= 0;
            
            // Initialize buffer to zeros
            for (i = 0; i < WIN_LEN; i = i + 1) begin
                buffer[i] <= 0;
            end
        end else begin
            // Handle write operation
            if (write_en && data_valid && write_ready) begin
                // Shift existing data by one position (discard oldest sample)
                for (i = 0; i < WIN_LEN - 1; i = i + 1) begin
                    buffer[i] <= buffer[i + 1];
                end
                
                // Write new sample at the end
                buffer[WIN_LEN - 1] <= data_in;
                
                // Update write counter
                if (write_count == HOP_LEN - 1) begin
                    write_count <= 0;
                    write_ready <= 0;  // Not ready until next hop request
                    frame_available <= 1;  // Frame available for processing
                    
                    // Update hop tracking
                    if (hops_written < NUM_HOPS) begin
                        hops_written <= hops_written + 1;
                    end
                    
                    // Mark buffer ready once we have full window
                    if (hops_written == NUM_HOPS - 1) begin
                        first_frame_done <= 1;
                        buffer_ready <= 1;
                    end
                end else begin
                    write_count <= write_count + 1;
                end
            end
            
            // Clear frame_available when read starts
            if (read_en && frame_available) begin
                frame_available <= 0;
                write_ready <= 1;  // Ready for next hop after read starts
            end
        end
    end
    
    // Read logic - asynchronous read from buffer
    always @(*) begin
        if (buffer_ready && read_addr < WIN_LEN) begin
            data_out = buffer[read_addr];
        end else begin
            data_out = 0;
        end
    end

endmodule
