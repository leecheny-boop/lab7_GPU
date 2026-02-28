module gpu(
    input clk, rst
);

    // 1. IF stage
    wire [31:0] pc;
    wire [31:0] if_instr;

    // no stall/stop for now
    wire        stall  = 1'b0;
    wire        stop   = 1'b0;

    // branch feedback from EX stage
    wire        branch_taken_ex;
    wire [31:0] branch_target_ex;

    PC u_pc (
        .clk          (clk),
        .rst          (rst),
        .stall        (stall),
        .stop         (stop),
        .branch_valid (branch_taken_ex),   // 真的有跳才更新
        .branch_target(branch_target_ex),
        .pc_out       (pc)
    );

    // Instruction memory: 用 pc[7:0] index 256 entries
    i_mem u_imem (
        .clk        (clk),
        .pc         (pc),
        .instruction(if_instr)
    );

    // 2. IF/ID
    wire [31:0] id_instr;
    wire [31:0] id_pc;

    // 先不做真正的 flush，簡單接 0
    wire flush_if_id = 1'b0; // 以後可以用 branch_taken_ex 當 flush

    if_id u_if_id (
        .clk    (clk),
        .rst    (rst),
        .stall  (stall),
        .flush  (flush_if_id),
        .if_instr(if_instr),
        .if_pc  (pc),
        .id_instr(id_instr),
        .id_pc  (id_pc)
    );
    // 3. ID stage: decode + regfile + control + imm

    // ---- Decode fields from id_instr ----
    wire [5:0] id_opcode = id_instr[31:26];
    wire [3:0] id_rd4    = id_instr[25:22];
    wire [3:0] id_rs1_4  = id_instr[21:18];
    wire [3:0] id_rs2_4  = id_instr[17:14];
    wire [3:0] id_rs3_4  = id_instr[13:10];
    wire [5:0] id_func   = id_instr[9:4];
    wire [3:0] id_imm4   = id_instr[3:0];

    // reg_file 用 5-bit address, 但實際只用到 0~15
    wire [4:0] id_rd   = {1'b0, id_rd4};
    wire [4:0] id_rs1  = {1'b0, id_rs1_4};
    wire [4:0] id_rs2  = {1'b0, id_rs2_4};
    wire [4:0] id_rs3  = {1'b0, id_rs3_4};

    // ---- Control outputs ----
    wire       id_alu_en;
    wire [2:0] id_alu_op;

    wire       id_tensor_en;
    wire [1:0] id_tensor_op;

    wire       id_mem_read;
    wire       id_mem_write;

    wire       id_branch_valid;
    wire [2:0] id_branch_type;

    wire       id_reg_write_en;
    wire [1:0] id_wb_sel;
    wire       id_data_type;  // 暫時沒特別用到
    wire       id_stop;       // HALT，暫時沒用

    control u_control (
        .opcode       (id_opcode),
        .func         (id_func),

        .alu_en       (id_alu_en),
        .alu_op       (id_alu_op),

        .tensor_en    (id_tensor_en),
        .tensor_op    (id_tensor_op),

        .mem_read     (id_mem_read),
        .mem_write    (id_mem_write),

        .branch_valid (id_branch_valid),
        .branch_type  (id_branch_type),

        .reg_write_en (id_reg_write_en),
        .wb_sel       (id_wb_sel),

        .data_type    (id_data_type),
        .stop         (id_stop)
    );

    // ---- Immediate generator ----
    wire [31:0] id_imm;

    imm_gen u_imm_gen (
        .instr   (id_instr),
        .opcode  (id_opcode),
        .imm_out (id_imm)
    );

    // ---- Register file ----
    wire [63:0] id_rs1_data;
    wire [63:0] id_rs2_data;
    wire [63:0] id_rs3_data;

    // WB stage write-back signals (from later)
    wire        wb_reg_write_en;
    wire [4:0]  wb_rd;
    wire [63:0] wb_data;

    reg_file u_reg_file (
        .clk       (clk),
        .rst       (rst),
        .write_en  (wb_reg_write_en),
        .rd        (wb_rd),
        .rd_data   (wb_data),

        .rs1_addr  (id_rs1),
        .rs2_addr  (id_rs2),
        .rs3_addr  (id_rs3),
        .rs1_data  (id_rs1_data),
        .rs2_data  (id_rs2_data),
        .rs3_data  (id_rs3_data)
    );

    // 4. ID/EX pipeline register
    wire [63:0] ex_rs1_data;
    wire [63:0] ex_rs2_data;
    wire [63:0] ex_rs3_data;
    wire [4:0]  ex_rd;
    wire [31:0] ex_imm;
    wire [31:0] ex_pc;

    wire        ex_alu_en;
    wire [2:0]  ex_alu_op;

    wire        ex_tensor_en;
    wire [1:0]  ex_tensor_op;

    wire        ex_mem_read;
    wire        ex_mem_write;

    wire        ex_reg_write_en;
    wire [1:0]  ex_wb_sel;

    wire        ex_branch_valid;
    wire [2:0]  ex_branch_type;

    wire flush_id_ex = 1'b0; // 之後可以用 branch_taken_ex

    id_ex u_id_ex (
        .clk           (clk),
        .rst           (rst),
        .stall         (stall),
        .flush         (flush_id_ex),

        .id_rs1_data   (id_rs1_data),
        .id_rs2_data   (id_rs2_data),
        .id_rs3_data   (id_rs3_data),
        .id_rd         (id_rd),
        .id_imm        (id_imm),
        .id_pc         (id_pc),

        .id_alu_en     (id_alu_en),
        .id_alu_op     (id_alu_op),

        .id_tensor_en  (id_tensor_en),
        .id_tensor_op  (id_tensor_op),

        .id_mem_read   (id_mem_read),
        .id_mem_write  (id_mem_write),

        .id_reg_write_en(id_reg_write_en),
        .id_wb_sel     (id_wb_sel),

        .id_branch_valid(id_branch_valid),
        .id_branch_type(id_branch_type),

        .ex_rs1_data   (ex_rs1_data),
        .ex_rs2_data   (ex_rs2_data),
        .ex_rs3_data   (ex_rs3_data),
        .ex_rd         (ex_rd),
        .ex_imm        (ex_imm),
        .ex_pc         (ex_pc),

        .ex_alu_en     (ex_alu_en),
        .ex_alu_op     (ex_alu_op),

        .ex_tensor_en  (ex_tensor_en),
        .ex_tensor_op  (ex_tensor_op),

        .ex_mem_read   (ex_mem_read),
        .ex_mem_write  (ex_mem_write),

        .ex_reg_write_en(ex_reg_write_en),
        .ex_wb_sel     (ex_wb_sel),

        .ex_branch_valid(ex_branch_valid),
        .ex_branch_type (ex_branch_type)
    );

    // EX stage

    // ALU
    wire [63:0] ex_alu_result;

    ALU u_alu (
        .alu_en (ex_alu_en),
        .alu_op (ex_alu_op),
        .a      (ex_rs1_data),
        .b      (ex_rs2_data),
        .out    (ex_alu_result)
    );

    //Tensor
    wire [63:0] ex_tensor_result;

    tensor u_tensor (
        .tensor_en (ex_tensor_en),
        .tensor_op (ex_tensor_op),
        .a         (ex_rs1_data),
        .b         (ex_rs2_data),
        .c         (ex_rs3_data),
        .out       (ex_tensor_result)
    );

    //Branch
    branch u_branch (
        .branch_valid (ex_branch_valid),
        .branch_type  (ex_branch_type),
        .rs1_data     (ex_rs1_data),
        .rs2_data     (ex_rs2_data),
        .pc           (ex_pc),
        .imm          (ex_imm),

        .branch_taken (branch_taken_ex),
        .branch_target(branch_target_ex)
    );

    // --- For memory ---
    wire [7:0]  ex_dmem_addr  = ex_alu_result[7:0]; // 用 ALU 結果當位址（低 8 bits）
    wire [63:0] ex_store_data = ex_rs2_data;        // store 的資料

    // 6. EX/MEM pipeline register
    wire [63:0] mem_alu_result;
    wire [63:0] mem_tensor_result;
    wire [63:0] mem_store_data;
    wire [7:0]  mem_dmem_addr;

    wire [4:0]  mem_rd;
    wire        mem_mem_read;
    wire        mem_mem_write;
    wire        mem_reg_write_en;
    wire [1:0]  mem_wb_sel;

    wire flush_ex_mem = 1'b0;

    ex_mem u_ex_mem (
        .clk            (clk),
        .rst            (rst),
        .stall          (stall),
        .flush          (flush_ex_mem),

        .ex_alu_result  (ex_alu_result),
        .ex_tensor_result(ex_tensor_result),
        .ex_store_data  (ex_store_data),
        .ex_dmem_addr   (ex_dmem_addr),

        .ex_rd          (ex_rd),

        .ex_mem_read    (ex_mem_read),
        .ex_mem_write   (ex_mem_write),

        .ex_reg_write_en(ex_reg_write_en),
        .ex_wb_sel      (ex_wb_sel),

        .mem_alu_result (mem_alu_result),
        .mem_tensor_result(mem_tensor_result),
        .mem_store_data (mem_store_data),
        .mem_dmem_addr  (mem_dmem_addr),

        .mem_rd         (mem_rd),

        .mem_mem_read   (mem_mem_read),
        .mem_mem_write  (mem_mem_write),

        .mem_reg_write_en(mem_reg_write_en),
        .mem_wb_sel     (mem_wb_sel)
    );


    // 7. MEM stage: Data Memory
    wire [63:0] mem_read_data;

    dmem u_dmem (
        .clk        (clk),
        .mem_read   (mem_mem_read),
        .mem_write  (mem_mem_write),
        .addr       (mem_dmem_addr),
        .write_data (mem_store_data),
        .read_data  (mem_read_data)
    );

    // 8. MEM/WB pipeline register
    wire [63:0] wb_alu_result;
    wire [63:0] wb_tensor_result;
    wire [63:0] wb_read_data;
    wire [4:0]  wb_rd_reg;
    wire        wb_reg_write_en_reg;
    wire [1:0]  wb_wb_sel;

    wire flush_mem_wb = 1'b0;

    mem_wb u_mem_wb (
        .clk            (clk),
        .rst            (rst),
        .stall          (stall),
        .flush          (flush_mem_wb),

        .mem_alu_result    (mem_alu_result),
        .mem_tensor_result (mem_tensor_result),
        .mem_read_data     (mem_read_data),
        .mem_rd            (mem_rd),
        .mem_reg_write_en  (mem_reg_write_en),
        .mem_wb_sel        (mem_wb_sel),

        .wb_alu_result     (wb_alu_result),
        .wb_tensor_result  (wb_tensor_result),
        .wb_read_data      (wb_read_data),
        .wb_rd             (wb_rd_reg),
        .wb_reg_write_en   (wb_reg_write_en_reg),
        .wb_wb_sel         (wb_wb_sel)
    );


    // WB stage
    reg [63:0] wb_data_reg;

    always @(*) begin
        case (wb_wb_sel)
            2'b00: wb_data_reg = wb_alu_result;
            2'b01: wb_data_reg = wb_tensor_result;
            2'b10: wb_data_reg = wb_read_data;
            2'b11: wb_data_reg = 64'd0; // TODO: 支援 CONST / TID 時可改成立即數
            default: wb_data_reg = 64'd0;
        endcase
    end

    // expose to reg_file (上面 reg_file 用的那三條)
    assign wb_data          = wb_data_reg;
    assign wb_rd            = wb_rd_reg;
    assign wb_reg_write_en  = wb_reg_write_en_reg;

endmodule

if opcode == OP_TID:
    writeback = thread_id;
else if opcode == OP_CONST:
    writeback = imm;