/*
    Internal Chip Bus (ICB) Interface Definition
    -------------------------------------
    Command Channel:
        - icb_cmd_valid : CPU to Peripheral, write request signal
        - icb_cmd_ready : Peripheral to CPU, write request acknowledgment signal
        - icb_cmd_addr [31:0] : CPU to Peripheral, address for the write / read operation
        - icb_cmd_read: CPU to Peripheral, read / write indicator (1 for read, 0 for write)
        - icb_cmd_wdata [31:0] : CPU to Peripheral, data to be written
        - icb_cmd_wmask [3:0] : CPU to Peripheral, byte-wise write mask, same as AXI.

    Response Channel:
        - icb_rsp_valid: Peripheral to CPU, read / write request from peripheral
        - icb_rsp_ready: CPU to Peripheral, read / write request acknowledgment from CPU
        - icb_rsp_rdata [31:0] : Peripheral to CPU, data read from peripheral
        - icb_rsp_err : Peripheral to CPU, error indicator (1 for error, 0 for no error)
*/

interface icb_interface(input logic clk, input logic rst_n);

    // Command Channel
    logic           icb_cmd_valid;
    logic           icb_cmd_ready;
    logic [31:0]    icb_cmd_addr;
    logic           icb_cmd_read;
    logic [31:0]    icb_cmd_wdata;
    logic [3:0]     icb_cmd_wmask;

    // Response Channel
    logic           icb_rsp_valid;
    logic           icb_rsp_ready;
    logic [31:0]    icb_rsp_rdata;
    logic           icb_rsp_err;

    // Modport for a master device (e.g., CPU, testbench driver)
    modport master (
        input   clk, rst_n,
        // Command Channel
        output  icb_cmd_valid,
        input   icb_cmd_ready,
        output  icb_cmd_addr,
        output  icb_cmd_read,
        output  icb_cmd_wdata,
        output  icb_cmd_wmask,
        // Response Channel
        input   icb_rsp_valid,
        output  icb_rsp_ready,
        input   icb_rsp_rdata,
        input   icb_rsp_err
    );

    // Modport for a slave device (e.g., Peripheral, memory)
    modport slave (
        input   clk, rst_n,
        // Command Channel
        input   icb_cmd_valid,
        output  icb_cmd_ready,
        input   icb_cmd_addr,
        input   icb_cmd_read,
        input   icb_cmd_wdata,
        input   icb_cmd_wmask,
        // Response Channel
        output  icb_rsp_valid,
        input   icb_rsp_ready,
        output  icb_rsp_rdata,
        output  icb_rsp_err
    );

endinterface 