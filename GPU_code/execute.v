module execute(
    input  alu_enable,
    input  [2:0]  alu_op,

    input  branch_valid,
    input  [2:0]  branch_type,

    input  [63:0] rs1_data,
    input  [63:0] rs2_data,
    input  [31:0] ex_pc,
    input  [31:0] branch_imm,

    output [63:0] alu_result,
    output branch_taken,
    output [31:0] branch_target
);

    // --- ALU ---
    wire [63:0] alu_out;

    ALU  alu(
        .alu_en(alu_en),
        .a     (rs1_data),
        .b     (rs2_data),
        .alu_op(alu_op),
        .result(alu_out)
    );

    // 如果 alu_enable=0，就輸出 0（或保留 alu_raw 看你要不要）
    assign alu_result = alu_enable ? alu_raw : 64'd0;

    // --- Branch Unit ---
    branch BRANCH(
        .branch_valid (branch_valid),
        .branch_type  (branch_type),
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .pc           (ex_pc),
        .imm          (branch_imm),
        .branch_taken (branch_taken),
        .branch_target(branch_target)
    );

endmodule
