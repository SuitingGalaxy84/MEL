`include "icb_interface.sv"

module ICB_MSP (
    icb_interface.slave  icb_msp,
    input start,
    input win_coe_lut_en
);

    wire cmd_hand_shake;
    wire rsp_hand_shake;
    wire [15:0] fifo_cmd_data;
    wire [15:0] win_coe;
    wire [15:0] signal_re; 
    wire [7:0] mel_data;
    wire mel_avail; 
    wire [7:0] fifo_rsp_data;

    assign cmd_hand_shake = icb_msp.icb_cmd_valid && icb_msp.icb_cmd_ready;
    assign rsp_hand_shake = icb_msp.icb_rsp_valid && icb_msp.icb_rsp_ready;
    assign win_coe = win_coe_lut_en ? fifo_cmd_data : 16'b0;
    assign signal_re = start ? fifo_cmd_data : 16'b0;


    wire [31:0] msp_icb_fifo_rdata;
    wire fft_1_rdy;
    wire fft_2_rdy;
   
    SYNC_FIFO_SWMR #(
        .W_WIDTH(32), .R_WIDTH(16),
        .W_DEPTH(80)
    ) ICB_MSP_FIFO(
        .clk        (icb_msp.clk        ),
        .rst_n      (icb_msp.rst_n      ),
        // Write Interface
        .wr_en      (cmd_hand_shake && !icb_msp.icb_cmd_read),
        .wr_data    (icb_msp.icb_cmd_wdata),
        .full       (icb_msp_fifo_full  ),
        // Read Interface
        .rd_en      (start              ),
        .rd_data    (fifo_cmd_data      ),
        .empty      (icb_msp_fifo_empty )
    );

    SYNC_FIFO_MWSR #(
        .W_WIDTH(8), .R_WIDTH(32),
        .R_DEPTH(80)
    ) MSP_ICB_FIFO(
        .clk        (icb_msp.clk        ),
        .rst_n      (icb_msp.rst_n      ),
        // Write Interface
        .wr_en      (mel_avail          ),
        .wr_data    (mel_data           ),
        .full       (msp_icb_fifo_full  ),
        // Read Interface
        .rd_en      (rsp_hand_shake     ),
        .rd_data    (msp_icb_fifo_rdata ),
        .empty      (msp_icb_fifo_empty )  

    );

    MEL_SPEC #(
        .WIDTH          (16                ),
        .N_FRAMES       (101               ),
        .N_FFT          (512               ),
        .WIN_LEN        (480               ),
        .HOP_LEN        (160               ),
        .MEL_BANDS      (40                )
    ) MEL_SPEC_inst (
        .clk            (icb_msp.clk        ),
        .rst_n          (icb_msp.rst_n      ),
        .signal_en      (signal_en          ),
        .signal_re      (signal_re          ),
        .signal_im      (16'b0              ),
        .mel_data       (mel_data           ),
        .mel_avail      (mel_avail          ),

        .fft_1_rdy      (fft_1_rdy          ),
        .fft_2_rdy      (fft_2_rdy          ),
        .buf_full       (msp_icb_wbuf_full  ),
        .buf_empty      (msp_icb_wbuf_empty )
    );
    
    // error handling
    localparam MSP_ICB_FIFO_FULL    = 32'hF1F0F001; // "FIFOFUL1"
    localparam MSP_ICB_FIFO_EMPTY   = 32'hF1F0E971; // "FIFOEPT1" 
    localparam ICB_MSP_FIFO_FULL    = 32'hF1F0F002; // "FIFOFUL2"
    localparam ICB_MSP_FIFO_EMPTY   = 32'hF1F0E972; // "FIFOEPT2"
    localparam MSP_ICB_WBUF_FULL    = 32'hB00FF001; // "WBUFFUL"   
    localparam MSP_ICB_WBUF_EMPTY   = 32'hB00FE971; // "WBUFEPT"
    localparam MSP_ICB_STFT_BUSY     = 32'h57F7BE57;

     // error handling
    wire icb_msp_fifo_full;
    wire icb_msp_fifo_empty;
    wire msp_icb_fifo_full;
    wire msp_icb_fifo_empty;
    wire msp_icb_wbuf_full;
    wire msp_icb_wbuf_empty
    wire msp_icb_stft_busy;

    wire [6:0] error_vector;
    wire [31:0] error_code;

    assign error_vector[0] = icb_msp_fifo_full;
    assign error_vector[1] = icb_msp_fifo_empty;
    assign error_vector[2] = msp_icb_fifo_full;
    assign error_vector[3] = msp_icb_fifo_empty;
    assign error_vector[4] = msp_icb_wbuf_full;
    assign error_vector[5] = msp_icb_stft_busy;
    assign error_vector[6] = msp_icb_wbuf_empty;

    always_comb begin : ERROR_HANDLING
        if(rsp_hand_shake) begin
            case(error_vector)
                6'b000000: icb_msp.icb_rsp_rdata = msp_icb_fifo_rdata;
                default: icb_msp.icb_rsp_rdata = error_code(error_vector);
            endcase
        end 
    end

    function [31:0] error_code;
        input logic [5:0]  error_vector;
    begin
        if (error_vector[0]) error_code = error_code ^ MSP_ICB_FIFO_FULL;
        if (error_vector[1]) error_code = error_code ^ MSP_ICB_FIFO_EMPTY;
        if (error_vector[2]) error_code = error_code ^ ICB_MSP_FIFO_FULL;
        if (error_vector[3]) error_code = error_code ^ ICB_MSP_FIFO_EMPTY;
        if (error_vector[4]) error_code = error_code ^ MSP_ICB_WBUF_FULL;
        if (error_vector[5]) error_code = error_code ^ MSP_ICB_WBUF_EMPTY;

    end
    
    endfunction
endmodule