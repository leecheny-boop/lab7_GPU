module MEM_WB(
    input clk, rst, stall, flush,
    //======== Inputs from MEM stage =========
    input  wire [63:0] mem_alu_result,
    input  wire [63:0] mem_tensor_result,
    input  wire [63:0] mem_read_data,     // from dmem

    input  wire [4:0]  mem_rd,

    input  wire        mem_reg_write_en,
    input  wire [1:0]  mem_wb_sel,        // 00=ALU, 01=Tensor, 10=MEM, 11=IMM(optional)

    //======== Outputs to WB stage ===========
    output reg  [63:0] wb_alu_result,
    output reg  [63:0] wb_tensor_result,
    output reg  [63:0] wb_read_data,

    output reg  [4:0]  wb_rd,

    output reg         wb_reg_write_en,
    output reg  [1:0]  wb_wb_sel
);

always @(posedge clk) begin
    if (rst || flush) begin
        wb_alu_result     <= 64'd0;
        wb_tensor_result  <= 64'd0;
        wb_read_data      <= 64'd0;

        wb_rd             <= 5'd0;

        wb_reg_write_en   <= 1'b0;
        wb_wb_sel         <= 2'd0;
    end
    else if (!stall) begin
        wb_alu_result     <= mem_alu_result;
        wb_tensor_result  <= mem_tensor_result;
        wb_read_data      <= mem_read_data;

        wb_rd             <= mem_rd;

        wb_reg_write_en   <= mem_reg_write_en;
        wb_wb_sel         <= mem_wb_sel;
    end
end

endmodule

)