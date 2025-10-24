module BRR_PP #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
) (
    // Inputs
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,

    // Outputs
    output [DATA_WIDTH-1:0] data_out,
    output reg buffer_full,
    output reg buffer_empty
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    // Memory banks
    reg [DATA_WIDTH-1:0] mem_a [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] mem_b [0:DEPTH-1];

    // Pointers for writing and reading
    reg [ADDR_WIDTH-1:0] write_counter;
    reg [ADDR_WIDTH-1:0] read_counter;

    // Bank selection signals
    reg wr_bank; // 0 for mem_a, 1 for mem_b
    reg rd_bank; // 0 for mem_a, 1 for mem_b

    // Write and read addresses
    wire [ADDR_WIDTH-1:0] wr_addr;
    wire [ADDR_WIDTH-1:0] rd_addr;


    // Function to reverse the bits of a vector
    function [ADDR_WIDTH-1:0] bit_reverse;
        input [ADDR_WIDTH-1:0] in;
        integer i;
        begin
            // Build the reversed-bit vector bit-by-bit
            for (i = 0; i < ADDR_WIDTH; i = i + 1)
                bit_reverse[i] = in[ADDR_WIDTH-1-i];
        end
    endfunction

    // Generate write address by bit-reversing the write_counter
    assign wr_addr = bit_reverse(write_counter);

    // Read address is the natural order read_counter
    assign rd_addr = read_counter;

    // Write logic
    always @(posedge clk) begin
        if (wr_en) begin
            if (wr_bank == 0)
                mem_a[wr_addr] <= data_in;
            else
                mem_b[wr_addr] <= data_in;
        end
    end

    // Counters and bank switching logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_counter <= 0;
            read_counter  <= 0;
            wr_bank       <= 0;
            rd_bank       <= 1;
            buffer_full   <= 0;
            buffer_empty  <= 1;
        end else begin
            // Write counter logic and bank switching

            if (wr_en) begin
                if (write_counter == DEPTH - 1) begin
                    write_counter <= 0;
                    wr_bank       <= ~wr_bank; // Switch write bank
                    rd_bank       <= ~rd_bank; // force read bank switch: sync with write
                    buffer_full   <= 1;       // Signal that a buffer is full
                end else begin
                    write_counter <= write_counter + 1;
                    buffer_full   <= 0;
                end
            end

            // Read counter logic
            if (rd_en) begin
                if (read_counter == DEPTH - 1) begin
                    read_counter <= 0;
                    buffer_empty <= 1;      // Signal that a buffer is empty
                end else begin
                    read_counter <= read_counter + 1;
                    buffer_empty <= 0;
                end
            end

        end
    end

    // Output multiplexer
    assign data_out = (rd_bank == 0) ? mem_a[rd_addr] : mem_b[rd_addr];
    integer monitor_file;
    
    initial begin
        monitor_file = $fopen("monitor.txt", "w");
    end

    always @(posedge clk) begin
        $fdisplay(monitor_file, "Time=%0t | wr_en=%b rd_en=%b | wr_bank=%b rd_bank=%b | write_counter=%d read_counter=%d | write_addr=%d read_addr=%d | data_in=%d data_out=%d", 
                 $time, wr_en, rd_en, wr_bank, rd_bank, write_counter, read_counter, wr_addr, rd_addr, data_in, data_out);
    end
endmodule
