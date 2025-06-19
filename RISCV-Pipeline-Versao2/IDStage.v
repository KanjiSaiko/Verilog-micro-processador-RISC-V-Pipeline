module ID_Stage (
  input  wire         clk,
  input  wire         reset,
  input  wire [31:0]  IF_PC,
  input  wire [31:0]  IF_instr,
  input  wire         branch_taken,

  // Saídas para o estágio EX
  output reg  [31:0]  ID_PC,
  output reg  [31:0]  ID_instr,
  output reg  [31:0]  ID_imm,
  output reg  [31:0]  imm_sext,
  output reg  [31:0]  imm_shift,
  output reg         flag_jump,
  output reg         ID_regwrite,
  output reg  [4:0]  Indice_R1,
  output reg  [4:0]  Indice_R2,
  output reg  [4:0]  ID_rd,
  output reg  [6:0]  ID_opcode,
  output reg  [2:0]  ID_funct3,
  output reg  [6:0]  ID_funct7
);

  always @(posedge clk or posedge reset) begin
    if (reset || branch_taken || IF_instr[6:0] == 7'b1101111) begin
      // flush/limpeza em reset, branch ou JAL
      ID_instr     <= 32'b0;
      ID_PC        <= 32'b0;
      ID_imm       <= 32'b0;
      imm_sext     <= 32'b0;
      imm_shift    <= 32'b0;
      flag_jump    <= 1'b0;
      ID_regwrite  <= 1'b0;
      Indice_R1  <= 5'b0;
      Indice_R2  <= 5'b0;
      ID_rd        <= 5'b0;
      ID_opcode    <= 7'b0;
      ID_funct3    <= 3'b0;
      ID_funct7    <= 7'b0;
    end else begin
      // passar adiante
      ID_instr  <= IF_instr;
      ID_PC     <= IF_PC;
      flag_jump <= 1'b0;

      case (IF_instr[6:0])
        // I-Type: ADDI, LW
        7'b0010011,
        7'b0000011: begin
          ID_opcode   <= IF_instr[6:0];
          ID_funct3   <= IF_instr[14:12];
          ID_rd       <= IF_instr[11:7];
          Indice_R1 <= IF_instr[19:15];
          ID_imm      <= {{20{IF_instr[31]}}, IF_instr[31:20]};
          ID_regwrite <= 1;
        end

        // S-Type: SW
        7'b0100011: begin
          ID_opcode   <= IF_instr[6:0];
          ID_funct3   <= IF_instr[14:12];
          Indice_R1 <= IF_instr[19:15];
          Indice_R2 <= IF_instr[24:20];
          ID_imm      <= {{20{IF_instr[31]}}, IF_instr[31:25], IF_instr[11:7]};
          ID_regwrite <= 0;
        end

        // R-Type: ADD, SUB, MUL…
        7'b0110011: begin
          ID_opcode   <= IF_instr[6:0];
          ID_funct3   <= IF_instr[14:12];
          ID_funct7   <= IF_instr[31:25];
          ID_rd       <= IF_instr[11:7];
          Indice_R1 <= IF_instr[19:15];
          Indice_R2 <= IF_instr[24:20];
          ID_regwrite <= 1;
        end

        // B-Type: BGE, BLT
        7'b1100011: begin
          ID_opcode    <= IF_instr[6:0];
          ID_funct3    <= IF_instr[14:12];
          Indice_R1  <= IF_instr[19:15];
          Indice_R2  <= IF_instr[24:20];
          ID_imm       <= {{19{IF_instr[31]}}, IF_instr[31], IF_instr[7], IF_instr[30:25], IF_instr[11:8], 1'b0};
          ID_regwrite  <= 0;
        end

        // J-Type: JAL
        7'b1101111: begin
          ID_opcode    <= IF_instr[6:0];
          ID_rd        <= IF_instr[11:7];
          ID_imm       <= {{11{IF_instr[31]}}, IF_instr[31], IF_instr[19:12], IF_instr[20], IF_instr[30:21], 1'b0};
          ID_regwrite  <= 1;
          flag_jump    <= 1;
        end

        // U-Type: AUIPC
        7'b0010111: begin
          ID_opcode   <= IF_instr[6:0];
          ID_rd       <= IF_instr[11:7];
          imm_sext    <= {IF_instr[31:12], 12'b0};
          imm_shift   <= {IF_instr[31:12], 12'b0};
          ID_PC       <= IF_PC;
          ID_regwrite <= 1;
        end

        default: begin
          ID_opcode   <= 7'b0;
          ID_regwrite <= 0;
        end
      endcase
    end
  end

endmodule
