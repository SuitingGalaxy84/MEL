`include "transaction.sv"

class ICBDriver;
    virtual icb_interface.master vif;
    mailbox #(ICBTransaction) gen2drv_mbx;

    function new(virtual icb_interface.master vif, mailbox #(ICBTransaction) gen2drv_mbx);
        this.vif = vif;
        this.gen2drv_mbx = gen2drv_mbx;
    endfunction

    task run();
        forever begin
            ICBTransaction tr;
            gen2drv_mbx.get(tr);

            vif.icb_cmd_valid <= 1;
            vif.icb_cmd_addr  <= tr.addr;
            vif.icb_cmd_read  <= tr.read;
            if (!tr.read) begin // Write transaction
                vif.icb_cmd_wdata <= tr.wdata;
                vif.icb_cmd_wmask <= 4'b1111; // Assuming full 32-bit write
            end

            wait (vif.icb_cmd_ready === 1);
            @(posedge vif.clk);
            vif.icb_cmd_valid <= 0;
        end
    endtask
endclass
