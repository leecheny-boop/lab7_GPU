module reg_file (

    input clk, rst, write_en,
    input  [3:0]  rd, // destination register address for write
    input  [63:0] rd_data, // write data

    // Read ports (rs1, rs2, rs3)
    input  [3:0] rs1_addr,
    input  [3:0] rs2_addr,
    input  [3:0] rs3_addr,
    output reg  [63:0]  rs1_data,
    output reg  [63:0]  rs2_data,
    output reg  [63:0]  rs3_data
);

    // register storage
    reg [63:0] regs [0:15];
    integer i;

    // synchronous write (and reset)
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1)
                regs[i] <= 64'b0;
        end 
        else begin
            if (write_en && (rd != 4'b0)) begin // x0 is hardwired to 0
                regs[rd] <= rd_data;
            end
            regs[0] <= 64'd0;  // Ensure x0 is always 0
        end
    end

    // combinational reads with simple write-forwarding
    always @(*) begin
        // rs1
        if (rs1_addr == 4'd0)
            rs1_data = 64'd0;
        else if (write_en && rs1_addr == rd && rd != 4'd0)
            rs1_data = rd_data;     // forwarding
        else
            rs1_data = regs[rs1_addr];

        // rs2
        if (rs2_addr == 4'd0)
            rs2_data = 64'd0;
        else if (write_en && (rs2_addr == rd && rd != 4'd0))
            rs2_data = rd_data;
        else
            rs2_data = regs[rs2_addr];

        // rs3
        if (rs3_addr == 4'd0)
            rs3_data = 64'd0;
        else if (write_en && (rs3_addr == rd && rd != 4'd0))
            rs3_data = rd_data;
        else
            rs3_data = regs[rs3_addr];
    end

endmodule
