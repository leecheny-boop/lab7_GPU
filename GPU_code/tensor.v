module tensor(
    input tensor_en,
    input [1:0] tensor_op,

    input [63:0] a, 
    input [63:0] b,
    input [63:0] c, // for FMA accumulate
    output reg [63:0] out
);

// Tensor ops (must match control.v)
    localparam TS_MUL  = 2'b00;
    localparam TS_FMA  = 2'b01;
    localparam TS_RELU = 2'b10;

    // Unpack 4 lanes (暫時用 signed 16-bit 來近似 BF16 value)
    wire [15:0] a0 = a[15:0];
    wire [15:0] a1 = a[31:16];
    wire [15:0] a2 = a[47:32];
    wire [15:0] a3 = a[63:48];

    wire [15:0] b0 = b[15:0];
    wire [15:0] b1 = b[31:16];
    wire [15:0] b2 = b[47:32];
    wire [15:0] b3 = b[63:48];

    wire [15:0] c0 = c[15:0];
    wire [15:0] c1 = c[31:16];
    wire [15:0] c2 = c[47:32];
    wire [15:0] c3 = c[63:48];

    // Result lanes
    reg [15:0] r0;
    reg [15:0] r1;
    reg [15:0] r2;
    reg [15:0] r3;

    // multiply lanes
    wire [15:0] m0, m1, m2, m3;
    bf16_mul mul0(.a(a0), .b(b0), .out(m0));
    bf16_mul mul1(.a(a1), .b(b1), .out(m1));
    bf16_mul mul2(.a(a2), .b(b2), .out(m2));
    bf16_mul mul3(.a(a3), .b(b3), .out(m3));

    // FMA = mul + c
    wire [15:0] f0, f1, f2, f3;
    ubf16_adder add0(.a(m0), .b(c0), .out(f0));
    ubf16_adder add1(.a(m1), .b(c1), .out(f1));
    ubf16_adder add2(.a(m2), .b(c2), .out(f2));
    ubf16_adder add3(.a(m3), .b(c3), .out(f3));

    always @(*) begin
        // default: zero
        r0 = 16'd0;
        r1 = 16'd0;
        r2 = 16'd0;
        r3 = 16'd0;

        if (tensor_en)  begin
            case (tensor_op)
                TS_MUL: begin
                    // per-lane multiply (暫時當成 int16 乘法)
                    // 真正 BF16 之後可以在這裡換成 bf16_mul(aX, bX)
                    r0 = m0;
                    r1 = m1;
                    r2 = m2;
                    r3 = m3;
                end

                TS_FMA: begin
                    // per-lane fused multiply-add: a*b + c
                    // 實際硬體你可以分兩級 pipeline: mul → add
                    r0 = f0;
                    r1 = f1;
                    r2 = f2;
                    r3 = f3;
                end

                TS_RELU: begin
                    // per-lane ReLU: max(a, 0)
                    // 這邊用 signed 比較，假設最高 bit 是 sign
                    r0 = (a0[15] == 1'b1) ? 16'd0 : a0;
                    r1 = (a1[15] == 1'b1) ? 16'd0 : a1;
                    r2 = (a2[15] == 1'b1) ? 16'd0 : a2;
                    r3 = (a3[15] == 1'b1) ? 16'd0 : a3;
                end

                default: begin
                    // 保持 0
                end
            endcase
        end

        // pack 回 64-bit
        out = {r3, r2, r1, r0};
    end

endmodule