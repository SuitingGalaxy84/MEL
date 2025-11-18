`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Electronic Science and Technology of China
// Engineer: Sun Yucheng
// 
// Create Date: 2025-11-17
// Design Name: Short-Time Fourier Transform (STFT) - Ping-Pong FFT wrapper
// Module Name: STFT_PW2
// Project Name: MEL
// Target Devices: FPGA (e.g. Xilinx)
// Tool Versions: Vivado 2020.2+
// Description:
//   STFT_PW2 is a top-level STFT processing block that performs windowing,
//   ping-pong FFT ingestion and power-spectrum (|X|^2) calculation limited
//   to a WIDTH-bit saturated output. The module uses a WIN_LUT for windowing
//   and two FFT512 instances in a ping-pong configuration to maintain
//   continuous throughput. The real and imaginary outputs from the active
//   FFT are squared (via Multiply blocks) and summed to produce the
//   power-per-bin output (stft_pw2_data). A data_full flag from the window
//   buffer is exposed to upstream logic.
//
// Parameters:
//   WIDTH   - data bit width for real/imag samples and intermediate results.
//   N_FFT   - FFT length (e.g., 512).
//   WIN_LEN - analysis window length in samples.
//   HOP_LEN - hop/stride length between consecutive windows.
//
// Ports:
//   clk            - system clock.
//   rst_n          - active-low reset.
//   den            - input data enable (feed samples when asserted).
//   din_re, din_im - input real/imag sample stream (signed, WIDTH bits).
//   data_full      - asserted when window buffer cannot accept more samples.
//   stft_data_en   - asserted when output power sample is valid.
//   stft_pw2_data  - saturated power spectrum output (WIDTH bits).
//
// Dependencies:
//   - WIN_LUT (windowing and buffering to produce framed windows)
//   - FFT512 (FFT core, used twice in ping-pong configuration)
//   - Multiply (multiplier blocks used for squaring real/imag parts)
//
// Revision:
//   1.00 - 2025-11-17 - Initial header and description added.
//   1.01 - 2025-11-17 - Clarified module purpose, ports and dependencies.
//
// Additional Comments:
//   - Output saturation clamps (fft_pwd_re + fft_pwd_im) to all-ones when
//     overflow occurs; consider expanding internal accumulator width if
//     higher dynamic range is required.
//   - FFT cores expect active-high reset; this module inverts rst_n for them.
//   - Ensure Multiply and FFT512 implementations match WIDTH and signedness
//     assumptions used here.

//////////////////////////////////////////////////////////////////////////////////


module STFT_PW2#(
    parameter WIDTH             = 16,
    parameter N_FFT             = 512,
    parameter WIN_LEN           = 480,
    parameter HOP_LEN           = 160
)(
    input                       clk,
    input                       rst_n,

    input                       den, // data enable, enable computation as well.
    input [WIDTH-1:0]           din_re, // input data (real)
    input [WIDTH-1:0]           din_im, // input data (imag)
    output                      stft_data_en,
    output [WIDTH-1:0]          stft_pw2_data,
    output                      buf_full,
    output                      buf_empty,
    output                      fft_1_rdy,
    output                      fft_2_rdy
);
    
    wire win_dout_en;
    reg fft_1_di_en, fft_2_di_en;
    wire [WIDTH-1:0] win_dout_re;
    wire [WIDTH-1:0] win_dout_im;
    reg [WIDTH-1:0] fft_1_din_re;
    reg [WIDTH-1:0] fft_1_din_im;
    reg [WIDTH-1:0] fft_2_din_re;
    reg [WIDTH-1:0] fft_2_din_im;

    wire [WIDTH-1:0] fft_1_do_re;
    wire [WIDTH-1:0] fft_1_do_im;
    wire [WIDTH-1:0] fft_2_do_re;
    wire [WIDTH-1:0] fft_2_do_im;

    wire [9:0] fft_1_cnt;
    wire [9:0] fft_2_cnt;

    always @(*) begin
        case({win_dout_en, fft_1_rdy, fft_2_rdy})
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
    
    WIN_LUT #(
        .WIDTH          (WIDTH          ),
        .N_FFT          (N_FFT          ),
        .WIN_LEN        (WIN_LEN        ),
        .HOP_LEN        (HOP_LEN        )
    ) WIN_LUT_inst (
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .den            (den            ),
        .din_re         (din_re         ),
        .din_im         (din_im         ),
        .dout_en        (win_dout_en    ),
        .dout_re        (win_dout_re    ),
        .dout_im        (win_dout_im    ),
        .data_full      (buf_full       ),
        .data_empty     (buf_empty      )
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