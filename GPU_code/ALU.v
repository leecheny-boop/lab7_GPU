module ALU(
    input alu_en,
    input [2:0] alu_op,
    input [63:0] a,
    input [63:0] b,

    output [63:0] out   
);

    // ALU operations (must match control unit)
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;
    localparam ALU_SHL = 3'b101;
    localparam ALU_SHR = 3'b110;
    localparam ALU_ADD64 = 3'b111;

    // Unpack lanes (16-bit each)
    wire [15:0] a0 = a[15:0];
    wire [15:0] a1 = a[31:16];
    wire [15:0] a2 = a[47:32];
    wire [15:0] a3 = a[63:48];

    wire [15:0] b0 = b[15:0];
    wire [15:0] b1 = b[31:16];
    wire [15:0] b2 = b[47:32];
    wire [15:0] b3 = b[63:48];

    // Result lanes
    reg [15:0] r0;
    reg [15:0] r1;
    reg [15:0] r2;
    reg [15:0] r3;
    reg [63:0] temp_64; // for ALU_ADD64 result

    // Shift amount: use low 4 bits of src_b[15:0]
    wire [3:0] shamt = b[3:0];

    always @(*) begin
        // default: all zeros
        r0 = 16'd0;
        r1 = 16'd0;
        r2 = 16'd0;
        r3 = 16'd0;
        temp_64 = 64'd0;

        if (alu_en) begin
            case (alu_op)
                ALU_ADD: begin
                    r0 = a0 + b0;
                    r1 = a1 + b1;
                    r2 = a2 + b2;
                    r3 = a3 + b3;
                end

                ALU_SUB: begin
                    r0 = a0 - b0;
                    r1 = a1 - b1;
                    r2 = a2 - b2;
                    r3 = a3 - b3;
                end

                ALU_AND: begin
                    r0 = a0 & b0;
                    r1 = a1 & b1;
                    r2 = a2 & b2;
                    r3 = a3 & b3;
                end

                ALU_OR: begin
                    r0 = a0 | b0;
                    r1 = a1 | b1;
                    r2 = a2 | b2;
                    r3 = a3 | b3;
                end

                ALU_XOR: begin
                    r0 = a0 ^ b0;
                    r1 = a1 ^ b1;
                    r2 = a2 ^ b2;
                    r3 = a3 ^ b3;
                end

                ALU_SHL: begin
                    r0 = a0 << shamt;
                    r1 = a1 << shamt;
                    r2 = a2 << shamt;
                    r3 = a3 << shamt;
                end

                ALU_SHR: begin
                    // Guaranteed logical right shift (zero extension)
                    r0 = a0 >> shamt;
                    r1 = a1 >> shamt;
                    r2 = a2 >> shamt;
                    r3 = a3 >> shamt;
                end
                ALU_ADD64: begin
                    temp_64 = a + b; // 64-bit add without lane slicing
                    r0 = temp_64[15:0];
                    r1 = temp_64[31:16];
                    r2 = temp_64[47:32];
                    r3 = temp_64[63:48];
                end

                default: begin
                    // default is already 0
                end
            endcase
        end
    end

    assign out = {r3, r2, r1, r0};

endmodule
