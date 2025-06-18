module PC_Update (
  input  wire        clk,
  input  wire        reset,
  input  wire [31:0] pc_anterior,    // agora 32 bits
  input  wire        branch_taken,
  input  wire        flag_jump,      // inclua este port
  input  wire [31:0] branch_target,
  input  wire [31:0] ID_PC,
  input  wire [31:0] ID_imm,         // e este também com 32 bits
  output reg  [31:0] PC,
  output reg  [31:0] link
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 32'b0;
        else
            if (branch_taken == 1) begin //BGE/BLT
                PC <= branch_target;
            end

            else if(flag_jump == 1) begin //JAL
                PC <= ID_PC + ID_imm;
                link <= pc_anterior + 4;
            end

            else
                PC <= pc_anterior + 4;
            end
endmodule