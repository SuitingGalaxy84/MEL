//----------------------------------------------------------------------
//  Bit-Reversal Reordering with Ping-Pong Buffer (Register File based)
//  Converts FFT bit-reversed output to natural order.
//  It accepts bit-reversed data and outputs it in natural order.
//----------------------------------------------------------------------
module BRR_PP #(
    parameter N = 128,              // FFT size (must be power of 2)
    parameter BITS = 7,             // log2(N) - address width
    parameter WIDTH = 16            // Data width for real/imag components
)(
    input                   clock,
    input                   reset,
    
    // Input: bit-reversed FFT output
    input                   di_en,
    input  [WIDTH-1:0]      di_re,
    input  [WIDTH-1:0]      di_im,
    
    // Output: natural order
    output reg              do_en,
    output reg [WIDTH-1:0]  do_re,
    output reg [WIDTH-1:0]  do_im
);

//----------------------------------------------------------------------
//  Ping-Pong Dual-Port Register File
//  Buffer A and Buffer B alternate between write and read
//----------------------------------------------------------------------
reg [WIDTH-1:0] bufA_re [0:N-1];
reg [WIDTH-1:0] bufA_im [0:N-1];
reg [WIDTH-1:0] bufB_re [0:N-1];
reg [WIDTH-1:0] bufB_im [0:N-1];

//----------------------------------------------------------------------
//  Control Logic
//----------------------------------------------------------------------
reg                 buf_sel;        // 0: Write to A, Read from B
                                    // 1: Write to B, Read from A
reg [BITS-1:0]      wr_cnt;         // Write counter (sequential)
reg [BITS-1:0]      rd_cnt;         // Read counter (sequential)
reg                 wr_active;      // Write operation active
reg                 rd_active;      // Read operation active
reg                 first_frame;    // Flag to prevent reading before first write is complete

//----------------------------------------------------------------------
//  Bit-Reverse Function
//  Reverses the bit order of the input address
//----------------------------------------------------------------------
function [BITS-1:0] bit_reverse;
    input [BITS-1:0] in;
    integer i;
    begin
        bit_reverse = 0;
        for (i = 0; i < BITS; i = i + 1)
            bit_reverse[i] = in[BITS-1-i];
    end
endfunction

//----------------------------------------------------------------------
//  Address Generation
//  Input is in bit-reversed order. We write to a bit-reversed address
//  so the data is stored in natural order. Reading is done sequentially.
//----------------------------------------------------------------------
wire [BITS-1:0] wr_addr = bit_reverse(wr_cnt);
wire [BITS-1:0] rd_addr = rd_cnt;

//----------------------------------------------------------------------
//  Write Logic - Buffer Switching
//----------------------------------------------------------------------
always @(posedge clock) begin
    if (reset) begin
        wr_cnt <= 0;
        wr_active <= 0;
        buf_sel <= 0;
        first_frame <= 1;
    end else begin
        if (di_en) begin
            wr_active <= 1;
            
            // Write to the currently active write buffer
            if (buf_sel == 0) begin // Write to A
                bufA_re[wr_addr] <= di_re;
                bufA_im[wr_addr] <= di_im;
            end else begin // Write to B
                bufB_re[wr_addr] <= di_re;
                bufB_im[wr_addr] <= di_im;
            end
            
            // Increment write counter and swap buffers when full
            if (wr_cnt == N-1) begin
                wr_cnt <= 0;
                buf_sel <= ~buf_sel;    // Swap buffers for next frame
                first_frame <= 0;       // First frame is now written
                wr_active <= 0;         // Finished writing this frame
            end else begin
                wr_cnt <= wr_cnt + 1;
            end
        end
    end
end

//----------------------------------------------------------------------
//  Read Logic - Buffer Switching
//----------------------------------------------------------------------
always @(posedge clock) begin
    if (reset) begin
        rd_cnt <= 0;
        rd_active <= 0;
        do_en <= 0;
    end else begin
        // Start reading a frame when the other buffer is full
        if (wr_cnt == N-1 && di_en) begin
             rd_active <= 1;
        end

        if (rd_active && !first_frame) begin
            // Read from the inactive write buffer (the one that's full)
            if (buf_sel == 0) begin // Read from B
                do_re <= bufB_re[rd_addr];
                do_im <= bufB_im[rd_addr];
            end else begin // Read from A
                do_re <= bufA_re[rd_addr];
                do_im <= bufA_im[rd_addr];
            end
            do_en <= 1;
            
            // Increment read counter
            if (rd_cnt == N-1) begin
                rd_cnt <= 0;
                rd_active <= 0; // Finished reading frame
                do_en <= 0;
            end else begin
                rd_cnt <= rd_cnt + 1;
            end
        end else begin
            do_en <= 0;
        end
    end
end


////  Read Logic - Sequential Output in Natural Order
////----------------------------------------------------------------------
//reg rd_buf_sel;  // Read buffer selection (opposite of write buffer)

//always @(posedge clock) begin
//    if (reset) begin
//        rd_cnt <= 0;
//        rd_active <= 0;
//        rd_buf_sel <= 1;  // Start reading from opposite buffer
//        do_en <= 0;
//        do_re <= 0;
//        do_im <= 0;
//    end else begin
//        // Start reading when first frame is complete and we're not currently writing to this buffer
//        if (!first_frame && !rd_active) begin
//            rd_active <= 1;
//            rd_cnt <= 0;
//        end
        
//        if (rd_active) begin
//            // Read from the buffer that's not being written to
//            if (rd_buf_sel == 0) begin
//                do_re <= bufA_re[rd_cnt];
//                do_im <= bufA_im[rd_cnt];
//            end else begin
//                do_re <= bufB_re[rd_cnt];
//                do_im <= bufB_im[rd_cnt];
//            end
            
//            do_en <= 1;
            
//            // Increment read counter
//            if (rd_cnt == N-1) begin
//                rd_cnt <= 0;
//                rd_active <= 0;
//                rd_buf_sel <= ~rd_buf_sel;  // Swap read buffer
//            end else begin
//                rd_cnt <= rd_cnt + 1;
//            end
//        end else begin
//            do_en <= 0;
//        end
//    end
//end

//----------------------------------------------------------------------
//  Synthesis Notes:
//  - Total RAM: 2 * N * 2 * WIDTH bits
//  - For N=128, WIDTH=16: 8192 bits (1 KB)
//  - Latency: N clock cycles (one frame delay)
//  - Throughput: Continuous streaming (no gaps after first frame)
//----------------------------------------------------------------------

endmodule
