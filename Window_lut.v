
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Electronic Science and Technology of China
// Engineer: Sun Yucheng
// 
// Create Date: 2025-11-17
// Design Name: Windowed LUT for FFT input
// Module Name: WIN_LUT
// Project Name: MEL
// Target Devices: FPGA (e.g. Xilinx)
// Tool Versions: Vivado 2020.2+
// Description:
//   WIN_LUT applies a Hann window to incoming complex samples, buffers them with
//   a circular buffer to implement overlap-add (hop length), and presents
//   windowed complex outputs for FFT ingestion. The module supports parameterized
//   data width, FFT length, window length and hop length.
//
//   - Incoming samples (din_re, din_im) are written into a circular buffer.
//   - A ROM-based Hann window (HANN_WIN_480) supplies coefficients.
//   - A multiplier scales buffered samples by the window coefficient.
//   - Outputs (dout_re, dout_im) present the windowed complex samples while
//     r_idx_ptr iterates through the FFT frame.
//
// Parameters:
//   WIDTH   - bit width of real/imag samples
//   N_FFT   - FFT frame length (address wrap length)
//   WIN_LEN - window length (number of valid samples per frame)
//   HOP_LEN - hop length between consecutive frames
//
// Dependencies:
//   - CIRCULAR_BUFFER (parameterized)
//   - HANN_WIN_480 (window coefficient ROM)
//   - Multiply (complex scalar multiplier)
//
// Revision:
//   1.00 - Header and description completed.
//
// Additional Comments:
//   Keep WIN_LEN <= N_FFT and WIN_LEN <= BUF_DEPTH. Ensure HANN_WIN_480
//   supports the configured WIN_LEN.
//////////////////////////////////////////////////////////////////////////////////


module WIN_LUT#(
    parameter WIDTH             = 16,
    parameter N_FFT             = 512,
    parameter WIN_LEN           = 480,
    parameter HOP_LEN           = 160
)(
    input                       clk,
    input                       rst_n,
    input                       den, // data enable, enable computation as well.
    input [WIDTH-1:0]           din_re,
    input [WIDTH-1:0]           din_im,
    output                      dout_en,
    output [WIDTH-1:0]          dout_re,
    output [WIDTH-1:0]          dout_im,
    output                      data_full,
    output                      data_empty,
    output [ADDR_WIDTH-1:0]     buf_count
);

    localparam BUF_DEPTH       = 2**$clog2(WIN_LEN);
    localparam ADDR_WIDTH      = $clog2(BUF_DEPTH);

    wire [2*WIDTH-1:0] data_buf_in     = {din_re, din_im};
    wire [2*WIDTH-1:0] data_mu_in;
    wire [WIDTH-1:0] coe_mu_in; 
    wire buf_rd_en;
    wire frm_init;
    
    
    reg [ADDR_WIDTH-1:0] r_idx_ptr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_idx_ptr  <= 0;
        end else begin
            if (den) begin
                r_idx_ptr  <= (r_idx_ptr == N_FFT - 1) ? 0 : r_idx_ptr + 1;
            end
        end
    end 


    assign buf_rd_en = (r_idx_ptr < WIN_LEN) ? 1'b1 : 1'b0;
    assign frm_init = (r_idx_ptr == 0) ? 1'b1 : 1'b0;

    CIRCULAR_BUFFER #(
        .WIDTH              (2*WIDTH        ),
        .WIN_LENGTH         (WIN_LEN        ),
        .HOP_LENGTH         (HOP_LEN        )
    ) CIRCULAR_BUFFER_inst (
        .clk                (clk            ),
        .rst_n              (rst_n          ),
        .frm_init           (frm_init       ),
        .wr_en              (den            ),
        .din                (data_buf_in    ),
        .full               (data_full      ),
        .rd_en              (buf_rd_en      ),
        .dout               (data_mu_in     ),
        .empty              (data_empty     ),
        .almost_empty       (               ),
        .count_r            (buf_count      )
    );

    HANN_WIN_480 HANN_WIN_inst (
        .clk                (clk            ),
        .rst_n              (rst_n          ),
        .addr               (r_idx_ptr      ),  
        .win_coe_out        (coe_mu_in      )
    );

    // --- MU Output Wires ---
    wire [WIDTH-1:0] data_mu_re;
    wire [WIDTH-1:0] data_mu_im;
    wire [WIDTH-1:0] mu_a_re = r_idx_ptr >= WIN_LEN ? 16'b0 : data_mu_in[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] mu_b_re = r_idx_ptr >= WIN_LEN ? 16'b0 : coe_mu_in;
    // --- MU Instantiation ---
    Multiply #(
        .WIDTH              (WIDTH)
    ) MU_inst (
        .a_re               (mu_a_re                    ),
        .a_im               (16'b0                      ),
        .b_re               (mu_b_re                    ),
        .b_im               (16'b0                      ),
        .m_re               (data_mu_re                 ),
        .m_im               (data_mu_im                 )
    );


    assign dout_en = r_idx_ptr != 0 & ~data_empty;
    assign dout_re = data_mu_re;
    assign dout_im = data_mu_im;


endmodule