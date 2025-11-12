module PP_BUFFER#(
    parameter WIDTH = 8,
    parameter DEPTH = 128,
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
    input wire clk, // System clock
    input wire rst_n, // Active-low reset
    input wire [WIDTH-1:0] data_in,// Input data
    input wire data_valid, // Data valid signal
    output reg [WIDTH-1:0] data_out, // Output data
    output reg data_ready, // Data ready signal
    output full,
    output empty
);
    reg [WIDTH-1:0] buffer1 [0:DEPTH-1]; // First buffer
    reg [WIDTH:0] buffer2 [0:DEPTH-1]; // Second buffer
    reg [ADDR_WIDTH-1:0] write_ptr; // Write pointer
    reg [ADDR_WIDTH-1:0] read_ptr; // Read pointer
    reg active_buffer; // 0: buffer1 active, 1: buffer2 active

    reg buffer_1_full;
    reg buffer_2_full;
    reg buffer_1_empty;
    reg buffer_2_empty;
    reg first_frame;

    assign full = buffer_1_full && buffer_2_full;
    assign empty = buffer_1_empty && buffer_2_empty || first_frame;



   function [ADDR_WIDTH-1:0] bit_reverse;
        input [ADDR_WIDTH-1:0] in;
        integer i;
        begin
            // Build the reversed-bit vector bit-by-bit
            for (i = 0; i < ADDR_WIDTH; i = i + 1)
                bit_reverse[i] = in[ADDR_WIDTH-1-i];
        end
    endfunction
    
   always @(posedge clk or negedge rst_n) begin
       if (!rst_n) begin
            write_ptr       <= 0;
            read_ptr        <= 0;
            active_buffer   <= 0;
            data_ready      <= 0;
            buffer_1_full   <= 0;
            buffer_2_full   <= 0; 
            buffer_1_empty  <= 1;
            buffer_2_empty  <= 1;
            first_frame     <= 1;

        end else begin
            if (data_valid) begin
                // Write to the active buffer
                if (active_buffer == 0)
                    buffer1[bit_reverse(write_ptr)] <= data_in;
                else
                    buffer2[bit_reverse(write_ptr)] <= data_in;
                write_ptr <= write_ptr + 1;
                // Switch buffers when full
                if (write_ptr == DEPTH-1) begin
                    write_ptr <= 0;
                    active_buffer <= ~active_buffer;
                    first_frame <= 0;


                    if (active_buffer == 0) begin
                        buffer_1_full <= 1;
                    end else
                        buffer_2_full <= 1;
                end
            end
            // Read from the inactive buffer
            if (read_ptr < DEPTH) begin
                if (active_buffer == 0)
                    data_out <= buffer2[read_ptr];
                else
                    data_out <= buffer1[read_ptr];
                read_ptr <= read_ptr + 1;
                data_ready <= 1 && !empty;

                if (active_buffer == 0)
                    buffer_2_empty <= (read_ptr == DEPTH-1) ? 1 : 0;
                else
                    buffer_1_empty <= (read_ptr == DEPTH-1) ? 1 : 0;

            end else begin
                read_ptr <= 0;
                data_ready <= 0;
            end
            if (buffer_1_empty && buffer_2_empty)
                first_frame <= 1;
        end
    end

endmodule