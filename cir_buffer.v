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
    output reg [WIDTH-1:0]      dout,
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

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] write_ptr;
    reg [ADDR_WIDTH-1:0] read_ptr;
    reg [ADDR_WIDTH-1:0] init_write_ptr;
    reg [ADDR_WIDTH-1:0] init_read_ptr;
    


    // write pointer logic
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            write_ptr   <= 0;
        end else if (wr_en & ~full) begin
            write_ptr   <= write_ptr == DEPTH - 1 ? 0 : write_ptr + 1;
        end
    end 

    // read pointer logic
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            read_ptr    <= 0;
        end else if (rd_en & ~empty) begin
            read_ptr    <= read_ptr == DEPTH - 1 ? 0 : read_ptr + 1;
        end 
    end 

    // count logic
    integer i;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count_r <= 0;
        end else begin
            case({wr_en & ~full, rd_en & ~empty})
                2'b10: count_r  <= count_r + 1;
                2'b01: count_r  <= count_r - 1;
                default: count_r <= count_r;
            endcase
        end 
    end 

    // memory logic
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= 0;
            end
        end else begin
            if (wr_en & ~full) begin
                mem[write_ptr] <= din;
            end 
            if (rd_en & ~empty) begin
                dout <= mem[read_ptr];
            end 
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

    assign full = isfull(write_ptr, init_read_ptr);
    assign empty = (count_r == 0) ? 1'b1 : 1'b0;
    assign almost_empty = is_almost_empty(count_r);

    // full logic
    function isfull;
        input [ADDR_WIDTH-1:0] write_ptr;
        input [ADDR_WIDTH-1:0] init_read_ptr;
        if (write_ptr == init_read_ptr + HOP_LENGTH - 1) begin
            isfull = 1'b1;
        end else begin
            isfull = 1'b0;
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


endmodule 