//----------------------------------------------------------------------
//  Mel_mac: Multiply-Accumulate for Mel Filter Bank
//----------------------------------------------------------------------
module MEL_MAC #(
    parameter   WIDTH = 16,
    parameter   Q = 15,
    // Accumulator width needs to be larger to prevent overflow.
    // A single product is Q1.15. Summing up to N_FFT/2 (256) of these
    // requires at least 8 extra integer bits (2^8 = 256).
    // ACC_WIDTH = 1 (sign) + 8 (integer) + 15 (fractional) = 24.
    // Let's use a wider accumulator for safety.
    parameter   ACC_WIDTH = 32,
    parameter   OUT_WIDTH = 16
)(
    input   clk,
    input   rst_n,
    input   clear,  // Synchronous clear for the accumulator
    input   en,     // Enable for the MAC operation

    // Inputs to the multiplier
    input   signed [WIDTH-1:0] a, // Power spectrum value (real, Q1.15)
    input   signed [WIDTH-1:0] b, // Mel filter weight (real, Q1.15)

    // Accumulated output
    output  reg signed [ACC_WIDTH-1:0] c,

    // Automatically scaled output (block floating-point, Usually Not used)
    output  reg signed [OUT_WIDTH-1:0] c_mantissa, // Scaled mantissa
    output  reg [4:0] c_exponent                  // Headroom/Exponent
);

    // Wire for the product of a and b
    wire signed [WIDTH-1:0] product;

    // Instantiate the Q-format multiplier
    Multiply_qx #(
        .WIDTH_A(WIDTH), 
        .Q_A(Q),
        .WIDTH_B(WIDTH), 
        .Q_B(Q),
        .WIDTH_C(WIDTH), 
        .Q_C(Q)
    ) mac_multiplier (
        .a_re(a), 
        .a_im(16'b0),
        .b_re(b), 
        .b_im(16'b0),
        .c_re(product), 
        .c_im()
    );

    // Accumulator logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c <= 0;
        end else begin
            case ({clear, en})
                2'b00: c        <= c;
                2'b01: c        <= c + {{ACC_WIDTH-WIDTH{product[WIDTH-1]}}, product};
                2'b10: c        <= 0;
                2'b11: c        <= product; // Clear and add current product
                default: c      <= c;
            endcase
        end
    end

    // --- Automatic Scaling (Block Floating-Point) ---

    // 1. Find the number of leading sign bits (headroom) in the accumulator
    // This is a priority encoder that finds the first bit that differs from the sign bit.
    integer i;
    // Temporary variables for synthesizable headroom computation
    reg found;                     // flag: have we seen the first differing bit?
    reg [4:0] tmp_exponent;        // temporary exponent (width matches c_exponent)

    always @(*) begin: find_exponent
        reg sign_bit;
        sign_bit = c[ACC_WIDTH-1];
        tmp_exponent = 0; // Default for c = 0 or c = -1
        found = 1'b0;
        // Count leading sign-equal bits until the first differing bit is encountered
        for (i = ACC_WIDTH - 2; i >= 0; i = i - 1) begin
            if (!found) begin
                if (c[i] == sign_bit) begin
                    tmp_exponent = tmp_exponent + 1;
                end else begin
                    found = 1'b1; // stop counting further
                end
            end
        end
        c_exponent = tmp_exponent;
    end

    // 2. Scale the output based on the exponent to produce the mantissa
    // This normalizes the accumulator value to fit into the output width.
    always @(*) begin: scale_output
        reg signed [ACC_WIDTH-1:0] shifted_c;
        // We shift left to bring the MSB of the data to the top of the word,
        // preserving the sign bit. This maximizes precision.
        shifted_c = c << c_exponent;
        // Take the top N bits for the mantissa
        c_mantissa = shifted_c[ACC_WIDTH-1 -: OUT_WIDTH];
    end

endmodule
