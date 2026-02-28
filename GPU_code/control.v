module control(
    input  [5:0] opcode,
    input  [5:0] func,

    // ALU 
    output reg alu_en,
    output reg [2:0] alu_op,      
    //Tensor
    output reg tensor_en,
    output reg [1:0] tensor_op,
    // memory interface
    output reg mem_read,
    output reg mem_write,
    // branch 
    output reg branch_valid,      
    output reg [2:0] branch_type,  
    // writeback
    output reg reg_write_en,
    output reg [1:0] wb_sel,         // 00=ALU, 01=Tensor, 10=Memory
    //data type (integer vs BF16) 
    output reg data_type,  // 0 = INT16, 1 = BF16
    output reg stop
);

/*
    localparam OP_VADD   = 6'b000000;
    localparam OP_VSUB   = 6'b000001;
    localparam OP_VMUL   = 6'b000010;
    localparam OP_VFMA   = 6'b000011;
    localparam OP_RELU   = 6'b000100;
    localparam OP_LOAD   = 6'b000101;
    localparam OP_STORE  = 6'b000110;
    localparam OP_CONST  = 6'b000111; 
    localparam OP_BRANCH = 6'b001000;
    localparam OP_VAND   = 6'b001001;
    localparam OP_VOR    = 6'b001010;
    localparam OP_VXOR   = 6'b001011;
    localparam OP_VSHL   = 6'b001100;
    localparam OP_VSHR   = 6'b001101;
    localparam OP_TID    = 6'b001110;   // ⭐ 新增：Thread ID load
    localparam OP_ADD64  = 6'b001111; // 64-bit 純量加法 (算指標/記憶體位址專用)
    localparam OP_HALT   = 6'b111111; // 程式結束 (讓 PC 停止)
*/

// ALU operations
localparam ALU_ADD = 3'b000;
localparam ALU_SUB = 3'b001;
localparam ALU_AND = 3'b010;
localparam ALU_OR  = 3'b011;
localparam ALU_XOR = 3'b100;
localparam ALU_SHL = 3'b101;
localparam ALU_SHR = 3'b110;
localparam ALU_ADD64 = 3'b111;

// Tensor ops
localparam TS_MUL   = 2'b00;
localparam TS_FMA   = 2'b01;
localparam TS_RELU  = 2'b10;

// Branch types
localparam BR_ALWAYS = 3'b000;
localparam BR_EQ     = 3'b001;
localparam BR_NE     = 3'b010;
localparam BR_GT     = 3'b011;
localparam BR_LT     = 3'b100;

/*
WB_ALU    = 2'b00;
WB_TENSOR = 2'b01;
WB_MEM    = 2'b10;
WB_IMM    = 2'b11; // 新增：直接寫回常數
*/


// Main control logic
always @(*) begin
    // default values
    alu_en        = 0;
    alu_op        = 0;
    tensor_en     = 0;
    tensor_op     = 0;
    mem_read      = 0;
    mem_write     = 0;
    branch_valid  = 0;
    branch_type   = 0;
    reg_write_en  = 0;  // default no writeback
    wb_sel        = 2'b00; // default ALU result to writeback
    data_type     = 0;  // default INT16 or BF16 (for tensor ops)
    stop          = 0; // default not stop

    case (opcode)

        // OP_VADD 
        6'b000000: begin   
            alu_en        = 1;
            alu_op        = ALU_ADD;
            reg_write_en  = 1;
            wb_sel        = 2'b00;
            data_type     = 0;  // INT16
        end

        // OP_VSUB
        6'b000001: begin  
            alu_en        = 1;
            alu_op        = ALU_SUB;
            reg_write_en  = 1;
            wb_sel        = 2'b00;
            data_type     = 0;  // INT16
        end

        // OP_VMUL
        6'b000010: begin  
            tensor_en     = 1;
            tensor_op     = TS_MUL;
            reg_write_en  = 1;
            wb_sel        = 2'b01;
            data_type     = 1;  // BF16
        end

        // OP_VFMA
        6'b000011: begin  
            tensor_en     = 1;
            tensor_op     = TS_FMA;
            reg_write_en  = 1;
            wb_sel        = 2'b01;
            data_type     = 1;  // BF16
        end

        // OP_RELU
        6'b000100: begin 
            tensor_en     = 1;
            tensor_op     = TS_RELU;
            reg_write_en  = 1;
            wb_sel        = 2'b01;
            data_type     = 1;  // BF16
        end

        // OP_LOAD
       6'b000101: begin  
            mem_read     = 1;
            reg_write_en = 1;
            wb_sel       = 2'b10;
        end

        // OP_STORE
        6'b000110: begin  
            mem_write    = 1;
            reg_write_en = 0;
        end

        // OP_CONST
        6'b000111: begin 
            reg_write_en = 1;
            wb_sel       = 2'b11; // write back immediate value (from instruction)
        end

        // OP_BRANCH
        6'b001000: begin 
            branch_valid = 1;
            branch_type  = func[2:0];
            reg_write_en = 0;
        end

        // OP_VAND  
        6'b001001: begin 
            alu_en       = 1;
            alu_op       = ALU_AND;
            reg_write_en = 1;
            wb_sel       = 2'b00;
            data_type    = 0; // INT16
        end

        //OP_VOR
        6'b001010: begin 
            alu_en    = 1;
            alu_op       = ALU_OR;
            reg_write_en = 1;
            wb_sel       = 2'b00;
            data_type    = 0; // INT16
        end

        //OP_VXOR
        6'b001011: begin 
            alu_en       = 1;
            alu_op       = ALU_XOR;
            reg_write_en = 1;
            wb_sel       = 2'b00;
            data_type    = 0; // INT16
        end

        //OP_VSHL
        6'b001100: begin   
            alu_en       = 1;
            alu_op       = ALU_SHL;
            reg_write_en = 1;
            wb_sel       = 2'b00;
            data_type    = 0; // INT16
        end

        //OP_VSHR
        6'b001101: begin   
            alu_en       = 1;
            alu_op       = ALU_SHR;
            reg_write_en = 1;
            wb_sel       = 2'b00;
            data_type    = 0; // INT16
        end

        //OP_TID
        6'b001110: begin 
            reg_write_en = 1;
            wb_sel       = 2'b11; // write back immediate value (from instruction)
        end
        
        // OP_ADD64 (64-bit 純量加法)
        6'b001111: begin   
            alu_en        = 1;
            alu_op        = ALU_ADD64; // 指示 ALU 不要切塊，整條 64-bit 直接加
            reg_write_en  = 1;
            wb_sel        = 2'b00;
            data_type     = 0;  // 算位址當然是整數
        end

        // OP_HALT (程式結束)
        6'b111111: begin 
            stop = 1; // stop pc from updating, effectively halting the program
        end

        default: begin
            // Default case - no operation
        end
    endcase
end
endmodule