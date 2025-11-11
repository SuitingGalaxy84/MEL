class ICBTransaction;
    rand bit [31:0] addr;
    rand bit [31:0] wdata;
    rand bit         read; // 1 for read, 0 for write

    function new();
        // Initialization if needed
    endfunction
endclass
