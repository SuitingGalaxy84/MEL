module BIN_CNT#(
    parameter WIDTH         = 16,
    parameter N_FFT         = 512,
    parameter MEL_BANDS     = 40,
    parameter FFT_IDX_WIDTH = $clog2(N_FFT/2+1)
)(
    input                               clk,
    input                               rst_n,
    input                               pwd_odata_en,
    output reg [FFT_IDX_WIDTH-1:0]      fft_bin_idx

);



    // Count FFT output index whenever a power-spectrum output is valid
    // This mirrors the STFT/FFT behavior which produces (N_FFT/2 + 1) outputs

    wire [N_FFT-1:0] half_plus_one = (N_FFT >> 1) + 1'b1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fft_bin_idx <= {FFT_IDX_WIDTH{1'b0}};
        end else begin
            if (pwd_odata_en) begin
                if (fft_bin_idx + 1 >= half_plus_one[FFT_IDX_WIDTH-1:0]) begin
                    fft_bin_idx <= {FFT_IDX_WIDTH{1'b0}};
                end else begin
                    fft_bin_idx <= fft_bin_idx + 1'b1;
                end
            end
        end
    end

    
endmodule