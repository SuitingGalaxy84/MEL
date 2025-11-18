
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Electronic Science and Technology of China
// Engineer: Sun Yucheng
// 
// Create Date: 2025-11-17
// Design Name: MEL Spectrum Front-End
// Module Name: MEL_SPEC
// Project Name: MEL
// Target Devices: FPGA (e.g. Xilinx)
// Tool Versions: Vivado 2020.2+
// Description:
//   Top-level module to produce Mel-spectrogram frames from a stream of complex
//   input samples. The module instantiates an STFT power-spectrum generator
//   (STFT_PW2), a ping-pong / packet buffer (PP_BUFFER) to reorder FFT bins,
//   a bin counter (BIN_CNT) for indexing, and a Mel filterbank (MEL_FBANK).
//   It outputs MEL_BANDS-wide mel spectral values (fixed-point, WIDTH bits)
//   along with a valid strobe.
//
// Parameters:
//   WIDTH      - bit-width of internal fixed-point data (e.g. Q1.(WIDTH-1))
//   N_FRAMES   - number of frames to process (top-level usage, optional)
//   N_FFT      - FFT length
//   WIN_LEN    - analysis window length (samples)
//   HOP_LEN    - hop/shift length between consecutive frames (samples)
//   MEL_BANDS  - number of mel filterbank output bands
//   N_FFT_MAX, WIN_LEN_MAX, HOP_LEN_MAX - derived widths for counters
//
// Ports:
//   clk         - system clock
//   rst_n       - active-low synchronous reset
//   signal_en   - input sample valid
//   signal_re   - input sample (real), WIDTH-bit fixed-point
//   signal_im   - input sample (imag), WIDTH-bit fixed-point
//   mel_data    - output mel spectral value (WIDTH-bit)
//   mel_avail   - output valid strobe for mel_data
//
// Dependencies:
//   STFT_PW2.v     - computes per-bin power spectrum from complex samples
//   PP_BUFFER.v    - buffer/reorder FFT bins for downstream processing
//   BIN_CNT.v      - generates FFT bin indices for mel mapping
//   MEL_FBANK.v    - applies mel filterbank to power-spectrum bins
//
// Revision:
//   1.0 - Initial implementation: wire-up of STFT_PW2, PP_BUFFER, BIN_CNT, MEL_FBANK
//
// Additional Comments:
//   - Fixed-point format and scaling are determined by the STFT_PW2 / MEL_FBANK
//     implementations. Ensure consistent Q-formats across modules.
//   - This module focuses on streaming operation; external logic should manage
//     frame-level control (e.g. start/stop, frame counters) if required.


//////////////////////////////////////////////////////////////////////////////////


module MEL_SPEC #(
    parameter WIDTH             = 16,
    parameter N_FRAMES          = 101,
    parameter N_FFT             = 512,
    parameter WIN_LEN           = 480,
    parameter HOP_LEN           = 160,
    parameter MEL_BANDS         = 40,

    // Derived parameters for module instantiation
    parameter N_FFT_MAX         = $clog2(N_FFT),
    parameter WIN_LEN_MAX       = $clog2(WIN_LEN),
    parameter HOP_LEN_MAX       = $clog2(HOP_LEN)
) (
    input                       clk,
    input                       rst_n,
    // Data Channel
    input                       signal_en,   
    input [WIDTH-1:0]           signal_re, // real input signal
    input [WIDTH-1:0]           signal_im, // imag input signal
    output[WIDTH-1:0]           mel_data,
    output                      mel_avail
    // Response Channel
    output                     fft_1_rdy,
    output                     fft_2_rdy,
    output                     buf_full,
    output                     buf_empty
);

    wire [WIDTH-1:0] stft_pw2_data; // Q1.15 power spectrum value
    wire stft_data_en;
    wire [WIDTH-1:0] stft_bin_reordered;
    wire stft_bin_reordered_rdy;

    localparam FFT_IDX_WIDTH = $clog2(N_FFT/2+1);
    wire [FFT_IDX_WIDTH-1:0] stft_bin_idx;
    
    BIN_CNT#(
        .WIDTH(WIDTH),
        .N_FFT(N_FFT),
        .MEL_BANDS(MEL_BANDS)
    ) BIN_CNT_inst (
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .pwd_odata_en       (stft_bin_reordered_rdy ),
        .stft_bin_idx        (stft_bin_idx          )
    );
    

    // STFT module instance: Obtain Power Spectrum
    STFT_PW2 #(
        .WIDTH              (WIDTH          ),
        .N_FFT              (N_FFT          ),
        .WIN_LEN            (WIN_LEN        ),
        .HOP_LEN            (HOP_LEN        )
    ) STFT_PW2_inst (
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .den                (signal_en          ),
        .din_re             (signal_re          ),
        .din_im             (signal_im          ),
        .stft_data_en       (stft_data_en       ),
        .stft_pw2_data      (stft_pw2_data      ),
        .buf_full           (buf_full           ),
        .buf_empty          (buf_empty          ),
        .fft_1_rdy          (fft_1_rdy          ),
        .fft_2_rdy          (fft_2_rdy          )
    );

    MEL_FBANK #(
        .WIDTH      (WIDTH),
        .N_MEL      (MEL_BANDS),
        .N_FFT      (N_FFT)
    ) MEL_FBANK_inst (
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .stft_bin_vld       (stft_bin_reordered_rdy  ),
        .stft_bin           (stft_bin_reordered      ),
        .stft_bin_idx       (stft_bin_idx            ),
        .mel_spec_vld       (mel_avail              ),
        .mel_spec           (mel_data               )
    );

    PP_BUFFER #(
        .WIDTH(WIDTH),
        .DEPTH(N_FFT / 2 + 1)
    ) PP_BUFFER_inst (
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .data_in            (stft_pw2_data          ),
        .data_valid         (stft_data_en           ),
        .data_out           (stft_bin_reordered     ),
        .data_ready         (stft_bin_reordered_rdy )
    );
    
endmodule
