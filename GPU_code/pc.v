module PC(
    input rst, clk, stall, stop,
    input branch_valid,
    input [7:0] branch_target,
    //input [63:0] pc_in,
    output reg [31: 0] pc_out
);

always @(posedge clk) begin
    if(rst) begin
        pc_out <= 32'd0;
    end else if(stall | stop) begin
        pc_out <= pc_out;
    end else if(branch_valid) begin
        pc_out <= branch_target;
    end else begin
        pc_out <= pc_out + 1;
    end
end
endmodule
