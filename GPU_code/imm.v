module imm(
    input  [31:0] instr,
    input  [5:0]  opcode,
    output reg [31:0] imm_out
);

always @(*) begin
    case (opcode)
        6'b001000: begin   // BRANCH
            imm_out = {{28{instr[3]}}, instr[3:0]} << 2;
        end
        6'b000101: begin   // LOAD
            imm_out = {{28{instr[3]}}, instr[3:0]};
        end
        6'b000110: begin   // STORE
            imm_out = {{28{instr[3]}}, instr[3:0]};
        end
        6'b000111: begin   // CONST (立即數載入)
            imm_out = {{28{instr[3]}}, instr[3:0]};
        end
        default: imm_out = 32'd0;
    endcase
end

endmodule