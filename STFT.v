module STFT_PW2#(
    parameter WIDTH             = 16,
    parameter N_FFT             = 512,
    parameter WIN_LEN           = 480,
    parameter HOP_LEN           = 160
)(
    input                       clk,
    input                       rst_n,

    input                       lut_en, // load window coeff enable
    input                       den, // data enable, enable computation as well.
    input [WIDTH-1:0]           win_coe, // window coeff data
    input [WIDTH-1:0]           din_re, // input data (real)
    input [WIDTH-1:0]           din_im, // input data (imag)

    output                      data_full,
    output                      stft_data_en,
    output [WIDTH-1:0]          stft_pw2_data
);
    
    wire win_do_en;
    reg fft_1_di_en, fft_2_di_en;
    wire [WIDTH-1:0] win_dout_re;
    wire [WIDTH-1:0] win_dout_im;
    wire [WIDTH-1:0] fft_1_din_re;
    wire [WIDTH-1:0] fft_1_din_im;
    wire [WIDTH-1:0] fft_2_din_re;
    wire [WIDTH-1:0] fft_2_din_im;

    wire [WIDTH-1:0] fft_1_do_re;
    wire [WIDTH-1:0] fft_1_do_im;

    always @(*) begin
        case({win_do_en, fft_1_rdy, fft_2_rdy})
            3'b0xx: begin // no window output available
                fft_1_di_en = 1'b0;
                fft_2_di_en = 1'b0;

                fft_1_din_re = {WIDTH{1'b0}};
                fft_2_din_re = {WIDTH{1'b0}};
                fft_2_din_im = {WIDTH{1'b0}};
                fft_1_din_im = {WIDTH{1'b0}};
            
            end
            3'b111: begin // both FFT available, prioritize FFT1
                fft_1_di_en = 1'b1;
                fft_2_di_en = 1'b0;
            
                fft_1_din_re = win_dout_re;
                fft_1_din_im = win_dout_im;
                fft_2_din_re = {WIDTH{1'b0}};
                fft_2_din_im = {WIDTH{1'b0}};

            end
            3'b101: begin // only FFT2 available
                fft_1_di_en = 1'b0;
                fft_2_di_en = 1'b1;

                fft_2_din_re = win_dout_re;
                fft_2_din_im = win_dout_im;
                fft_1_din_re = {WIDTH{1'b0}};
                fft_1_din_im = {WIDTH{1'b0}};

            end
            3'b110: begin // only FFT1 available
                fft_1_di_en = 1'b1;
                fft_2_di_en = 1'b0;

                fft_1_din_re = win_dout_re;
                fft_1_din_im = win_dout_im;
                fft_2_din_re = {WIDTH{1'b0}};
                fft_2_din_im = {WIDTH{1'b0}};

            end 
            default: begin
                fft_1_di_en = 1'b0;
                fft_2_di_en = 1'b0;

                fft_1_din_re = {WIDTH{1'b0}};
                fft_1_din_im = {WIDTH{1'b0}};
                fft_2_din_re = {WIDTH{1'b0}};
                fft_2_din_im = {WIDTH{1'b0}};
            end
        endcase    
    end 
    
    WIN #(
        .WIDTH          (WIDTH          ),
        .N_FFT          (N_FFT          ),
        .WIN_LEN        (WIN_LEN        ),
        .HOP_LEN        (HOP_LEN        )
    ) WIN_inst (
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .den            (den            ), // data enable, enable computation as well.
        .lut_en         (lut_en         ), // load window coeff enable
        .win_coe        (win_coe        ), // window coeff data
        .din_re         (din_re         ),
        .din_im         (din_im         ),
        .dout_en        (win_dout_en    ),
        .dout_re        (win_dout_re    ),
        .dout_im        (win_dout_im    ),
        .data_full      (data_full      )
    );

    // Ping-Pong FFT
    FFT512 #(
        .WIDTH          (WIDTH          )
    ) FFT_inst_1 (
        .clock          (clk            ),  //  Master Clock
        .reset          (!rst_n         ),  //  Active High Asynchronous Reset (driven)
        .di_en          (fft_1_di_en    ),  //  Input Data Enable
        .di_re          (fft_1_din_re   ),  //  Input Data (Real)
        .di_im          (fft_1_din_im   ),  //  Input Data (Imag)
        .do_en          (fft_1_do_en    ),  //  Output Data Enable
        .do_re          (fft_1_do_re    ),  //  Output Data (Real)
        .do_im          (fft_1_do_im    ),  //  Output Data (Imag)
        .fft_cnt        (fft_1_cnt      ),
        .fft_rdy        (fft_1_rdy      )
    );

    FFT512 #(
        .WIDTH          (WIDTH          ),
        .N_FFT          (N_FFT          )
    ) FFT_inst_2 (
        .clock          (clk            ),
        .reset          (!rst_n         ),
        .di_en          (fft_2_di_en    ),
        .di_re          (fft_2_din_re   ),
        .di_im          (fft_2_din_im   ),
        .do_en          (fft_2_do_en    ),
        .do_re          (fft_2_do_re    ),
        .do_im          (fft_2_do_im    ),
        .fft_cnt        (fft_2_cnt      ),
        .fft_rdy        (fft_2_rdy      )
    );
    
    wire [WIDTH-1:0] fft_do_re = fft_1_do_en ? fft_1_do_re : (fft_2_do_en ? fft_2_do_re : {WIDTH{1'b0}});
    wire [WIDTH-1:0] fft_do_im = fft_1_do_en ? fft_1_do_im : (fft_2_do_en ? fft_2_do_im : {WIDTH{1'b0}});
    wire fft_do_en = fft_1_do_en | fft_2_do_en;
    wire [WIDTH-1:0] fft_pwd_re;
    wire [WIDTH-1:0] fft_pwd_im;
    assign stft_data_en = fft_do_en;
    assign stft_pw2_data = (fft_pwd_re + fft_pwd_im) > {WIDTH{1'b1}} ? {WIDTH{1'b1}} : (fft_pwd_re + fft_pwd_im);

    // Power Spectrum Calculation
    Multiply #(
        .WIDTH          (WIDTH          )
    ) MU_inst1 (
        .a_re           (fft_do_re      ),
        .a_im           ({WIDTH{1'b0}}), // not used
        .b_re           (fft_do_re      ),
        .b_im           ({WIDTH{1'b0}}), // not used
        .m_re           (fft_pwd_re), // not used
        .m_im           ()  // not used
    );

    Multiply #(
        .WIDTH          (WIDTH          )
    ) MU_inst2 (
        .a_re           (fft_do_im      ),
        .a_im           ({WIDTH{1'b0}}), // not used
        .b_re           (fft_do_im      ),
        .b_im           ({WIDTH{1'b0}}), // not used
        .m_re           (fft_pwd_im), // not used
        .m_im           ()  // not used
    );

    // Output Selection
    

endmodule