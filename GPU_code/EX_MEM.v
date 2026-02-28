module EX_MEM(
    input clk, rst, stall, flush,
    input [63:0] ex_alu_result,
    input branch_taken,
    input [31:0] branch_target,
    input mem_read,
    input mem_write,
    input [4:0] ex_rd,
    input [63:0] ex_tensor_result,
    input ex_reg_write_en,  // to know if we need to write back tensor result
    input [1:0]  ex_wb_sel, // to know if writeback data comes from ALU or Tensor unit

    // For STORE instructions
    input  wire [63:0] ex_store_data,    // data to be written to D-MEM (for STORE)
    input  wire [7:0]  ex_dmem_addr, 
    

    output reg [63:0] mem_alu_result,
    output reg mem_branch_taken,
    output reg [31:0] mem_branch_target,
    output reg mem_mem_read,
    output reg mem_mem_write,
    output reg [4:0] mem_rd,
    output reg [63:0] mem_tensor_result
    output reg         mem_reg_write_en,
    output reg  [1:0]  mem_wb_sel
    //???
    output reg  [63:0] mem_store_data,
    output reg  [7:0]  mem_dmem_addr,

);
always @(posedge clk) begin
    if (rst || flush) begin
        mem_alu_result <= 64'd0;
        mem_branch_taken <= 0;
        mem_branch_target <= 32'd0;
        mem_mem_read <= 0;
        mem_mem_write <= 0;
        mem_rd <= 5'b0;
        mem_tensor_result <= 64'd0;
        mem_reg_write_en <= 0;
        mem_wb_sel <= 2'b0;
        mem_store_data <= 64'd0;
        mem_dmem_addr <= 8'b0;
    end else if (stall) begin
        // Hold current values (do not update)
        mem_alu_result <= mem_alu_result;
        mem_branch_taken <= mem_branch_taken;
        mem_branch_target <= mem_branch_target;
        mem_mem_read <= mem_mem_read;
        mem_mem_write <= mem_mem_write;
        mem_rd <= mem_rd;
        mem_tensor_result <= mem_tensor_result;
        mem_reg_write_en <= mem_reg_write_en;
        mem_wb_sel <= mem_wb_sel;
        mem_store_data <= mem_store_data;
        mem_dmem_addr <= mem_dmem_addr;
    end else begin
        // Normal operation: pass values from EX stage to MEM stage
        mem_alu_result <= ex_alu_result;
        mem_branch_taken <= branch_taken;
        mem_branch_target <= branch_target;
        mem_mem_read <= ex_mem_read;
        mem_mem_write <= ex_mem_write;
        mem_rd <= ex_rd;
        mem_tensor_result <= ex_tensor_result; // Pass tensor result for potential writeback
        mem_reg_write_en <= ex_reg_write_en;   // Pass write enable for regfile
        mem_wb_sel <= ex_wb_sel;               // Pass writeback select signal
        // For STORE instructions, pass the data and address to MEM stage
        if (ex_mem_write) begin
            mem_store_data <= ex_store_data;   // Data to be written to D-MEM
            mem_dmem_addr <= ex_dmem_addr;     // Address for D-MEM access
        end else begin
            // For non-STORE instructions, these can be set to default values
            mem_store_data <= 64'd0;           // No data to write
            mem_dmem_addr <= 8'b0;             // No address needed
        end
    end
end