//----------------------------------------------------------------------
//  Multiply: Complex Multiplier
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//  Complex Multiply (Q1.15) with convergent rounding and saturation
//----------------------------------------------------------------------
//  a * b = (a_re + j a_im) * (b_re + j b_im)
//        = (a_re*b_re - a_im*b_im) + j (a_re*b_im + a_im*b_re)
//
//  - Inputs:  signed Q1.15 (WIDTH=16)
//  - Internal: full 32-bit products (Q2.30)
//  - Output: signed Q1.15 with round-to-nearest, ties-to-even, then saturate
//----------------------------------------------------------------------
module Multiply #(
    parameter WIDTH = 16  // 16 for Q1.15
)(
    input  signed [WIDTH-1:0] a_re,
    input  signed [WIDTH-1:0] a_im,
    input  signed [WIDTH-1:0] b_re,
    input  signed [WIDTH-1:0] b_im,
    output signed [WIDTH-1:0] m_re,
    output signed [WIDTH-1:0] m_im
);
    // 16x16 -> 32 (Q2.30)
    wire signed [31:0] arbr = a_re * b_re;
    wire signed [31:0] aibi = a_im * b_im;
    wire signed [31:0] arbi = a_re * b_im;
    wire signed [31:0] aibr = a_im * b_re;

    // Sum/diff in 33 bits to be safe
    wire signed [32:0] re_full = $signed({arbr[31], arbr}) - $signed({aibi[31], aibi}); // Q2.30 in 33b
    wire signed [32:0] im_full = $signed({arbi[31], arbi}) + $signed({aibr[31], aibr}); // Q2.30 in 33b

    // -------- Convergent rounding (round-to-nearest, ties-to-even) --------
    // We want to shift right by 15 to go Q2.30 -> Q1.15
    function automatic signed [WIDTH-1:0] round_shift_sat_q15;
        input signed [32:0] x;  // Q2.30 extended
        reg   signed [16:0] keep17;  // 17-bit to catch overflow before saturate
        reg                  guard;
        reg                  sticky;
        reg                  lsb;
        reg                  round_up;
        reg   signed [16:0]  rounded17;
        reg   signed [15:0]  clipped16;
    begin
        // Bits: x[32] sign, integer bits x[31:30], fraction x[29:0]
        // After >>15 we keep x[30:15] (16 bits + possible overflow into bit16)
        keep17  = {x[30], x[30:15]};  // 17 bits: extra MSB to catch carry (sign-aware)
        guard   = x[14];
        sticky  = |x[13:0];
        lsb     = keep17[0];
        round_up = guard & (sticky | lsb); // ties to even

        rounded17 = keep17 + $signed({16'd0, round_up});

        // Saturate to Q1.15 range: [-32768, 32767]
        if (rounded17 > 17'sd32767)
            clipped16 = 16'sh7FFF;
        else if (rounded17 < -17'sd32768)
            clipped16 = 16'sh8000;
        else
            clipped16 = rounded17[15:0];

        round_shift_sat_q15 = clipped16;
    end
    endfunction

    assign m_re = round_shift_sat_q15(re_full);
    assign m_im = round_shift_sat_q15(im_full);
endmodule

