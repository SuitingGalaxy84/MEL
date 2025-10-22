module MEL_FBANK #(
    
    parameter WIDTH = 16,
    parameter N_MEL = 40,
    parameter N_FFT = 512,
    parameter NZ_MEL_SRAM_DEPTH = 257 // Number of non-zero entries in mel filter bank
)(
    input clk, 
    input rst_n,
    input fft_bin_vld,
    input [WIDTH-1:0] fft_bin,
    input [2*WIDTH-1:0] mel_fbank_weight,
   
    input [1:0] mac_bits,
    output reg mel_spec_vld,
    output reg [WIDTH-1:0] mel_spec,
    output reg [7:0] mel_cnt
);

    
    wire mac_1_bit = mac_bits[1]; 
    wire mac_2_bit = mac_bits[0];
    reg  mac_1_bit_d1;
    reg  mac_2_bit_d1;

    wire mel_mac_1_xor = mac_1_bit ^ mac_1_bit_d1;
    wire mel_mac_2_xor = mac_2_bit ^ mac_2_bit_d1;
    
    reg mel_mac_1_clear;
    reg mel_mac_2_clear;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mel_mac_1_clear <= 0;
            mel_mac_2_clear <= 0;
            mel_cnt <= 0;
        end else begin
            mel_mac_1_clear <= mel_mac_1_xor;
            mel_mac_2_clear <= mel_mac_2_xor;
            mel_cnt <= mel_spec_vld ? mel_cnt + 1 : mel_cnt;
        end
    end
    
    
    wire [WIDTH-1:0] mel_fbank_weight_1 = mel_fbank_weight[WIDTH-1:0];
    wire [WIDTH-1:0] mel_fbank_weight_2 = mel_fbank_weight[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] mel_spec_accum;
    wire [WIDTH-1:0] mel_spec_accum_2;

    always @(*) begin
        case ({mel_mac_1_xor, mel_mac_2_xor})
            2'b00: mel_spec = 0; // No clear, output zero
            2'b01: mel_spec = mel_spec_accum_2;
            2'b10: mel_spec = mel_spec_accum;
            2'b11: mel_spec = 0; // Both cleared, output zero 
            default: mel_spec = 0;
        endcase

        case ({mel_mac_1_xor, mel_mac_2_xor})
            2'b00: mel_spec_vld = 1'b0; // No clear, output invalid
            2'b01: mel_spec_vld = 1'b1;
            2'b10: mel_spec_vld = 1'b1;
            2'b11: mel_spec_vld = 1'b0; // Both cleared, output invalid
            default: mel_spec_vld = 1'b0;
        endcase
    end 

    // clear the mac once clear bit is inverted: XOR operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_1_bit_d1 <= 0;
            mac_2_bit_d1 <= 1;
        end else begin
            mac_1_bit_d1 <= mac_1_bit;
            mac_2_bit_d1 <= mac_2_bit;
        end
    end

    MEL_MAC #(
        .WIDTH(WIDTH), .Q(15)
    ) MEL_MAC_1 (
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .clear              (mel_mac_1_xor    ), // Clear at the start of each new frame
        .en                 (fft_bin_vld        ),
        .a                  (fft_bin            ),
        .b                  (mel_fbank_weight_1),
        .c                  (mel_spec_accum     ),
        .c_mantissa         (),
        .c_exponent         ()
    );

    MEL_MAC #(
        .WIDTH(WIDTH), .Q(15)
    ) MEL_MAC_2 (
        .clk                (clk                ),
        .rst_n              (rst_n              ),
        .clear              (mel_mac_2_xor      ), // Clear at the start of each new frame
        .en                 (fft_bin_vld        ),
        .a                  (fft_bin            ),
        .b                  (mel_fbank_weight_2 ),
        .c                  (mel_spec_accum_2   ),
        .c_mantissa         (),
        .c_exponent         ()
    );


endmodule