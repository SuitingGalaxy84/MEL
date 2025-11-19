module CIRCULAR_BUFFER #(
    parameter WIDTH         = 32,
    parameter WIN_LENGTH     = 480,
    parameter HOP_LENGTH    = 160
)(
    input                       clk,
    input                       rst_n,
    input                       frm_init,

    input                       wr_en,
    input [WIDTH-1:0]           din,
    output                      full,

    input                       rd_en,
    input                       rd_jump,
    output [WIDTH-1:0]          dout,
    output                      empty,
    output                      almost_empty,

    output reg [ADDR_WIDTH-1:0] count_r
);
    /*
        WIDTH: Data width
        DEPTH: Total depth of the circular buffer
        ADDR_WIDTH: Address width for the circular buffer
        KEP_LENGTH: Length of data to keep before overwriting
    */
    localparam DEPTH         = 2**$clog2(WIN_LENGTH);
    localparam ADDR_WIDTH    = $clog2(DEPTH);

    reg [ADDR_WIDTH-1:0] write_ptr;
    reg [ADDR_WIDTH-1:0] write_addr;
    reg [ADDR_WIDTH-1:0] read_ptr;
    reg [ADDR_WIDTH-1:0] init_write_ptr;
    reg [ADDR_WIDTH-1:0] init_read_ptr;
    
    S2SRAM #(
        .DEPTH  (DEPTH),
        .WIDTH (WIDTH)
    ) S2SRAM_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_addr(write_addr),
        .wr_data(din),
        .rd_en(rd_en),
        .rd_addr(read_ptr),
        .rd_data(dout)
    );

    // write pointer logic
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            write_ptr   <= 0;
            write_addr  <= 0;
        end else if (wr_en & ~full) begin
            write_ptr   <= write_ptr == DEPTH - 1 ? 0 : write_ptr + 1;
            write_addr  <= write_ptr;
        end
    end 

    // read pointer logic
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            read_ptr    <= 0;
        end else if (rd_en & ~empty) begin
            if (rd_jump) begin
                read_ptr    <= init_read_ptr + HOP_LENGTH >= DEPTH ? (init_read_ptr + HOP_LENGTH - DEPTH) : (init_read_ptr + HOP_LENGTH);
            end else begin
                read_ptr    <= read_ptr == DEPTH - 1 ? 0 : read_ptr + 1;
            end 
        end 
    end 
            

            

    // count logic
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count_r <= 0;
        end else begin
            case({wr_en & ~full, rd_en & ~empty})
                2'b10: count_r  <= count_r + 1;
                2'b01: count_r  <= count_r > 0 ? count_r - 1 : 0;
                default: count_r <= count_r;
            endcase
        end 
    end 


    // frm_init logic
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            init_read_ptr <= 0;
            init_write_ptr <= 0;
        end else begin
            if(frm_init) begin
                init_read_ptr <= read_ptr;
                init_write_ptr <= write_ptr;
            end 
        end 
    end 

    assign full = isfull(write_ptr, read_ptr, init_read_ptr);
    assign empty = (read_ptr == write_ptr) ? 1'b1 : 1'b0; //isempty(read_ptr, write_ptr, init_write_ptr);
    assign almost_empty = is_almost_empty(count_r);

    // full logic
    function isfull;
        input [ADDR_WIDTH-1:0] write_ptr;
        input [ADDR_WIDTH-1:0] read_ptr;
        input [ADDR_WIDTH-1:0] init_read_ptr;
        if (write_ptr >= read_ptr) begin
            isfull = 1'b0;
        end else begin
            if(init_read_ptr + HOP_LENGTH - 1 > DEPTH - 1) begin
                isfull = (write_ptr == ((init_read_ptr + HOP_LENGTH - 1) - DEPTH)) ? 1'b1 : 1'b0;
            end else begin
                isfull = (write_ptr == (init_read_ptr + HOP_LENGTH - 1)) ? 1'b1 : 1'b0;
            end
        end
    endfunction    

    // empty logic
    function is_almost_empty;
        input [ADDR_WIDTH-1:0] count_r;
        if (count_r < WIN_LENGTH - HOP_LENGTH + 1) begin
            is_almost_empty = 1'b1;
        end else begin
            is_almost_empty = 1'b0;
        end
    endfunction

    function isempty;
        input [ADDR_WIDTH-1:0] read_ptr;
        input [ADDR_WIDTH-1:0] write_ptr;
        input [ADDR_WIDTH-1:0] init_write_ptr;
        begin
            if(read_ptr == write_ptr) begin
                isempty = 1'b1;
            end else begin
                if ((init_write_ptr + WIN_LENGTH - 1) > DEPTH - 1) begin
                    isempty = (read_ptr == ((init_write_ptr + WIN_LENGTH - 1) - DEPTH)) ? 1'b1 : 1'b0;
                end else begin
                    isempty = (read_ptr == (init_write_ptr + WIN_LENGTH - 1)) ? 1'b1 : 1'b0;
                end
            end
        end
    endfunction


endmodule 