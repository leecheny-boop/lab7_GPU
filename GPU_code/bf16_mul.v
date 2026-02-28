module bf16_mul(
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] out
);
    // ===== BF16 欄位擷取 (直接忽略 a[15] 和 b[15] 的符號位) =====
    wire [7:0] exp_a  = a[14:7];
    wire [6:0] frac_a = a[6:0];

    wire [7:0] exp_b  = b[14:7];
    wire [6:0] frac_b = b[6:0];

    // 判斷是否為 0 (只看指數和尾數)
    wire a_is_zero = (a[14:0] == 15'b0); 
    wire b_is_zero = (b[14:0] == 15'b0);

    // ==========================================
    // 1. 尾數 (Mantissa) 乘法
    // ==========================================
    // 補上隱藏的 1
    wire [7:0] mant_a = {1'b1, frac_a};
    wire [7:0] mant_b = {1'b1, frac_b};

    wire [15:0] mant_mult = mant_a * mant_b;

    // 判斷是否需要正規化 (最高位是否進位)
    wire norm_shift = mant_mult[15];

    // 截斷 (Truncation) 取得小數點後 7 bit
    wire [6:0] final_frac = norm_shift ? mant_mult[14:8] : mant_mult[13:7];

    // ==========================================
    // 2. 指數 (Exponent) 計算 (修復 Underflow Bug)
    // ==========================================
    // 先全部用 10-bit 相加，保證絕對不會出現負數
    wire [9:0] raw_exp_sum = exp_a + exp_b + norm_shift;

    // 判斷 Underflow 與 Overflow
    wire underflow = (raw_exp_sum <= 127);
    wire overflow  = (raw_exp_sum >= 382); // 255 + 127 = 382

    // 扣掉 Bias (127)
    wire [7:0] final_exp = raw_exp_sum - 10'd127;

    // ==========================================
    // 3. 最終組裝 (符號位強迫寫死為 1'b0)
    // ==========================================
    assign out =
          (a_is_zero | b_is_zero | underflow) ? 16'd0 :
          overflow ? {1'b0, 8'hFF, 7'b0} :
          {1'b0, final_exp, final_frac};

endmodule