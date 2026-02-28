module bf16_add(
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] out
);
    wire [7:0] exp_a  = a[14:7];
    wire [6:0] frac_a = a[6:0];
    
    wire [7:0] exp_b  = b[14:7];
    wire [6:0] frac_b = b[6:0];

    wire a_is_zero = (a[14:0] == 15'd0);
    wire b_is_zero = (b[14:0] == 15'd0);

    // Hidden-bit mantissa (這邊就算輸入是 0 被補了 1 也沒關係，因為最後會被擋掉)
    wire [7:0] mant_a = {1'b1, frac_a};
    wire [7:0] mant_b = {1'b1, frac_b};

    // Larger exponent logic
    wire a_is_larger = (exp_a >= exp_b);
    wire [7:0] max_exp = a_is_larger ? exp_a : exp_b;
    wire [7:0] min_exp = a_is_larger ? exp_b : exp_a;
    wire [7:0] exp_diff = max_exp - min_exp;

    // Align mantissas
    wire [7:0] large_mant = a_is_larger ? mant_a : mant_b;
    wire [7:0] small_mant = a_is_larger ? mant_b : mant_a;

    wire [7:0] shifted_small_mant = 
              (exp_diff >= 8) ? 8'd0 : (small_mant >> exp_diff);

    // Add
    wire [8:0] sum_mant = large_mant + shifted_small_mant;

    // Normalize
    wire norm_shift = sum_mant[8];
    wire [6:0] final_frac = norm_shift ? sum_mant[7:1] : sum_mant[6:0];

    wire [8:0] new_exp_raw = max_exp + norm_shift;

    wire overflow = (new_exp_raw >= 9'd255);
    wire [7:0] final_exp = overflow ? 8'hFF : new_exp_raw[7:0];

    // ==========================================
    // 終極大會合 (單一 assign，解決 Multiple Drivers)
    // 優先權順序：a是0 -> b是0 -> 溢位 -> 正常輸出
    // ==========================================
    assign out =
          a_is_zero ? b :
          b_is_zero ? a :
          overflow  ? {1'b0, 8'hFF, 7'd0} :
          {1'b0, final_exp, final_frac};

endmodule