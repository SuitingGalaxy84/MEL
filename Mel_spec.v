module Mel_spec #(
    parameter WIDTH             = 16,
    parameter N_FRAMES          = 101,
    parameter N_FFT             = 512,
    parameter WIN_LEN           = 480,
    parameter HOP_LEN           = 160,
    parameter MEL_BANDS         = 40,

    // Derived parameters for module instantiation
    parameter N_FFT_MAX         = $clog2(N_FFT),
    parameter WIN_LEN_MAX       = $clog2(WIN_LEN),
    parameter HOP_LEN_MAX       = $clog2(HOP_LEN),
    parameter SPEC_ADDR_WIDTH   = $clog2(N_FRAMES * MEL_BANDS)
) (
    input                       clk,
    input                       rst_n,
    
    input                       start,

    input                       win_coe_lut_en,
    input [WIDTH-1:0]           win_coe, // window coeff data
   
    input [WIDTH-1:0]           signal_re, // real input signal
    input [WIDTH-1:0]           signal_im, // imag input signal
    output[WIDTH-1:0]           mel_data,

    output                      mel_avail
);

    wire pwd_odata_en;
    wire [2*WIDTH-1:0] stft_odata_raw; // STFT output
    wire [WIDTH-1:0] fft_bin; // Q1.15 power spectrum value
    localparam FFT_IDX_WIDTH = $clog2(N_FFT/2+1);
    assign fft_bin = stft_odata_raw[WIDTH-1:0];
    wire [FFT_IDX_WIDTH-1:0] fft_bin_idx;
    
    BIN_CNT#(
        .WIDTH(WIDTH),
        .N_FFT(N_FFT),
        .MEL_BANDS(MEL_BANDS)
    ) BIN_CNT_inst (
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .pwd_odata_en       (pwd_odata_en       ),
        .fft_bin_idx        (fft_bin_idx        )
    );
    

    // STFT module instance: Obtain Power Spectrum
    STFT #(
        .WIDTH              (WIDTH          ),
        .N_FFT_MAX          (N_FFT_MAX      ),
        .WIN_LEN_MAX        (WIN_LEN_MAX    ),
        .HOP_LEN_MAX        (HOP_LEN_MAX    )
    ) STFT_inst (
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .lut_en             (win_coe_lut_en     ),
        .den                (start              ),
        .n_fft              (N_FFT              ),
        .win_len            (WIN_LEN            ),
        .hop_len            (HOP_LEN            ),
        .is_real            (1'b1               ),
        .pow2               (1'b1               ),
        .win_coe            (win_coe            ),
        .din_re             (signal_re          ),
        .din_im             (signal_im          ),
        .data_full          (data_full          ),
        .stft_odata         (stft_odata_raw     ), 
        .pwd_odata_en       (pwd_odata_en       ),
        .cpx_odata_en       ()
    );


    MEL_FBANK #(
        .WIDTH      (WIDTH),
        .N_MEL      (MEL_BANDS),
        .N_FFT      (N_FFT)
    ) MEL_FBANK_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        .fft_bin_vld        (pwd_odata_en),
        .fft_bin            (fft_bin),
        .fft_bin_idx        (fft_bin_idx),
        .mel_spec_vld       (mel_avail),
        .mel_spec           (mel_data)
    );

endmodule
