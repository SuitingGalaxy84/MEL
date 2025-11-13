module WIN_LUT#(
    parameter WIDTH             = 16,
    parameter N_FFT             = 512,
    parameter WIN_LEN           = 480,
    parameter HOP_LEN           = 160,

    parameter BUFF_ADDR_WIDTH   = $clog2(WIN_LEN + HOP_LEN),
    parameter N_FFT_WIDTH     = $clog2(N_FFT)
    
)(
    input                       clk,
    input                       rst_n,
    input                       den, // data enable, enable computation as well.
    input [WIDTH-1:0]           din_re,
    input [WIDTH-1:0]           din_im,
    output                      dout_en,
    output [WIDTH-1:0]          dout_re,
    output [WIDTH-1:0]          dout_im,
    output                      data_full,
    output                      data_empty
);

    wire [2*WIDTH-1:0] data_sram_in     = {din_re, din_im};
    wire [2*WIDTH-1:0] data_mu_in;
    wire [WIDTH-1:0] coe_mu_in; 
    
    
    reg [BUFF_ADDR_WIDTH-1:0] w_data_ptr, r_data_ptr;
    reg [N_FFT_WIDTH-1:0] r_idx_ptr;
    reg first_frame;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_data_ptr  <= 0;
            r_data_ptr  <= 0;
            r_idx_ptr   <= 0;
            first_frame <= 1'b1;
        end else begin
            if (den) begin
                w_data_ptr <= w_data_ptr + 1;
                first_frame <= (w_data_ptr == HOP_LEN - 1) ? 1'b0 : first_frame;
            end
        end 
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_data_ptr <= 0;
            r_idx_ptr  <= 0;
        end else begin
            if (first_frame) begin
                r_data_ptr <= 0;
                r_idx_ptr  <= 0;
            end else begin
                r_idx_ptr  <= (r_idx_ptr == N_FFT - 1) ? 0 : r_idx_ptr + 1;
                if(r_idx_ptr < WIN_LEN - 1) begin
                    r_data_ptr <= r_data_ptr + 1;
                end else if (r_idx_ptr == WIN_LEN - 1) begin
                    r_data_ptr <= r_data_ptr - (WIN_LEN - HOP_LEN);
                end 
             end
        end
    end 


    // --- SRAM Instantiation ---
    SRAM #(
        .DATA_WIDTH         (2*WIDTH        ),
        .ADDR_WIDTH         ($clog2(WIN_LEN+HOP_LEN))
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

    HANN_WIN HANN_WIN_inst (
        .clk                (clk            ),
        .rst_n              (rst_n          ),
        .addr               (r_idx_ptr      ),  
        .win_coe_out        (coe_mu_in      )
    );



    // --- MU Output Wires ---
    wire [WIDTH-1:0] data_mu_re;
    wire [WIDTH-1:0] data_mu_im;
    wire [WIDTH-1:0] mu_a_re = r_idx_ptr >= WIN_LEN ? 0 : data_mu_in[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] mu_b_re = r_idx_ptr >= WIN_LEN ? 0 : coe_mu_in;
    // --- MU Instantiation ---
    Multiply #(
        .WIDTH              (WIDTH)
    ) MU_inst (
        .a_re               (mu_a_re                     ),
        .a_im               (0                           ),
        .b_re               (mu_b_re                     ),
        .b_im               (0                           ),
        .m_re               (data_mu_re                  ),
        .m_im               (data_mu_im                  )
    );


    assign dout_en = r_idx_ptr != 0;
    assign dout_re = data_mu_re;
    assign dout_im = data_mu_im;
    assign data_full = (r_data_ptr - w_data_ptr) < (WIN_LEN - HOP_LEN) && !first_frame;
    assign data_empty = first_frame;


endmodule