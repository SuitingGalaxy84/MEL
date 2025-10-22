module STFT#(
    parameter WIDTH             = 16,
    parameter N_FFT_MAX         = $clog2(1024),
    parameter WIN_LEN_MAX       = $clog2(1024),
    parameter HOP_LEN_MAX       = $clog2(1024/2)
)(
    input                       clk,
    input                       rst_n,

    input                       lut_en, // load window coeff enable
    input                       den, // data enable, enable computation as well.
    input [N_FFT_MAX-1:0]       n_fft,
    input [WIN_LEN_MAX-1:0]     win_len,
    input [HOP_LEN_MAX-1:0]     hop_len,
    
    input                       is_real, // 1: real input, 0: complex input
    input                       pow2, // 1: power spectrum, 0: complex spectrum
    input [WIDTH-1:0]           win_coe, // window coeff data
    input [WIDTH-1:0]           din_re, // input data (real)
    input [WIDTH-1:0]           din_im, // input data (imag)
    
    output                      data_full,
    output reg [2*WIDTH-1:0]    stft_odata,
    output reg                  pwd_odata_en,
    output reg                  cpx_odata_en
);
    wire win_dout_en;
    wire fft_do_en;
    wire [WIDTH-1:0] win_dout_re;
    wire [WIDTH-1:0] win_dout_im;
    wire [WIDTH-1:0] fft_do_re;
    wire [WIDTH-1:0] fft_do_im;
    wire [WIDTH-1:0] fft_pwd_re;
    wire [WIDTH-1:0] fft_pwd_im;
    wire [WIDTH-1:0] fft_pwd_data = fft_pwd_re + fft_pwd_im;
    
    // Reset the FFT core after producing n_fft/2 + 1 outputs (one-sided output)
    reg [N_FFT_MAX-1:0] fft_out_cnt;
    reg reset_fft_internal;
    wire reset_fft = (~rst_n) | reset_fft_internal;
    wire [N_FFT_MAX-1:0] half_plus_one = (n_fft >> 1) + 1'b1;
    
    
    WIN #(
        .WIDTH          (WIDTH          ),
        .N_FFT_MAX      (N_FFT_MAX      ),
        .WIN_LEN_MAX    (WIN_LEN_MAX    ),
        .HOP_LEN_MAX    (HOP_LEN_MAX    )
    ) WIN_inst (
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .den            (den            ), // data enable, enable computation as well.
        .n_fft          (n_fft          ),
        .win_len        (win_len        ),
        .hop_len        (hop_len        ),
        .lut_en         (lut_en         ), // load window coeff enable
        .win_coe        (win_coe        ), // window coeff data
        .din_re         (din_re         ),
        .din_im         (din_im         ),
        .dout_en        (win_dout_en    ),
        .dout_re        (win_dout_re    ),
        .dout_im        (win_dout_im    ),
        .data_full      (data_full      )
    );

    FFT #(
        .WIDTH          (WIDTH          )
    ) FFT_inst (
        .clock          (clk            ),  //  Master Clock
        .reset          (reset_fft      ),  //  Active High Asynchronous Reset (driven)
        .di_en          (win_dout_en    ),  //  Input Data Enable
        .di_re          (win_dout_re    ),  //  Input Data (Real)
        .di_im          (win_dout_im    ),  //  Input Data (Imag)
        .do_en          (fft_do_en      ),  //  Output Data Enable
        .do_re          (fft_do_re      ),  //  Output Data (Real)
        .do_im          (fft_do_im      )   //  Output Data (Imag)
    );

    

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fft_out_cnt <= {N_FFT_MAX{1'b0}};
            reset_fft_internal <= 1'b0;
        end else begin
            reset_fft_internal <= 1'b0; // default
            if (fft_do_en) begin
                // count outputs; when we reach half_plus_one outputs, pulse reset
                if (fft_out_cnt + 1 >= half_plus_one) begin
                    reset_fft_internal <= 1'b1;
                    fft_out_cnt <= {N_FFT_MAX{1'b0}};
                end else begin
                    fft_out_cnt <= fft_out_cnt + 1'b1;
                end
            end
        end
    end
    


    Multiply #(
        .WIDTH          (WIDTH +1       )
    ) MU_inst1 (
        .a_re           (fft_do_re      ),
        .a_im           ({WIDTH{1'b0}}), // not used
        .b_re           (fft_do_re      ),
        .b_im           ({WIDTH{1'b0}}), // not used
        .m_re           (fft_pwd_re), // not used
        .m_im           ()  // not used
    );

    Multiply #(
        .WIDTH          (WIDTH +1       )
    ) MU_inst2 (
        .a_re           (fft_do_im      ),
        .a_im           ({WIDTH{1'b0}}), // not used
        .b_re           (fft_do_im      ),
        .b_im           ({WIDTH{1'b0}}), // not used
        .m_re           (fft_pwd_im), // not used
        .m_im           ()  // not used
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stft_odata          <= {2*WIDTH{1'b0}};
            pwd_odata_en        <= 1'b0;
            cpx_odata_en        <= 1'b0;
        end else begin
            if (pow2) begin
                stft_odata      <= {{(WIDTH-1){1'b0}}, fft_pwd_data};   
                pwd_odata_en    <= fft_do_en;
                cpx_odata_en    <= 1'b0;
            end else begin
                stft_odata      <= {fft_do_re, fft_do_im};
                pwd_odata_en    <= 1'b0;    
                cpx_odata_en    <= fft_do_en;
            end
        end
    end 

endmodule