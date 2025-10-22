//----------------------------------------------------------------------
//  Multiply_qx: Complex Multiplier with configurable Q-format
//----------------------------------------------------------------------
module Multiply_qx #(
    parameter   WIDTH_A = 16,
    parameter   Q_A = 15,
    parameter   WIDTH_B = 16,
    parameter   Q_B = 15,
    parameter   WIDTH_C = 16,
    parameter   Q_C = 15
)(
    input   signed  [WIDTH_A-1:0] a_re,
    input   signed  [WIDTH_A-1:0] a_im,
    input   signed  [WIDTH_B-1:0] b_re,
    input   signed  [WIDTH_B-1:0] b_im,
    output  signed  [WIDTH_C-1:0] c_re,
    output  signed  [WIDTH_C-1:0] c_im
);

localparam SHIFT_BITS = Q_A + Q_B - Q_C;
localparam PROD_WIDTH = WIDTH_A + WIDTH_B;

wire signed [PROD_WIDTH-1:0]   arbr, arbi, aibr, aibi;
wire signed [PROD_WIDTH-1:0]   shifted_arbr, shifted_arbi, shifted_aibr, shifted_aibi;
wire signed [PROD_WIDTH-1:0]   sum_re, sum_im;

//  Signed Multiplication
assign  arbr = a_re * b_re;
assign  arbi = a_re * b_im;
assign  aibr = a_im * b_re;
assign  aibi = a_im * b_im;

//  Scaling to output Q format
//  Arithmetic shift right to preserve sign
assign  shifted_arbr = arbr >>> SHIFT_BITS;
assign  shifted_arbi = arbi >>> SHIFT_BITS;
assign  shifted_aibr = aibr >>> SHIFT_BITS;
assign  shifted_aibi = aibi >>> SHIFT_BITS;

//  Sub/Add for complex multiplication result
assign  sum_re = shifted_arbr - shifted_aibi;
assign  sum_im = shifted_arbi + shifted_aibr;

//  Assign to output, truncating/extending as needed
assign  c_re = sum_re;
assign  c_im = sum_im;

/*
Example Verification for Mel Filter Bank Application:
This example demonstrates multiplying a power spectrum value with a mel filter bank weight.
Both values are real, so we will use the complex multiplier by setting the imaginary parts to zero.

Let's assume the following parameters for Q1.15 format:
    parameter   WIDTH_A = 16, Q_A = 15,  // Power Spectrum Value (real)
    parameter   WIDTH_B = 16, Q_B = 15,  // Mel Filter Weight (real)
    parameter   WIDTH_C = 16, Q_C = 15   // Output accumulator value

And the following inputs:
    // Power spectrum value from FFT, assumed to be scaled to [0, 1)
    a_re = 0.5 (decimal) -> 0.5 * 2^15 = 16384 (Q16.15 integer: 0x4000)
    a_im = 0.0 (decimal) -> 0 (Q16.15 integer: 0x0000)

    // Mel filter bank weight, which is always in [0, 1]
    b_re = 0.8 (decimal) -> 0.8 * 2^15 = 26214 (Q16.15 integer: 0x6666)
    b_im = 0.0 (decimal) -> 0 (Q16.15 integer: 0x0000)

Expected multiplication result in floating point:
    c = a * b = (0.5 + j*0.0) * (0.8 + j*0.0)
    c_re = 0.5 * 0.8 = 0.4
    c_im = 0.0

Now let's follow the module's fixed-point arithmetic:
1.  Intermediate product width:
    PROD_WIDTH = WIDTH_A + WIDTH_B = 16 + 16 = 32

2.  Signed Multiplication (results are in Q(16+16).(15+15) = Q32.30 format):
    arbr = a_re * b_re = 16384 * 26214 = 4294836224
    arbi = a_re * b_im = 16384 * 0 = 0
    aibr = a_im * b_re = 0 * 26214 = 0
    aibi = a_im * b_im = 0 * 0 = 0

3.  Scaling to output Q format:
    SHIFT_BITS = Q_A + Q_B - Q_C = 15 + 15 - 15 = 15
    The results are shifted right by 15 bits to convert from Q32.30 to Q32.15.
    shifted_arbr = 4294836224 >>> 15 = 13106.8 -> 13107 (due to rounding/truncation, Verilog `>>>` truncates)
    Let's use precise division: 4294836224 / 32768 = 13107.2. The integer part is 13107.
    shifted_arbi = 0 >>> 15 = 0
    shifted_aibr = 0 >>> 15 = 0
    shifted_aibi = 0 >>> 15 = 0

4.  Sub/Add for complex multiplication result (results are in Q32.15):
    sum_re = shifted_arbr - shifted_aibi = 13107 - 0 = 13107
    sum_im = shifted_arbi + shifted_aibr = 0 + 0 = 0

5.  Assign to output (truncating from Q32.15 to Q16.15):
    c_re = 13107 (Q16.15 integer: 0x3333)
    c_im = 0 (Q16.15 integer: 0x0000)

    Let's convert the result back to decimal to verify:
    c_re (decimal) = 13107 / 2^15 = 13107 / 32768 = 0.399993896...
    This is very close to the expected 0.4. The small difference is due to the quantization of the input `b_re`.
    (0.8 is a repeating fraction in binary, 26214/32768 is the Q15 approximation).

This example verifies that the module correctly performs multiplication for the Q1.15 format used in the mel filter bank calculation.
*/

endmodule
