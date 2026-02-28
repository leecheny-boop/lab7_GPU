module IF_ID(
    input clk, rst, stall, flush,
    input [31:0] if_inst,
    input [31:0] if_pc,

    output reg [31:0] id_inst,
    output reg [31:0] id_pc,

    output wire [5:0]  opcode,
    output wire [3:0]  rd,
    output wire [3:0]  rs1,
    output wire [3:0]  rs2,
    output wire [3:0]  rs3,
    output wire [5:0]  func,
    output wire [4:0]  imm
);

assign opcode  = id_inst[31:26];
assign rd      = id_inst[25:22];
assign rs1     = id_inst[21:18];
assign rs2     = id_inst[17:14];
assign rs3     = id_inst[13:10];
assign func    = id_inst[9:4];
assign imm     = id_inst[3:0]; 

always @(posedge clk) begin
    if (rst || flush) begin
        id_inst <= 32'd0;
        id_pc    <= 32'd0;
    end else if (!stall) begin
        id_inst <= if_inst;
        id_pc    <= if_pc;
    end
end

endmodule