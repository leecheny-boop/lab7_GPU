module branch(
    input branch_valid,
    input [2:0]  branch_type,

    input [63:0] rs1_data,
    input [63:0] rs2_data,

    input  wire [31:0] pc, // current PC value
    input  wire [31:0] imm,  // sign-extended immediate (already shifted left by 2 for word offset)

    output branch_taken,
    output [31:0] branch_target
);

    // Branch target = PC + offset
    assign branch_target = pc + imm; 

    wire eq = (rs1_data == rs2_data); // for BEQ
    wire ne = (rs1_data != rs2_data); // for BNE
    wire gt = ($signed(rs1_data) >  $signed(rs2_data)); // for BGT (signed comparison)
    wire lt = ($signed(rs1_data) <  $signed(rs2_data)); // for BLT (signed comparison)

    localparam BR_ALWAYS = 3'b000;
    localparam BR_EQ     = 3'b001;
    localparam BR_NE     = 3'b010;
    localparam BR_GT     = 3'b011;
    localparam BR_LT     = 3'b100;

    assign branch_taken = 
        branch_valid && 
        (
            (branch_type == BR_ALWAYS) ? 1'b1 : 
            (branch_type == BR_EQ    ) ? eq   :
            (branch_type == BR_NE    ) ? ne   :
            (branch_type == BR_GT    ) ? gt   :
            (branch_type == BR_LT    ) ? lt   :
                                         1'b0
        );

endmodule