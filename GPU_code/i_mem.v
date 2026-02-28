
module i_mem #(
    parameter INIT_FILE  = "gpu_program.hex"
) (
    input clk,
    input [31:0]    pc,         
    output reg  [31:0]   instruction
);

    // Memory array: DEPTH x DATA_WIDTH
    reg [31:0] mem [0:255]; // 256 entries of 32-bit memory

    // Initialize memory from hex file at simulation/elaboration time.
    initial begin
        $readmemh(INIT_FILE, mem);
    end

    // Synchronous read (registered output) - inferred as block RAM on most FPGAs
    always @(posedge clk) begin
        instruction <= mem[pc[7:0]];
    end

endmodule