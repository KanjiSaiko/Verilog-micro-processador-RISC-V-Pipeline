module RISCV_Pipeline (
    input wire clock,
    input wire reset
);

  integer i;

  //===============================
  // Memórias e banco de registradores
  //===============================
  reg [31:0] instr_mem [0:255];    // Memoria de instruçoes
  reg [31:0] data_mem  [0:255];   // Memoria de dados
  reg [31:0] banco_regs [0:31];   // 32 registradores
  reg [31:0] register_address;    // Para armazenar endereço de retorno (x1)

  //======================
  // Registradores do Pipeline
  //======================

  // IF
  reg [31:0] IF_instr, IF_PC;

  // ID
  reg [31:0] ID_instr, ID_PC, ID_r1, ID_r2;
  reg [4:0]  ID_indiceR1, ID_indiceR2, ID_rd;
  reg [19:0] ID_imm;
  reg [6:0]  ID_opcode, ID_funct7;
  reg [2:0]  ID_funct3;
  reg [31:0] link;
  reg ID_regwrite;
  reg ID_MemRead;
  reg ID_MemWrite;
  reg flag_jump;

  // EX
  reg [31:0] EX_instr, EX_alu_result, EX_r1, EX_r2;
  reg [4:0]  EX_rd;
  reg [6:0]  EX_opcode;
  reg [19:0] EX_imm;
  reg [31:0] imm_sext, imm_shift, AUIPC_result;
  reg EX_regwrite;
  reg EX_MemRead;
  reg EX_MemWrite;

  // MEM
  reg [31:0] MEM_instr, MEM_data;
  reg [4:0]  MEM_rd;
  reg [6:0]  MEM_opcode;
  reg MEM_regwrite;
  reg MEM_MemRead;
  reg MEM_MemWrite;

  reg [31:0] WB_instr;
  reg [31:0] WB_data;
  reg [4:0]  WB_rd;
  reg WB_regwrite; 
  reg WB_MemRead;
  reg WB_MemWrite;

  //=======================
  // Contador de Programa
  //=======================
  reg [31:0] PC;

  //=======================
  // Sinais Intermediarios
  //=======================
  reg  [31:0] alu_result, branch_target;
  reg         branch_taken;
  reg         bge_taken, blt_taken;

  //=======================
  // Cache de Instruções (direta, 4 linhas)
  //=======================
  reg [31:0] instr_cache_data [0:3];  // Dados da cache
  reg [27:0] instr_cache_tag  [0:3];  // Tags da cache (endereÃ§os sem offset)
  reg        instr_cache_valid[0:3];  // Bits de validade da cache

  wire [1:0] cache_index = PC[3:2];   // Indexa 4 linhas (usando bits 3:2)
  wire [27:0] cache_tag   = PC[31:4]; // Tag (sem os 4 bits menos significativos)

    //=======================
  // Cache de Dados (direta, 4 linhas)
  //=======================
  reg [31:0] data_cache_data [0:3];  // Dados da cache (16 bits)
  reg [27:0] data_cache_tag  [0:3];  // Tags da cache
  reg        data_cache_valid[0:3];  // Bits de validade da cache

  wire [1:0]  data_cache_index = EX_alu_result[3:2];   // Indexa 4 linhas
  wire [27:0] data_cache_tag_addr = EX_alu_result[31:4]; // Tag


  //=======================
  // Forwarding Logic
  //=======================
  wire fwdEX_r1 = EX_regwrite && (EX_rd == ID_indiceR1) && (EX_rd != 0);
  wire fwdEX_r2 = EX_regwrite && (EX_rd == ID_indiceR2) && (EX_rd != 0);

  wire fwdMEM_r1 = MEM_regwrite && (MEM_rd == ID_indiceR1) && (MEM_rd != 0);
  wire fwdMEM_r2 = MEM_regwrite && (MEM_rd == ID_indiceR2) && (MEM_rd != 0);


  wire fwdWB_r1 = WB_regwrite  && (WB_rd == ID_indiceR1) && (WB_rd != 0);
  wire fwdWB_r2 = WB_regwrite  && (WB_rd == ID_indiceR2) && (WB_rd != 0);

  wire stall = EX_MemRead && (fwdEX_r1 || fwdEX_r2);

  //=======================
  // Seleção de operandos para ULA (ALU Mux)
  //=======================
  wire [31:0] alu_in1 = fwdMEM_r1 ? MEM_data :
                        fwdWB_r1 ?  WB_data  :
                        EX_r1;

  wire [31:0] alu_in2 = (ID_opcode == 7'b0010011 || ID_opcode == 7'b0000011 || ID_opcode == 7'b0100011) ?
                          ID_imm :
                        fwdMEM_r2 ? MEM_data :
                        fwdWB_r2 ?  WB_data  :
                        EX_r2;


  //=======================
  // Atualização do PC
  //=======================
always @(posedge clock or posedge reset) begin
    if (reset) begin
      PC               <= 0;
      register_address <= 0;
      link             <= 0;

    end else begin
      if (branch_taken == 1) begin //BGE/BLT
          PC <= branch_target;
      end

      else if(flag_jump == 1) begin //JAL
          PC <= ID_PC + ID_imm;
          link <= PC + 4;
      end

      else if(stall)
          PC <= PC;

      else
          PC <= PC + 4;
    end  
  end

  //=======================
  // Estagio IF: Busca de instrução
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      IF_instr <= 0;
      IF_PC    <= 0;
      for (i = 0; i < 32; i = i + 1) banco_regs[i] = 0;
      // Invalida a cache
      for (i = 0; i < 4; i = i + 1) begin
        instr_cache_valid[i] <= 0;
        instr_cache_tag[i]   <= 0;
        instr_cache_data[i]  <= 0;
      end
      for (i = 0; i < 4; i = i + 1) begin
        data_cache_valid[i] <= 0;
        data_cache_tag[i]   <= 0;
        data_cache_data[i]  <= 0;
      end
    end else begin
      IF_PC <= PC;

      if (instr_cache_valid[cache_index] && instr_cache_tag[cache_index] == cache_tag) begin
        // Cache hit
        IF_instr <= instr_cache_data[cache_index];
      end else begin
        // Cache miss: busca da memoria principal
        IF_instr <= instr_mem[PC >> 2];
        instr_cache_data[cache_index]  <= instr_mem[PC >> 2];
        instr_cache_tag[cache_index]   <= cache_tag;
        instr_cache_valid[cache_index] <= 1;
      end
    end
  end

  //=======================
  // Estagio ID: Decodificação
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset || branch_taken || ID_opcode == 7'b1101111) begin
      ID_instr     <= 0;
      ID_PC        <= 0;
      ID_r1        <= 0;
      ID_r2        <= 0;
      ID_indiceR1  <= 0;
      ID_indiceR2  <= 0;
      ID_imm       <= 0;
      ID_rd        <= 0;
      ID_opcode    <= 0;
      ID_funct3    <= 0;
      ID_funct7    <= 0;
      ID_regwrite  <= 0;
      imm_sext     <= 0;
      imm_shift    <= 0;
      flag_jump    <= 0;
      ID_MemRead  <= 0;
      ID_MemWrite <= 0;
      flag_jump <= 0;
    end else begin
      if(stall)begin
        ID_instr <= ID_instr;
        ID_PC    <= ID_PC;
        flag_jump <= flag_jump;
        ID_r1     <= ID_r1;
        ID_r2     <= ID_r2;
        ID_rd     <= ID_rd;
        ID_imm    <= ID_imm;
        ID_opcode <= ID_opcode;
        ID_funct3 <= ID_funct3;
        ID_funct7 <= ID_funct7;
        ID_indiceR1 <= ID_indiceR1;
        ID_indiceR2 <= ID_indiceR2;
        ID_MemRead  <= ID_MemRead;
        ID_MemWrite <= ID_MemWrite;
        imm_shift   <= imm_shift;
        imm_sext    <= imm_sext;
      end

      else begin
        ID_instr  <= IF_instr;
        ID_PC     <= IF_PC;

        case (IF_instr[6:0])
          7'b0010011: begin// ADDI
            ID_opcode   <= IF_instr[6:0];
            ID_funct3   <= IF_instr[14:12];
            ID_rd       <= IF_instr[11:7];
            ID_indiceR1 <= IF_instr[19:15];
            ID_r1       <= banco_regs[IF_instr[19:15]];
            ID_imm      <= IF_instr[31:20];
            ID_regwrite <= 1;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
            flag_jump <= 0;
          end

          7'b0000011: begin //LW
            ID_opcode   <= IF_instr[6:0];
            ID_funct3   <= IF_instr[14:12];
            ID_rd       <= IF_instr[11:7];
            ID_indiceR1 <= IF_instr[19:15];
            ID_r1       <= banco_regs[IF_instr[19:15]];
            ID_imm      <= IF_instr[31:20];
            ID_regwrite <= 1;
            ID_MemRead  <= 1;
            ID_MemWrite <= 0;
            flag_jump <= 0;
          end

          7'b0100011: begin // SW
            ID_opcode   <= IF_instr[6:0];
            ID_funct3   <= IF_instr[14:12];
            ID_indiceR1 <= IF_instr[19:15];
            ID_indiceR2 <= IF_instr[24:20];
            ID_r1       <= banco_regs[IF_instr[19:15]];
            ID_r2       <= banco_regs[IF_instr[24:20]];
            ID_imm      <= {8'b0, IF_instr[31:25], IF_instr[11:7]};
            ID_regwrite <= 0;
            ID_MemRead  <= 0;
            ID_MemWrite <= 1;
            flag_jump <= 0;
          end

          7'b0110011: begin // R-Type
            ID_opcode   <= IF_instr[6:0];
            ID_funct3   <= IF_instr[14:12];
            ID_funct7   <= IF_instr[31:25];
            ID_rd       <= IF_instr[11:7];
            ID_indiceR1 <= IF_instr[19:15];
            ID_indiceR2 <= IF_instr[24:20];
            ID_r1       <= banco_regs[IF_instr[19:15]];
            ID_r2       <= banco_regs[IF_instr[24:20]];
            ID_regwrite <= 1;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
            flag_jump <= 0;
          end

          7'b1100011: begin // bge e blt
            ID_imm        <= {IF_instr[31:25], IF_instr[11:7]};
            ID_indiceR2   <= IF_instr[24:20];
            ID_indiceR1   <= IF_instr[19:15];
            ID_r2         <= banco_regs[IF_instr[24:20]];
            ID_r1         <= banco_regs[IF_instr[19:15]];
            ID_funct3     <= IF_instr[14:12];
            ID_opcode     <= IF_instr[6:0];
            ID_regwrite   <= 0;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
            flag_jump <= 0;
          end

          7'b1101111: begin // jal
            ID_imm        <= {IF_instr[31], IF_instr[19:12], IF_instr[20], IF_instr[30:21]};
            ID_rd         <= IF_instr[11:7];
            ID_opcode     <= IF_instr[6:0];
            ID_regwrite   <= 1;
            flag_jump     <= 1;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
          end

          7'b0010111: begin // auipc
            imm_sext      <= {IF_instr[31:12], 12'b0};
            imm_shift     <= {IF_instr[31:12], 12'b0};
            ID_PC         <= IF_PC;
            ID_rd         <= IF_instr[11:7];
            ID_opcode     <= IF_instr[6:0];
            ID_regwrite   <= 1;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
            flag_jump <= 0;
          end

          default: begin
            ID_opcode     <= 0;
            ID_regwrite   <= 0;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
            flag_jump <= 0;
          end
        endcase
      end
    end
  end

  //====================
  // Estagio EX
  //====================
   always @(posedge clock or posedge reset) begin
    if (reset || stall) begin
      EX_instr    <= 0;
      EX_rd       <= 0;
      EX_opcode   <= 0;
      EX_regwrite <= 0;
      EX_alu_result <= 0;
      EX_r1       <= 0;
      EX_r2       <= 0;
      EX_imm      <= 0;
      EX_MemWrite  <= 0;
      EX_MemRead   <= 0;
    end else begin
      EX_instr      <= ID_instr;
      EX_rd         <= ID_rd;
      EX_opcode     <= ID_opcode;
      EX_imm        <= ID_imm;
      EX_r1         <= ID_r1;
      EX_r2         <= ID_r2;
      EX_alu_result <= alu_result;
      EX_regwrite   <= ID_regwrite;
      EX_MemRead    <= ID_MemRead;
      EX_MemWrite   <= ID_MemWrite;
    end
  end

  //=======================
  // ULA
  //=======================
  always @(*) begin
    alu_result    = 0;

    case (ID_opcode)
      7'b0110011: begin // R-Type
        case (ID_funct7)
          7'b0000000: alu_result = alu_in1 + alu_in2;
          7'b0000001: alu_result = alu_in1 * alu_in2;
          7'b0100000: alu_result = alu_in1 - alu_in2;
          default:    alu_result = 0;
        endcase
      end

      7'b0010011,  // ADDI
      7'b0000011,  // LW
      7'b0100011:  // SW
        alu_result = alu_in1 + ID_imm;

      7'b0010111: // AUIPC
        alu_result = imm_shift + ID_PC;

      7'b1100011: begin // Branch
        bge_taken     = (ID_funct3 == 3'b101) && (alu_in1 >= alu_in2);
        blt_taken     = (ID_funct3 == 3'b100) && (alu_in1 <  alu_in2);
        branch_taken  = bge_taken || blt_taken;
        branch_target = ID_PC + ID_imm;
      end

      default: begin
        alu_result    = 0;
        branch_taken  = 0;
        branch_target = 0;
      end
    endcase
  end

  //====================
  // Estagio MEM
  //====================
     always @(posedge clock or posedge reset) begin
    if (reset) begin
      MEM_instr   <= 0;
      MEM_data    <= 0;
      MEM_rd      <= 0;
      MEM_opcode  <= 0;
      MEM_regwrite <= 0;
      MEM_MemWrite  <= 0;
      MEM_MemRead   <= 0;
    end else begin
      MEM_instr      <= EX_instr;
      MEM_rd         <= EX_rd;
      MEM_opcode     <= EX_opcode;
      MEM_regwrite   <= EX_regwrite;
      MEM_MemRead    <= EX_MemRead;
      MEM_MemWrite   <= EX_MemWrite;
      if(EX_MemRead)begin //LW
        case (EX_opcode)
          7'b0000011:begin
              // Leitura da cache de dados
              if (data_cache_valid[data_cache_index] && data_cache_tag[data_cache_index] == data_cache_tag_addr) begin
                // Cache hit
                MEM_data <= data_cache_data[data_cache_index];
              end else begin
                // Cache miss: acessa memória principal e atualiza cache
                data_cache_data[data_cache_index]  <= data_mem[EX_alu_result >> 2]; // 16 bits por posição
                data_cache_tag[data_cache_index]   <= data_cache_tag_addr;
                data_cache_valid[data_cache_index] <= 1;
                MEM_data <= data_mem[EX_alu_result >> 2];
              end
          end
        endcase
      end
      else if(EX_MemWrite) begin //SW
        case(EX_opcode)
          7'b0100011:begin
          // Escrita direta na memoria principal
          data_mem[EX_alu_result >> 2] <= EX_r2[15:0];
          // Invalida a linha da cache correspondente (write-through + no write-allocate)
          data_cache_valid[data_cache_index] <= 0;
          end
        endcase
      end
      else
        MEM_data <= EX_alu_result; // Para instruções tipo R, ADDI e AUIPC
    end
  end


  //====================
  // Estagio WB
  //====================
    always @(posedge clock or posedge reset) begin
    if (reset) begin
      WB_instr <= 0;
      WB_rd    <= 0;
      WB_data  <= 0;
      WB_regwrite <= 0;
    end else begin
      WB_instr <= MEM_instr;
      WB_data  <= MEM_data;
      WB_rd    <= MEM_rd;
      WB_regwrite <= MEM_regwrite;
      if (MEM_regwrite && MEM_rd != 0) begin
        banco_regs[MEM_rd] <= MEM_data;
        register_address   <= link;
      end
    end
  end


endmodule
