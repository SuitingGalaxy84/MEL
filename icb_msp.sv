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

    // error handling
    wire icb_msp_fifo_full;
    wire icb_msp_fifo_empty;
    wire msp_icb_fifo_full;
    wire msp_icb_fifo_empty;

    always_comb begin
        case({icb_msp_fifo_full, icb_msp_fifo_empty, msp_icb_fifo_full, msp_icb_fifo_empty})
            4'b1000: icb_msp.icb_rsp_rdata = MSP_ICB_FIFO_FULL;
            4'b0100: icb_msp.icb_rsp_rdata = MSP_ICB_FIFO_EMPTY;
            4'b0010: icb_msp.icb_rsp_rdata = ICB_MSP_FIFO_FULL;
            4'b0001: icb_msp.icb_rsp_rdata = ICB_MSP_FIFO_EMPTY;
            4'b1010: icb_msp.icb_rsp_rdata = MSP_ICB_FIFO_FULL | ICB_MSP_FIFO_FULL;
            4'b1001: icb_msp.icb_rsp_rdata = MSP_ICB_FIFO_FULL | ICB_MSP_FIFO_EMPTY;
            4'b0110: icb_msp.icb_rsp_rdata = MSP_ICB_FIFO_EMPTY | ICB_MSP_FIFO_FULL;
            4'b0101: icb_msp.icb_rsp_rdata = MSP_ICB_FIFO_EMPTY | ICB_MSP_FIFO_EMPTY;
            default: icb_msp.icb_rsp_rdata = msp_icb_fifo_rdata;
        endcase

        case({icb_msp_fifo_full, icb_msp_fifo_empty, msp_icb_fifo_full, msp_icb_fifo_empty})
            4'b0000: icb_msp.icb_rsp_err = 1'b0;
            default: icb_msp.icb_rsp_err = 1'b1;
        endcase
    end

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
        .rd_en      (rsp_hand_shake),
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
        .clk            (icb_msp.clk          ),
        .rst_n          (icb_msp.rst_n        ),
        .start          (start                ),
        .win_coe_lut_en (win_coe_lut_en       ),
        .win_coe        (win_coe              ),
        .signal_re      (signal_re            ),
        .signal_im      (16'b0                ),
        .mel_data       (mel_data             ),
        .mel_avail      (mel_avail            )
    );
    
    // error handling
    localparam MSP_ICB_FIFO_FULL    = 32'hF1F0F001; // "FIFOFUL1"
    localparam MSP_ICB_FIFO_EMPTY   = 32'hF1F0E971; // "FIFOEPT1" 
    localparam ICB_MSP_FIFO_FULL    = 32'hF1F0F002;    // "FIFOFUL2"
    localparam ICB_MSP_FIFO_EMPTY   = 32'hF1F0E972;    // "FIFOEPT2"


endmodule