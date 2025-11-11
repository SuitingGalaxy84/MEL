// icb_slave_bfm.sv
`timescale 1ns/1ps

module icb_slave_bfm #(
    parameter MEM_DEPTH = 256
) (
    icb_interface.slave icb
);

    // Internal memory
    logic [31:0] mem [MEM_DEPTH-1:0];
    logic [31:0] read_data_reg;

    // Handle incoming commands
    integer i;
    always @(posedge icb.clk or negedge icb.rst_n) begin
        if (!icb.rst_n) begin
            icb.icb_cmd_ready <= 0;
            icb.icb_rsp_valid <= 0;
            icb.icb_rsp_err   <= 0;
            icb.icb_rsp_rdata <= 0;
            
            read_data_reg <= 0;
            for(i = 0; i < MEM_DEPTH; i = i + 1) begin
                mem[i] <= 0;
            end
        end else begin
            // Default assignments
            icb.icb_cmd_ready <= 1; // Always ready to accept a command
            
            if (icb.icb_cmd_valid && icb.icb_cmd_ready) begin
                if (icb.icb_cmd_read) begin // Read operation
                    // Read from memory
                    read_data_reg <= mem[icb.icb_cmd_addr[($clog2(MEM_DEPTH)+1):2]];
                    
                    // Respond in the next cycle
                    icb.icb_rsp_valid <= 1;
                    icb.icb_rsp_err   <= 0;
                    icb.icb_rsp_rdata <= read_data_reg;
                    
                end else begin // Write operation
                    // Write to memory
                    if (icb.icb_cmd_wmask[0]) mem[icb.icb_cmd_addr[($clog2(MEM_DEPTH)+1):2]][7:0]   <= icb.icb_cmd_wdata[7:0];
                    if (icb.icb_cmd_wmask[1]) mem[icb.icb_cmd_addr[($clog2(MEM_DEPTH)+1):2]][15:8]  <= icb.icb_cmd_wdata[15:8];
                    if (icb.icb_cmd_wmask[2]) mem[icb.icb_cmd_addr[($clog2(MEM_DEPTH)+1):2]][23:16] <= icb.icb_cmd_wdata[23:16];
                    if (icb.icb_cmd_wmask[3]) mem[icb.icb_cmd_addr[($clog2(MEM_DEPTH)+1):2]][31:24] <= icb.icb_cmd_wdata[31:24];
                    
                    // Respond in the same cycle
                    icb.icb_rsp_valid <= 1;
                    icb.icb_rsp_err   <= 0;
                end
            end else begin
                 if (icb.icb_rsp_ready || !icb.icb_rsp_valid) begin
                    icb.icb_rsp_valid <= 0;
                    icb.icb_rsp_err   <= 0;
                    icb.icb_rsp_rdata <= 0;
                end
            end
        end
    end

endmodule
