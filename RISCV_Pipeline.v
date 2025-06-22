module RISCV_Pipeline (
    input wire clock,
    input wire reset
);

  integer i;

  //===============================
  // Memórias e banco de registradores
  //===============================
  reg [31:0] instr_mem [0:255];    // Memoria de instruçoes
  reg signed [31:0] data_mem  [0:255];   // Memoria de dados
  reg signed [31:0] banco_regs [0:31];   // 32 registradores

  //======================
  // Registradores do Pipeline
  //======================

  // IF
  reg [31:0] IF_instr, IF_PC;

  // ID
  reg [31:0] ID_instr, ID_PC, ID_r1, ID_r2;
  reg [4:0]  ID_indiceR1, ID_indiceR2, ID_rd, ID_shamt;
  reg signed [31:0] ID_imm;
  reg [6:0]  ID_opcode, ID_funct7;
  reg [2:0]  ID_funct3;
  reg ID_regwrite;
  reg ID_MemRead;
  reg ID_MemWrite;
  reg flag_jump;

  // EX
  reg [31:0] EX_instr, EX_r1, EX_r2, EX_PC;
  reg [4:0]  EX_rd;
  reg [6:0]  EX_opcode, EX_funct7;
  reg signed [31:0] EX_imm,  EX_alu_result;
  reg [2:0]  EX_funct3;
  reg EX_regwrite;
  reg EX_MemRead;
  reg EX_MemWrite;

  // MEM
  reg [31:0] MEM_instr,  MEM_r1, MEM_PC;
  reg [4:0]  MEM_rd;
  reg [6:0]  MEM_opcode;
  reg signed [31:0] MEM_alu_result, MEM_data;
  reg MEM_regwrite;
  reg MEM_MemRead;
  reg MEM_MemWrite;

  reg [31:0] WB_instr;
  reg signed [31:0] WB_data;
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
  reg  signed [31:0] alu_result;
  reg [31:0]  branch_target;
  reg         branch_taken;
  reg         bge_taken, blt_taken, bne_taken, beq_taken;

  //=======================
  // Cache de Instruções (direta, 4 linhas)
  //=======================
  reg [31:0] instr_cache_data [0:3];  // Dados da cache
  reg [27:0] instr_cache_tag  [0:3];  // Tags da cache (enderea§os sem offset)
  reg        instr_cache_valid[0:3];  // Bits de validade da cache

  wire [1:0] cache_index = PC[3:2];   // Indexa 4 linhas (usando bits 3:2)
  wire [27:0] cache_tag   = PC[31:4]; // Tag (sem os 4 bits menos significativos)

    //=======================
  // Cache de Dados (direta, 4 linhas)
  //=======================
  reg [31:0] data_cache_data [0:3];  // Dados da cache (16 bits)
  reg [27:0] data_cache_tag  [0:3];  // Tags da cache
  reg        data_cache_valid[0:3];  // Bits de validade da cache

  wire [1:0]  data_cache_index = MEM_alu_result[3:2];   // Indexa 4 linhas
  wire [27:0] data_cache_tag_addr = MEM_alu_result[31:4]; // Tag


  //caminho bypass acesso a memoria
  wire [31:0] mem_read_data_out;
  assign mem_read_data_out = (data_cache_valid[data_cache_index] && 
                            data_cache_tag[data_cache_index] == data_cache_tag_addr) 
                           ? data_cache_data[data_cache_index]  // Cache Hit
                           : data_mem[EX_alu_result >> 2];        // Cache Miss

  wire [31:0] data_to_forward_from_mem = MEM_MemRead ? mem_read_data_out : MEM_alu_result;

  //para nao conflitar com os stalls, guardo a instrucao da etapa ID mais recente


  //=======================
  // Forwarding Logic
  //=======================
    // Forwarding do dado para um Store (WB -> EX)
  wire fwd_sw = EX_MemWrite && (MEM_rd == EX_instr[24:20]) && MEM_regwrite && (MEM_rd != 0);
    
    // Forwarding do dado de um Store (WB -> EX)
  wire fwd_WB_to_EX_for_StoreData = (IF_instr[6:0] == 7'b0100011) && (MEM_rd == IF_instr[24:20]) && MEM_regwrite && (MEM_rd != 0);
    // Forwarding para Loads antecessor de instrucao com dependencia do dado
  wire fwdLW_r1 = EX_regwrite && (EX_rd == ID_indiceR1) && (EX_rd != 0);
  wire fwdLW_r2 = EX_regwrite && (EX_rd == ID_indiceR2) && (EX_rd != 0);

    //Loads nao podem entrar pois calculam endereço na ula, e nao resultado do reg_destino
  wire fwdEX_r1 = EX_regwrite && !EX_MemRead && (EX_rd == ID_indiceR1) && (EX_rd != 0);
  wire fwdEX_r2 = EX_regwrite && !EX_MemRead && (EX_rd == ID_indiceR2) && (EX_rd != 0);

  wire fwdMEM_r1 = MEM_regwrite && (MEM_rd == ID_indiceR1) && (MEM_rd != 0);
  wire fwdMEM_r2 = MEM_regwrite && (MEM_rd == ID_indiceR2) && (MEM_rd != 0);

  wire fwdWB_r1 = WB_regwrite  && (WB_rd == ID_indiceR1) && (WB_rd != 0);
  wire fwdWB_r2 = WB_regwrite  && (WB_rd == ID_indiceR2) && (WB_rd != 0);

    //Se umma instrucao precisa do dado de um load que esta ainda na etapa EX 
    //cria um stall ate ele receber o resultado da memoria no proximo clock
  wire stall =  EX_MemRead && (fwdLW_r1 || fwdLW_r2);

  //=======================
  // Seleçao de operandos para ULA (ALU Mux)
  //=======================
  wire signed [31:0] alu_in1 = fwdEX_r1 ? EX_alu_result         :
                          fwdMEM_r1 ? data_to_forward_from_mem  :
                          fwdWB_r1  ? WB_data                   :
                          ID_r1;

  wire signed [31:0] alu_in2 = (ID_opcode == 7'b0010011 || ID_opcode == 7'b0000011 || ID_opcode == 7'b0100011) ?
                          ID_imm                               :
                          fwdEX_r2  ? EX_alu_result            :
                          fwdMEM_r2 ? data_to_forward_from_mem :
                          fwdWB_r2  ?  WB_data                 :
                          ID_r2;

  wire signed [31:0] data_to_SW;

  assign data_to_SW = fwd_WB_to_EX_for_StoreData ?  MEM_data   :                    
                      banco_regs[IF_instr[24:20]];


  //=======================
  // Atualizaçao do PC
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      PC               <= 0;
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
      if (branch_taken == 1) begin //BGE/BLT
          PC <= branch_target;
      end

      else if(flag_jump == 1) begin //JAL | JALR
        case(ID_opcode)
          7'b1100111:begin //JALR
            PC <= ID_r1 + ID_imm;
          end
          7'b1101111: begin//JAL
            PC <= ID_PC + ID_imm;
          end
        endcase
      end

      else if(stall)
          PC <= PC;

      else
          PC <= PC + 4;
    end  
  end

  //=======================
  // Estagio IF: Busca de instruçao
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset || branch_taken || flag_jump) begin
      IF_instr <= 0;
      IF_PC    <= 0;
    end else begin
      if(stall)begin
        IF_instr <= IF_instr;
        IF_PC <= IF_PC;
      end
      else begin
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
  end

  //=======================
  // Estagio ID: Decodificaçao
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset || branch_taken || flag_jump) begin
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
      flag_jump    <= 0;
      ID_MemRead  <= 0;
      ID_MemWrite <= 0;
      ID_shamt    <= 0;
    end else begin
      if(stall)begin
        ID_instr <= ID_instr;
        ID_PC    <= ID_PC;
        flag_jump <= flag_jump;
        ID_r1     <= banco_regs[ID_indiceR1];
        if(ID_MemWrite) //se for sw copio o valor novamente 
          ID_r2     <= ID_r2;
        else //se for branch ou tipo R, acesso o valor no banco de registradores novamente
          ID_r2     <= banco_regs[ID_indiceR2];
        ID_rd     <= ID_rd;
        ID_imm    <= ID_imm;
        ID_opcode <= ID_opcode;
        ID_funct3 <= ID_funct3;
        ID_funct7 <= ID_funct7;
        ID_indiceR1 <= ID_indiceR1;
        ID_indiceR2 <= ID_indiceR2;
        ID_MemRead  <= ID_MemRead;
        ID_MemWrite <= ID_MemWrite;
        ID_shamt    <= ID_shamt;
      end

      else begin
        ID_instr  <= IF_instr;
        ID_PC     <= IF_PC;

        case (IF_instr[6:0])
          7'b0010011: begin// ADDI e SLRI e SLLI
            ID_opcode   <= IF_instr[6:0];
            ID_funct3   <= IF_instr[14:12];
            ID_rd       <= IF_instr[11:7];
            ID_indiceR1 <= IF_instr[19:15];
            ID_r1       <= banco_regs[IF_instr[19:15]];
            ID_imm      <= {{20{IF_instr[31]}}, IF_instr[31:20]};
            ID_regwrite <= 1;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
            flag_jump <= 0;
            if(IF_instr[14:12] == 101 || IF_instr[14:12] == 001) //se for slri utiliza o shamt
              ID_shamt <= IF_instr[24:20];
          end

          7'b0000011: begin //LW
            ID_opcode   <= IF_instr[6:0];
            ID_funct3   <= IF_instr[14:12];
            ID_rd       <= IF_instr[11:7];
            ID_indiceR1 <= IF_instr[19:15];
            ID_r1       <= banco_regs[IF_instr[19:15]];
            ID_imm      <= {{20{IF_instr[31]}}, IF_instr[31:20]};
            ID_regwrite <= 1;
            ID_MemRead  <= 1;
            ID_MemWrite <= 0;
            flag_jump <= 0;
          end

          7'b1100111: begin //JALR
            ID_opcode   <= IF_instr[6:0];
            ID_funct3   <= IF_instr[14:12];
            ID_rd       <= IF_instr[11:7];
            ID_indiceR1 <= IF_instr[19:15];
            ID_r1       <= banco_regs[IF_instr[19:15]];
            ID_imm      <= {{20{IF_instr[31]}}, IF_instr[31:20]};
            if(IF_instr[11:7] != 0) //rd != 0
              ID_regwrite <= 1;
            else
              ID_regwrite <= 0;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
            flag_jump <= 1;
          end
          
          7'b0100011: begin // SW
            ID_opcode   <= IF_instr[6:0];
            ID_funct3   <= IF_instr[14:12];
            ID_indiceR1 <= IF_instr[19:15];
            ID_indiceR2 <= IF_instr[24:20];
            ID_r1       <= banco_regs[IF_instr[19:15]];
            ID_r2       <= data_to_SW;
            ID_imm      <= {{20{IF_instr[31]}}, IF_instr[31:25], IF_instr[11:7]};
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

          7'b1100011: begin // Tipo B
            ID_imm        <= {{20{IF_instr[31]}}, IF_instr[7], IF_instr[30:25], IF_instr[11:8], 1'b0};
            ID_indiceR2   <= IF_instr[24:20];
            ID_indiceR1   <= IF_instr[19:15];
            ID_r1         <= banco_regs[IF_instr[19:15]];
            ID_r2         <= banco_regs[IF_instr[24:20]];
            ID_funct3     <= IF_instr[14:12];
            ID_opcode     <= IF_instr[6:0];
            ID_regwrite   <= 0;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
            flag_jump <= 0;
          end

          7'b1101111: begin // jal
            ID_imm        <= {{12{IF_instr[31]}}, IF_instr[19:12], IF_instr[20], IF_instr[30:21], 1'b0};
            ID_rd         <= IF_instr[11:7];
            ID_opcode     <= IF_instr[6:0];
            if(IF_instr[11:7] != 0) //rd != 0
              ID_regwrite <= 1;
            else
              ID_regwrite <= 0;
            flag_jump     <= 1;
            ID_MemRead  <= 0;
            ID_MemWrite <= 0;
          end

          7'b0010111, //TIPO U  - AUIPC
          7'b0110111: begin // LUI
            ID_imm        <= {IF_instr[31:12], 12'b0};
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
      EX_alu_result <= EX_alu_result;
      EX_r1       <= 0;
      EX_r2       <= 0;
      EX_imm      <= 0;
      EX_MemWrite  <= 0;
      EX_MemRead   <= 0;
      EX_funct3   <= 0;
      EX_funct7   <= 0;
      EX_PC       <= 0;
    end else begin
      EX_instr      <= ID_instr;
      EX_rd         <= ID_rd;
      EX_opcode     <= ID_opcode;
      EX_imm        <= ID_imm;
      EX_r1         <= ID_r1;
      EX_r2         <= ID_r2;
      EX_PC         <= EX_PC;
      EX_funct7     <= ID_funct7;
      EX_funct3     <= ID_funct3;
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

    if(!stall)begin
      case (ID_opcode)
        7'b0110011: begin // R-Type
          case (ID_funct7)
            7'b0000000: alu_result = alu_in1 + alu_in2;
            7'b0000001: alu_result = alu_in1 * alu_in2;
            7'b0100000: alu_result = alu_in1 - alu_in2;
          endcase
        end

        7'b0010011:begin  // ADDI e SRLI e SLLI
          case(ID_funct3)
            3'b101:
              alu_result = alu_in1 >> ID_shamt; //srli
            3'b001:
              alu_result = alu_in1 << ID_shamt; //slli
            3'b000:
              alu_result = alu_in1 + ID_imm;
          endcase
        end
        
        7'b0000011,  // LW
        7'b0100011:  // SW
          alu_result = alu_in1 + ID_imm;

        7'b0010111: // AUIPC
          alu_result = ID_imm + ID_PC;
        7'b0110111: //LUI
          alu_result = ID_imm;

        7'b1101111,  //JAL
        7'b1100111:  //JALR
          alu_result = ID_PC + 4;

        7'b1100011: begin // Branch
          bne_taken     = (ID_funct3 == 3'b001) && (alu_in1 != alu_in2);
          bge_taken     = (ID_funct3 == 3'b101) && (alu_in1 >= alu_in2);
          blt_taken     = (ID_funct3 == 3'b100) && (alu_in1 <  alu_in2);
          beq_taken     = (ID_funct3 == 3'b000) && (alu_in1 == alu_in2);
          branch_taken  = bge_taken || blt_taken || bne_taken || beq_taken;
          branch_target = ID_PC + ID_imm;
        end

        default: begin
          alu_result    = 0;
          branch_taken  = 0;
          branch_target = 0;
        end
      endcase
    end
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
      MEM_alu_result <= 0;
      MEM_PC          <= 0;
      MEM_r1        <= 0;
    end else begin
      MEM_instr      <= EX_instr;
      MEM_rd         <= EX_rd;
      MEM_opcode     <= EX_opcode;
      MEM_regwrite   <= EX_regwrite;
      MEM_MemRead    <= EX_MemRead;
      MEM_MemWrite   <= EX_MemWrite;
      MEM_alu_result <= EX_alu_result;
      MEM_r1         <= EX_r1;
      MEM_PC         <= EX_PC;
      if(EX_MemRead)begin //LW
        MEM_data <= mem_read_data_out;
      end
      else if(EX_MemWrite) begin //SW
          if(fwd_sw)
            data_mem[EX_alu_result >> 2] <= MEM_alu_result; //pega o resultado da instruçao anterior
          else
            data_mem[EX_alu_result >> 2] <= EX_r2;
          // Invalida a linha da cache correspondente (write-through + no write-allocate)
          data_cache_valid[data_cache_index] <= 0;
      end
      else
        MEM_data <= EX_alu_result; // Para outras instruções
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
      end
    end
  end


endmodule
