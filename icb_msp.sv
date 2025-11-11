`include "icb_interface.sv"

module ICB_MSP (
    icb_interface.slave  icb_msp
);

    wire cmd_hand_shake = icb_msp.icb_cmd_valid && icb_msp.icb_cmd_ready;
    wire rsp_hand_shake = icb_msp.icb_rsp_valid && icb_msp.icb_rsp_ready;

    SYNC_FIFO_SWMR #(
        .W_WIDTH(32), .R_WIDTH(16),
        .W_DEPTH(80)
    ) ICB_MSP_FIFO(
        .clk        (icb_msp.clk        ),
        .rst_n      (icb_msp.rst_n      ),
        // Write Interface
        .wr_en      (cmd_hand_shake && !icb_msp.icb_cmd_read),
        .wr_data    (icb_msp.icb_cmd_data),
        .wr_full    (),
        // Read Interface
        .rd_en      (),
        .rd_data    (),
        .rd_empty   ()
    );

    SYNC_FIFO_MWSR #(

    ) MSP_ICB_FIFO(
        .clk        (icb_msp.clk        ),
        .rst_n      (icb_msp.rst_n      ),
        // Write Interface
        .wr_en      (),
        .wr_data    (),
        .wr_full    (),
        // Read Interface
        .rd_en      (rsp_hand_shake),
        .rd_data    (icb_msp.icb_rsp_rdata),
        .rd_empty   ()  

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
        .start          (),
        .win_coe_lut_en (),
        .win_coe        (),
        .signal_re      (),
        .signal_im      (),
        .mel_data       (),
        .mel_avail      ()
    );
    // error signal logic      
endmodule