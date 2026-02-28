module ID_EX(
    input clk, rst, flush, stall,

    //control signals
    input id_alu_en,
    input [2:0] id_alu_op,
    input id_tensor_en,
    input [1:0] id_tensor_op,
    input id_mem_read,
    input id_mem_write,
    input id_branch_valid,
    input [2:0] id_branch_type,
    input [1:0] id_wb_sel,
    input id_data_type,

    // register file outputs (operands)
    input [63:0] id_rs1_data,
    input [63:0] id_rs2_data,
    input [63:0] id_rs3_data,

    input [3:0] id_rd_addr,
    input id_reg_write_en,

    // immediate and PC from ID stage
    input [31:0] id_imm32
    input [31:0] id_pc,   // for branch target calculation

    // outputs to EX stage
    output reg ex_alu_en,
    output reg [2:0] ex_alu_op,
    output reg ex_tensor_en,
    output reg [1:0] ex_tensor_op,
    output reg ex_mem_read,
    output reg ex_mem_write,    
    output reg ex_branch_valid,
    output reg [2:0] ex_branch_type,
    output reg [1:0] ex_wb_sel,
    output reg ex_data_type,

    output reg [63:0] ex_rs1_data,
    output reg [63:0] ex_rs2_data,
    output reg [63:0] ex_rs3_data,
    output reg [3:0] ex_rd_addr,
    output reg ex_reg_write_en,
    output reg [31:0] ex_imm32,
    output reg [31:0] ex_pc

);

    always @(posedge clk) begin
        if (rst || flush) begin
            // Clear all outputs on reset or flush
            ex_alu_en <= 0;
            ex_alu_op <= 3'b0;
            ex_tensor_en <= 0;
            ex_tensor_op <= 2'b0;
            ex_mem_read <= 0;
            ex_mem_write <= 0;
            ex_branch_valid <= 0;
            ex_branch_type <= 3'b0;
            ex_wb_sel <= 2'b0;
            ex_data_type <= 0;

            ex_rs1_data <= 64'd0;
            ex_rs2_data <= 64'd0;
            ex_rs3_data <= 64'd0;
            ex_rd_addr <= 4'b0;
            ex_reg_write_en <= 0;
            ex_imm32 <= 32'd0;
            ex_pc <= 32'd0;
        end else if (!stall) begin
            // Normal operation: pass values from ID to EX
            ex_alu_en <= id_alu_en;
            ex_alu_op <= id_alu_op;
            ex_tensor_en <= id_tensor_en;
            ex_tensor_op <= id_tensor_op;
            ex_mem_read <= id_mem_read;
            ex_mem_write <= id_mem_write;    
            ex_branch_valid <= id_branch_valid;
            ex_branch_type <= id_branch_type;
            ex_wb_sel <= id_wb_sel;
            ex_data_type <= id_data_type;

            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
            ex_rs3_data <= id_rs3_data;
            ex_rd_addr <= id_rd_addr;
            ex_reg_write_en <= id_reg_write_en;
            ex_imm32 <= id_imm32;
            ex_pc <= id_pc;            
        end
    end