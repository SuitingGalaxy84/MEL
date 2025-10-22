module WIN#(
    parameter WIDTH             = 16,
    parameter N_FFT_MAX         = $clog2(1024), 
    parameter WIN_LEN_MAX       = $clog2(1024),
    parameter HOP_LEN_MAX       = $clog2(1024/2)
)(
    input                       clk,
    input                       rst_n,
    input                       den, // data enable, enable computation as well.
    input [N_FFT_MAX-1:0]       n_fft,
    input [WIN_LEN_MAX-1:0]     win_len,
    input [HOP_LEN_MAX-1:0]     hop_len,
    input                       lut_en, // load window coeff enable
    input [WIDTH-1:0]           win_coe, // window coeff data
    input [WIDTH-1:0]           din_re,
    input [WIDTH-1:0]           din_im,
    output                      dout_en,
    output [WIDTH-1:0]          dout_re,
    output [WIDTH-1:0]          dout_im,
    output reg                  data_full
);

    wire win_coe_we                     = rst_n & lut_en;
    wire [2*WIDTH-1:0] data_sram_in     = {din_re, din_im};
    wire [2*WIDTH-1:0] data_mu_in;
    wire [WIDTH-1:0] coe_mu_in;
    
    
    reg [WIN_LEN_MAX-1:0] w_data_ptr, r_data_ptr;
    reg [N_FFT_MAX-1:0] r_coe_ptr, w_coe_ptr; // Changed to n_fft width for padding
    
    wire [N_FFT_MAX-1:0] next_r_coe_ptr       = (r_coe_ptr == n_fft - 1) ? 0 : r_coe_ptr + 1;
    wire [WIN_LEN_MAX-1:0] next_w_coe_ptr       = (w_coe_ptr == win_len - 1) ? 0 : w_coe_ptr + 1;
    wire [WIN_LEN_MAX-1:0] next_r_data_ptr      = (r_coe_ptr == n_fft - 1) ? r_data_ptr - (win_len - hop_len) : r_data_ptr + 1;
    
    // --- Input SRAM Padding / Regular Pointer Logic ---

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_data_ptr          <= 0;
            r_data_ptr          <= 0;
            w_coe_ptr           <= 0;
            r_coe_ptr           <= 0;

        end else begin
            if (den) begin
                w_data_ptr      <= w_data_ptr + 1;               
                r_coe_ptr       <= next_r_coe_ptr;
                if (r_coe_ptr < win_len) begin // Only advance data pointer during windowing part
                    r_data_ptr      <= next_r_data_ptr;
                end
            end else begin
                w_data_ptr      <= w_data_ptr;
                r_coe_ptr       <= r_coe_ptr;
                r_data_ptr      <= r_data_ptr;
            end

            // Load window coefficient pointer
            if (lut_en) begin
                w_coe_ptr       <= next_w_coe_ptr;
            end else begin
                w_coe_ptr       <= w_coe_ptr;
            end
        end
    end  

    // --- SRAM Instantiation ---
    SRAM #(
        .DATA_WIDTH         (2*WIDTH     ),
        .ADDR_WIDTH         (WIN_LEN_MAX )
    ) DATA_BUFF (
        .clk                (clk            ),
        .rstn               (rst_n          ),
        .cs                 (1'b1           ), 
        .we                 (den            ), // write when data enable is high
        .r_addr             (r_data_ptr     ),
        .w_addr             (w_data_ptr     ),
        .din                (data_sram_in   ),
        .dout               (data_mu_in     )
    );


    SRAM #(
        .DATA_WIDTH         (WIDTH      ),
        .ADDR_WIDTH         (WIN_LEN_MAX)
    ) WIN_COE_RE_LUT (
        .clk                (clk            ),
        .rstn               (rst_n          ),
        .cs                 (1'b1           ), // to be determined
        .we                 (win_coe_we     ), // load coefficient when lut_en is high
        .r_addr             (r_coe_ptr[WIN_LEN_MAX-1:0]),
        .w_addr             (w_coe_ptr      ),
        .din                (win_coe        ),
        .dout               (coe_mu_in      )
    );
    

    // --- MU Output Wires ---
    wire [WIDTH-1:0] data_mu_re;
    wire [WIDTH-1:0] data_mu_im;

    // --- MU Instantiation ---
    // This MU is pure combinational, zero latency
    // Note: Applying a window is element-wise multiplication of the signal and the window coefficients.
    Multiply #(
        .WIDTH              (WIDTH)
    ) MU_inst (
        .a_re               (data_mu_in[2*WIDTH-1:WIDTH] ),
        .a_im               (data_mu_in[WIDTH-1:0]       ),
        .b_re               (coe_mu_in                   ),
        .b_im               (0                           ),
        .m_re               (data_mu_re                  ),
        .m_im               (data_mu_im                  )
    );

    // --- Data Overflow Flag Logic ---
    wire [WIN_LEN_MAX:0] pesudo_rptr = r_data_ptr - (win_len - hop_len);
    wire [WIN_LEN_MAX:0] ptr_dist    = w_data_ptr - r_data_ptr;
    always @(*) begin
        if (w_data_ptr > r_data_ptr) begin
            data_full       = pesudo_rptr > w_data_ptr ? 1 : 0;
        end else begin
            data_full       = pesudo_rptr > w_data_ptr && ptr_dist > 0 ? 1 : 0; // exclude the case when pointers are equal
        end
    end 

    // --- Data Output Logic ---
    // Pipeline the output data and enable signal to match the SRAM read latency
    reg dout_en_reg;
    reg [WIDTH-1:0] dout_re_reg;
    reg [WIDTH-1:0] dout_im_reg;
    reg [N_FFT_MAX-1:0] out_cnt;
    reg output_active;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_en_reg <= 1'b0;
            dout_re_reg <= {WIDTH{1'b0}};
            dout_im_reg <= {WIDTH{1'b0}};
            out_cnt     <= 0;
        end else begin

            // dout_en_reg is a level signal indicating the module is outputting a full window
            // output_active is set when output starts and cleared after n_fft samples
            if (!output_active && den) begin
                // start outputting when data enable first becomes active
                output_active <= 1'b1;
            end else if (output_active && (out_cnt == n_fft - 1)) begin
                // clear when the window has completed
                output_active <= 1'b0;
            end else begin
                output_active <= output_active;
            end
            dout_en_reg <= output_active;

            if (den) begin
                if (out_cnt < win_len) begin
                    dout_re_reg <= data_mu_re;
                    dout_im_reg <= data_mu_im;
                end else begin
                    dout_re_reg <= 0;
                    dout_im_reg <= 0;
                end
                out_cnt <= (out_cnt == n_fft - 1) ? 0 : out_cnt + 1;
            end
        end
    end
    
    // Assign output ports
    assign dout_en = dout_en_reg;
    assign dout_re = dout_re_reg;
    assign dout_im = dout_im_reg;

endmodule