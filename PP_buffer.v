module PP_buffer#(
    parameter WIDTH = 8,
    parameter DEPTH = 128,
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
   input wire clk, // System clock
   input wire rst_n, // Active-low reset
   input wire [WIDTH-1:0] data_in,// Input data
   input wire data_valid, // Data valid signal
   output reg [WIDTH-1:0] data_out, // Output data
   output reg data_ready // Data ready signal
);
   reg [WIDTH-1:0] buffer1 [0:DEPTH-1]; // First buffer
   reg [WIDTH:0] buffer2 [0:DEPTH-1]; // Second buffer
   reg [ADDR_WIDTH-1:0] write_ptr; // Write pointer
   reg [ADDR_WIDTH-1:0] read_ptr; // Read pointer
   reg active_buffer; // 0: buffer1 active, 1: buffer2 active
   
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
           write_ptr <= 0;
           read_ptr <= 0;
           active_buffer <= 0;
           data_ready <= 0;
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
               end
           end
           // Read from the inactive buffer
           if (read_ptr < DEPTH) begin
               if (active_buffer == 0)
                   data_out <= buffer2[read_ptr];
               else
                   data_out <= buffer1[read_ptr];
               read_ptr <= read_ptr + 1;
               data_ready <= 1;
           end else begin
               read_ptr <= 0;
               data_ready <= 0;
           end
       end
   end
endmodule