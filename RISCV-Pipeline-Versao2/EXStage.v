module EX_Stage (
  input  wire         clk,
  input  wire         reset,
  // sinais vindos do estágio ID
  input  wire [31:0]  ID_instr,
  input  wire [4:0]   ID_rd,
  input  wire [6:0]   ID_opcode,
  input  wire         ID_regwrite,
  input  wire [31:0]  ID_imm,
  input  wire [31:0]  ID_r2,
  input  wire [31:0]  alu_result,
  // saídas para o estágio MEM ou para controle de fluxo
  output reg  [31:0]  EX_instr,
  output reg  [4:0]   EX_rd,
  output reg  [6:0]   EX_opcode,
  output reg          EX_regwrite,
  output reg  [31:0]  EX_imm,
  output reg  [31:0]  EX_r2,
  output reg  [31:0]  EX_alu_result
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      EX_instr       <= 32'b0;
      EX_rd          <= 5'b0;
      EX_opcode      <= 7'b0;
      EX_regwrite    <= 1'b0;
      EX_alu_result  <= 32'b0;
      EX_r2          <= 32'b0;
      EX_imm         <= 32'b0;
    end else begin
      // registra os sinais vindos do ID
      EX_instr      <= ID_instr;
      EX_rd         <= ID_rd;
      EX_opcode     <= ID_opcode;
      EX_imm        <= ID_imm;
      EX_r2         <= ID_r2;
      EX_regwrite   <= ID_regwrite;
      EX_alu_result <= alu_result;

    end
  end

endmodule
