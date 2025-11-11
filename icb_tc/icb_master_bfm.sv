// icb_master_bfm.sv
`timescale 1ns/1ps

module icb_master_bfm (
    icb_interface.master icb
);

    // Task to perform a single 32-bit write
    task write_word(input [31:0] addr, input [31:0] data);
        @(posedge icb.clk);
        icb.icb_cmd_valid <= 1;
        icb.icb_cmd_addr  <= addr;
        icb.icb_cmd_read  <= 0; // Write operation
        icb.icb_cmd_wdata <= data;
        icb.icb_cmd_wmask <= 4'b1111; // Write all 4 bytes

        // Wait for slave to be ready
        wait (icb.icb_cmd_ready);
        @(posedge icb.clk);

        // De-assert command signals
        icb.icb_cmd_valid <= 0;
        
        // Master is always ready to accept response
        icb.icb_rsp_ready <= 1;
        wait(icb.icb_rsp_valid);
        
        if (icb.icb_rsp_err) begin
            $display($time, " MASTER: Write Error Response Received for addr %h", addr);
        end else begin
            $display($time, " MASTER: Write Ack Received for addr %h", addr);
        end
        
        @(posedge icb.clk);
        icb.icb_rsp_ready <= 0;

    endtask

    // Task to perform a single 32-bit read
    task read_word(input [31:0] addr);
        logic [31:0] rdata;
        @(posedge icb.clk);
        icb.icb_cmd_valid <= 1;
        icb.icb_cmd_addr  <= addr;
        icb.icb_cmd_read  <= 1; // Read operation

        // Wait for slave to be ready
        wait (icb.icb_cmd_ready);
        @(posedge icb.clk);

        // De-assert command signals
        icb.icb_cmd_valid <= 0;

        // Master is always ready to accept response
        icb.icb_rsp_ready <= 1;
        wait(icb.icb_rsp_valid);
        
        if (icb.icb_rsp_err) begin
            $display($time, " MASTER: Read Error Response Received for addr %h", addr);
        end else begin
            rdata = icb.icb_rsp_rdata;
            $display($time, " MASTER: Read Data %h from addr %h", rdata, addr);
        end
        
        @(posedge icb.clk);
        icb.icb_rsp_ready <= 0;

    endtask

endmodule
