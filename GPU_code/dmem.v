module dmem(
    input  clk,
    input  mem_read,      // read enable
    input  mem_write,     // write enable

    input  [7:0]   addr,          // 8-bit address → 0~255 entries
    input  [63:0]  write_data,    // data to write

    output reg  [63:0]  read_data      // data from memory
);

    reg [63:0] mem [0:255]; // 256 entries of 64-bit memory

    always @(*) begin
        if(mem_read)
            read_data = mem[addr];
        else
            read_data = 64'd0;
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[addr] <= write_data;
    end

endmodule
