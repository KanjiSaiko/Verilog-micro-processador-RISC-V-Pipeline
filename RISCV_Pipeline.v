module RISCV_Pipeline (
    input wire clock,
    input wire reset
);

  integer i;

  //===============================
  // Memórias e banco de registradores
  //===============================
  reg signed [31:0] memoria_dados  [0:1023];   // Memoria de dados de 1kb
  reg signed [31:0] banco_regs [0:31];   // 32 registradores

  //======================
  // Registradores do Pipeline
  //======================


// --- Contador de Programa ---
    reg [31:0] PC;
    wire [31:0] PC_4; 

// --- Estágio IF/ID ---
  reg [31:0] IFID_instr, IFID_PC, IFID_PC4;

// --- Estágio ID/EX ---

  // Sinais de 32 bits (Dados, Endereços, Imediatos)
  reg [31:0] IDEX_instr, IDEX_PC, IDEX_PC4;
  reg signed [31:0] IDEX_imm, IDEX_r1, IDEX_r2;
  // Sinais de Controle e Flags (1 bit cada)
  reg IDEX_RegWrite, IDEX_MemRead, IDEX_MemWrite, IDEX_BranchBxx, IDEX_BranchJal, IDEX_MemToReg;
  reg IDEX_BranchJalr, IDEX_BranchOnSign, IDEX_AluSrcA, IDEX_AluSrcB, IDEX_BranchVal;
  // Campos da Instrução e Sinais de Controle de Múltiplos Bits
  reg [6:0]  IDEX_funct7;
  reg [4:0]  IDEX_rd, IDEX_indiceR1, IDEX_indiceR2, IDEX_shamt;
  reg [3:0]  IDEX_AluControl;
  reg [2:0]  IDEX_funct3;

// --- Estágio EX/MEM ---

  // Sinais de Dados e Endereços (32 bits)
  reg [31:0] EXMEM_instr, EXMEM_Somatorio_PCeIMM, EXMEM_PC4;
  reg signed [31:0] EXMEM_AluOut, EXMEM_WriteData;
  // Endereço do Registrador de Destino (5 bits)
  reg [4:0]  EXMEM_rd;
  // Sinais de Controle e Flags (1 bit cada)
  reg EXMEM_regwrite, EXMEM_MemRead, EXMEM_MemWrite, EXMEM_BranchVal, EXMEM_BranchJal, EXMEM_MemToReg;
  reg EXMEM_BranchJalr, EXMEM_BranchBxx, EXMEM_BranchOnSign, EXMEM_flagZero, EXMEM_flagNegative;

// --- Estágio MEM/WB ---

  // Sinais de Dados (32 bits)
  reg [31:0] MEMWB_instr, MEMWB_Data, MEMWB_DadoMUX, MEMWB_Dado, MEMWB_Dado_Lido;
  // Endereço do Registrador de Destino (5 bits)
  reg [4:0]  MEMWB_rd;
  // Sinais de Controle (1 bit cada)
  reg        MEMWB_regwrite, MEMWB_MemToReg;

    
//Se umma instrucao precisa do dado de um load que esta ainda na etapa EX/MEM 
//cria um stall ate ele receber o resultado da memoria no proximo clock
  wire stall;
  
  wire [31:0] branch_target;
  wire BranchOutCome;
  wire [31:0] Dado_MUX, RegWriteData;

  wire stall_cache_instrucoes;
  //=======================
  // Atualizaçao do PC
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      PC <= 0;
      for (i = 0; i < 32; i = i + 1) banco_regs[i] = 0;
    end else begin
      PC <= (BranchOutCome) ? branch_target           : 
            (stall || stall_cache_instrucoes)  ?  PC  :
             PC_4;
    end  
  end
  //acesso memoria de instrucoes
  assign PC_4 = PC + 4;

  wire [31:0] instrucao_do_processador;
  //=======================
  // Cache de Instruções (direta, 4 linhas)
  //=======================
  cache_instrucoes u_cacheInst (
      .clock(clock),
      .reset(reset),
      .PC(PC),
      .stall_cache_instrucoes(stall_cache_instrucoes),
      .instrucao_do_processador(instrucao_do_processador)
  );


  //=======================
  // Estagio IF/ID
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset || BranchOutCome || stall_cache_instrucoes) begin
      IFID_instr <= 0;
      IFID_PC    <= 0;
      IFID_PC4   <= 0;
    end else if (stall) begin
      IFID_instr    <= IFID_instr;
      IFID_PC       <= IFID_PC;
      IFID_PC4      <= IFID_PC4;
    end
    else begin
      IFID_instr    <= instrucao_do_processador;
      IFID_PC       <= PC;
      IFID_PC4      <= PC + 4;
      end
  end

  //Sinais
  reg [3:0] AluControl;
  reg [31:0] Imediato;
  reg MemRead, MemWrite, RegWrite, MemToReg, AluSrcA, AluSrcB;
  reg BranchJal, BranchJalr, BranchBxx, BranchOnSign, BranchVal;

    
  //====================
  // Controller
  //====================
  always @(*) begin
    AluControl    = 4'bx;
    BranchJal     = 0;
    BranchJalr    = 0;
    BranchBxx     = 0;
    MemRead       = 0;
    MemWrite      = 0;
    RegWrite      = 0;
    MemToReg      = 0;
    Imediato      = 0;
    BranchOnSign  = 0; //0 para flag zero || 1 para flag negative
    BranchVal     = 0;
    AluSrcA       = 0; // Padrão: usa rs1 || Se for 1 -> Utiliza PC
    AluSrcB       = 0; // Padrão: usa rs2 || Se for 1 -> Utiliza IMM

    case (IFID_instr[6:0])
      7'b0010011: begin// ADDI e SLRI e SLLI
        RegWrite      = 1;
        AluControl    = 4'b0001; //ADD
        AluSrcB       = 1;
        Imediato      = {{20{IFID_instr[31]}}, IFID_instr[31:20]};
        case(IFID_instr[14:12])
          3'b101: AluControl = 4'b0011; //SRLI
          3'b010: AluControl = 4'b0101; // SLTI <-- ADICIONADO
          3'b011: AluControl = 4'b0110; // SLTIU <-- ADICIONADO
          3'b001: AluControl = 4'b0100; //SLLI
        endcase
          
      end

      7'b0000011: begin //LW
        RegWrite      = 1;
        MemRead       = 1;
        AluSrcB       = 1;
        MemToReg      = 1;
        AluControl    = 4'b0001;
        Imediato      = {{20{IFID_instr[31]}}, IFID_instr[31:20]};
      end

      7'b1100111: begin //JALR
        RegWrite = (IFID_instr[11:7] != 5'b0);
        BranchJalr    = 1;
        AluSrcB       = 1;
        AluControl    = 4'b0001;
        Imediato      = {{20{IFID_instr[31]}}, IFID_instr[31:20]};
      end
      
      7'b0100011: begin // SW
        MemWrite        = 1;
        AluSrcB         = 1;
        AluControl      = 4'b0001;
        Imediato        = {{20{IFID_instr[31]}}, IFID_instr[31:25], IFID_instr[11:7]};
      end

      7'b0110011: begin // R-Type
        RegWrite        = 1;
        AluControl      = 4'b0001; //ADD
        case(IFID_instr[31:25])
          7'b0000000:begin // funct7 para MUL/DIV/etc.
            case(IFID_instr[14:12]) // Checa o funct3
              3'b000: AluControl = 4'b0001; // ADD
              3'b010: AluControl = 4'b0101; // SLT  <-- NOVO
              3'b011: AluControl = 4'b0110; // SLTU <-- NOVO
              default: AluControl = 4'bx;
            endcase
          end
          7'b0100000:begin // funct7 para SUB
            if(IFID_instr[14:12] == 3'b000) begin 
                AluControl = 4'b0010; // SUB
            end
          end
           7'b0000001:begin 
            if(IFID_instr[14:12] == 3'b000) begin
                AluControl = 4'b1000; // MUL
            end
           end
        endcase
      end

      7'b1100011: begin // Tipo B
        BranchBxx     = 1;
        AluControl    = 4'b0010; //SUB (generico e facil saber quando tomar o desvio)
        Imediato      = {{20{IFID_instr[31]}}, IFID_instr[7], IFID_instr[30:25], IFID_instr[11:8], 1'b0};
        case(IFID_instr[14:12])
          3'b000: BranchVal =  0;//beq
          3'b001: BranchVal =  1;//bne
          3'b100:begin //blt
            BranchOnSign = 1;  // Usa a flag Negative  
            BranchVal    = 0;  // Desviar se (Negative == 1)
          end
          3'b101:begin //bge
            BranchOnSign = 1;  // Usa a flag Negative
            BranchVal    = 1;  // Desviar se (Negative == 0)
          end
        endcase
      end

      7'b1101111: begin // jal
        RegWrite    = (IFID_instr[11:7] != 0);
        AluSrcA     = 1;
        AluSrcB     = 1;
        BranchJal   = 1;
        AluControl  = 4'b0001;
        Imediato    = {{12{IFID_instr[31]}}, IFID_instr[19:12], IFID_instr[20], IFID_instr[30:21], 1'b0};
      end

      7'b0010111: begin// AUIPC
        RegWrite    = 1;
        AluSrcA     = 1;    // Usa PC como primeiro operando
        AluSrcB     = 1;
        AluControl  = 4'b0001;
        Imediato    = {IFID_instr[31:12], 12'b0};
      end

      7'b0110111: begin // LUI
        RegWrite    = 1;
        AluSrcB     = 1;
        AluControl  = 4'b0001; //faz 0 + Imediato
        Imediato    = {IFID_instr[31:12], 12'b0};
      end

      default: begin
      end
    endcase
  end

  //=======================
  // Estagio ID/EX
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset || BranchOutCome || stall) begin
      IDEX_instr        <= 32'b0;
      IDEX_PC           <= 32'b0;
      IDEX_AluControl   <= 4'b0;
      IDEX_AluSrcA      <= 1'b0;
      IDEX_AluSrcB      <= 1'b0;
      IDEX_BranchVal    <= 1'b0;
      IDEX_BranchJal    <= 1'b0;
      IDEX_BranchJalr   <= 1'b0;
      IDEX_BranchBxx    <= 1'b0;
      IDEX_BranchOnSign <= 1'b0;
      IDEX_RegWrite     <= 1'b0;
      IDEX_MemRead      <= 1'b0;
      IDEX_MemWrite     <= 1'b0;
      IDEX_MemToReg     <= 1'b0;
      IDEX_r1           <= 32'b0;
      IDEX_r2           <= 32'b0;
      IDEX_rd           <= 5'b0;
      IDEX_indiceR1     <= 5'b0;
      IDEX_indiceR2     <= 5'b0;
      IDEX_shamt        <= 5'b0;
      IDEX_funct3       <= 3'b0;
      IDEX_funct7       <= 7'b0;
      IDEX_imm          <= 32'b0;
      IDEX_PC4          <= 32'b0;
    end
    else begin
      IDEX_instr        <= IFID_instr;
      IDEX_PC           <= IFID_PC;
      IDEX_AluControl   <= AluControl;
      IDEX_AluSrcA      <= AluSrcA;
      IDEX_AluSrcB      <= AluSrcB;
      IDEX_BranchVal    <= BranchVal;
      IDEX_BranchJal    <= BranchJal;
      IDEX_BranchJalr   <= BranchJalr;
      IDEX_BranchBxx    <= BranchBxx;
      IDEX_BranchOnSign <= BranchOnSign;
      IDEX_RegWrite     <= RegWrite;
      IDEX_MemRead      <= MemRead;
      IDEX_MemWrite     <= MemWrite;
      IDEX_MemToReg     <= MemToReg;
      IDEX_r1           <= banco_regs[IFID_instr[19:15]];
      IDEX_r2           <= banco_regs[IFID_instr[24:20]];
      IDEX_rd           <= IFID_instr[11:7];
      IDEX_indiceR1     <= IFID_instr[19:15];
      IDEX_indiceR2     <= IFID_instr[24:20];
      IDEX_shamt        <= IFID_instr[24:20];
      IDEX_funct3       <= IFID_instr[14:12];
      IDEX_funct7       <= IFID_instr[31:25];
      IDEX_imm          <= Imediato;
      IDEX_PC4          <= IFID_PC4;
    end
  end

  //=======================
  // Forwarding Logic
  //=======================
      //Loads nao podem entrar pois sequer pegaram valor na memoria, e resultado da ula é endereço e não valor do registrador
    wire fwdEXMEM_r1 = EXMEM_regwrite && !EXMEM_MemRead && (EXMEM_rd == IDEX_indiceR1) && (EXMEM_rd != 0);
    wire fwdEXMEM_r2 = EXMEM_regwrite && !EXMEM_MemRead && (EXMEM_rd == IDEX_indiceR2) && (EXMEM_rd != 0);

    wire fwdMEMWB_r1 = MEMWB_regwrite && (MEMWB_rd == IDEX_indiceR1) && (MEMWB_rd != 0);
    wire fwdMEMWB_r2 = MEMWB_regwrite && (MEMWB_rd == IDEX_indiceR2) && (MEMWB_rd != 0);

  //=======================
  // Seleçao de operandos para ULA (ALU Mux)
  //=======================
  wire signed [31:0] alu_in1 = fwdEXMEM_r1     ? EXMEM_AluOut        :
                              fwdMEMWB_r1      ? RegWriteData        :
                              IDEX_r1;

  wire signed [31:0] alu_in2 = fwdEXMEM_r2  ?   EXMEM_AluOut         :
                              fwdMEMWB_r2   ? RegWriteData           :
                              IDEX_r2;

  wire signed [31:0] Operando_1  = IDEX_AluSrcA    ?    IDEX_PC :
                              alu_in1;

  wire signed [31:0] Operando_2  = IDEX_AluSrcB    ?    IDEX_imm :
                              alu_in2;
  
  //=======================
  // ULA
  //=======================
  reg flag_zero, flag_negative;
  reg signed [31:0] alu_result;
  always @(*) begin
    alu_result    = 0;
    flag_zero     = 0;
    flag_negative = 0;
      case (IDEX_AluControl)
        4'b0001:  // SOMA
          alu_result = Operando_1 + Operando_2;
        4'b0010:  // SUB
          alu_result = Operando_1 - Operando_2;
        4'b0011:  // SRLI
          alu_result = Operando_1 >> Operando_2;
        4'b0100:  //SLLI
          alu_result = Operando_1 << Operando_2;
        4'b0101:  // SLT (Set Less Than, com sinal)
          alu_result = (Operando_1 < Operando_2) ? 32'd1 : 32'd0;
        4'b0110:  // SLTU (Set Less Than, sem sinal)
          alu_result = ($unsigned(Operando_1) < $unsigned(Operando_2)) ? 32'd1 : 32'd0;

        4'b1000:  //MUL
          alu_result = Operando_1 * Operando_2;
        default:begin end
      endcase
      if(alu_result == 0)
        flag_zero = 1;
      else if(alu_result < 0) //se flag_negative = 0 entao alu_result > 0, portanto r1 > r2
        flag_negative = 1;
    end

  wire [31:0] Somatorio_PCeIMM = IDEX_imm + IDEX_PC; 

  //====================
  // Estagio EX/MEM
  //====================
   always @(posedge clock or posedge reset) begin
    if (reset || BranchOutCome) begin
    // Atribuições para limpar/anular a instrução no estágio EX/MEM
      EXMEM_instr          <= 32'b0;
      EXMEM_regwrite       <= 1'b0;
      EXMEM_MemRead        <= 1'b0;
      EXMEM_MemWrite       <= 1'b0;
      EXMEM_MemToReg       <= 1'b0;
      EXMEM_BranchVal      <= 1'b0;
      EXMEM_BranchJal      <= 1'b0;
      EXMEM_BranchJalr     <= 1'b0;
      EXMEM_BranchBxx      <= 1'b0;
      EXMEM_BranchOnSign   <= 1'b0;
      EXMEM_flagZero       <= 1'b0;
      EXMEM_flagNegative   <= 1'b0;
      EXMEM_WriteData      <= 32'b0;
      EXMEM_rd             <= 5'b0;
      EXMEM_Somatorio_PCeIMM <= 32'b0;
      EXMEM_PC4            <= 32'b0;
      EXMEM_AluOut         <= 32'b0;
    end else begin
      EXMEM_instr      <= IDEX_instr;
      EXMEM_regwrite   <= IDEX_RegWrite;
      EXMEM_MemRead    <= IDEX_MemRead;
      EXMEM_MemWrite   <= IDEX_MemWrite;
      EXMEM_MemToReg    <= IDEX_MemToReg;
      EXMEM_BranchVal   <= IDEX_BranchVal;
      EXMEM_BranchJal  <= IDEX_BranchJal;
      EXMEM_BranchJalr <= IDEX_BranchJalr;
      EXMEM_BranchBxx  <= IDEX_BranchBxx;
      EXMEM_BranchOnSign <= IDEX_BranchOnSign;
      EXMEM_flagZero   <= flag_zero;
      EXMEM_flagNegative   <= flag_negative;
      EXMEM_WriteData  <= alu_in2;
      EXMEM_rd                <= IDEX_rd;
      EXMEM_Somatorio_PCeIMM  <= Somatorio_PCeIMM;
      EXMEM_PC4               <= IDEX_PC4;
      EXMEM_AluOut            <= alu_result;
    end
  end

  assign stall =  IDEX_MemRead && (IDEX_rd == IFID_instr[19:15] || IDEX_rd == IFID_instr[24:20]) && IDEX_rd != 0;

  wire Zero_Or_Negative = EXMEM_BranchOnSign ? EXMEM_flagNegative  :  EXMEM_flagZero;
  wire XOR           = (Zero_Or_Negative ^ EXMEM_BranchVal); 
  wire AND_Branch    = (EXMEM_BranchBxx && XOR); //and
  wire BranchJalx    = (EXMEM_BranchJal || EXMEM_BranchJalr); //or

  assign BranchOutCome = (AND_Branch || BranchJalx);

  assign branch_target = EXMEM_BranchJalr ? EXMEM_AluOut   :
                              EXMEM_Somatorio_PCeIMM;
  


  assign Dado_MUX =  BranchJalx  ?  EXMEM_PC4  :
                          EXMEM_AluOut;
                          
  //====================
  // Cache de Dados (direta, 4 linhas) Leitura Combinacional e Escrita Sequencial
  //====================
    reg [31:0] data_cache_data [0:3];  // Dados da cache (16 bits)
    reg [27:0] data_cache_tag  [0:3];  // Tags da cache
    reg        data_cache_valid[0:3];  // Bits de validade da cache

    wire [1:0]  data_cache_index = EXMEM_AluOut[3:2];   // Indexa 4 linhas
    wire [27:0] data_cache_tag_addr = EXMEM_AluOut[31:4]; // Tag

  assign cache_data_hit = data_cache_valid[data_cache_index] && (data_cache_tag[data_cache_index] == data_cache_tag_addr);
  wire [31:0] dado_lido_da_memoria_principal = memoria_dados[EXMEM_AluOut >> 2];
  wire [31:0] dado_lido = (cache_data_hit) ? data_cache_data[data_cache_index] : dado_lido_da_memoria_principal;
  //====================
  // Estagio MEM/WB
  //====================
     always @(posedge clock or posedge reset) begin
    if (reset) begin
      MEMWB_instr    <= 32'b0;
      MEMWB_regwrite <= 1'b0;
      MEMWB_Data     <= 32'b0;
      MEMWB_DadoMUX  <= 32'b0;
      MEMWB_rd       <= 5'b0;
      MEMWB_MemToReg <= 1'b0;
      for (i = 0; i < 4; i = i + 1) begin
        data_cache_valid[i] <= 0;
        data_cache_tag[i]   <= 0;
        data_cache_data[i]  <= 0;
      end
    end else begin
      MEMWB_instr      <= EXMEM_instr;
      MEMWB_regwrite   <= EXMEM_regwrite;
      MEMWB_Dado       <= Dado_MUX;
      MEMWB_Dado_Lido  <= dado_lido;
      MEMWB_rd         <= EXMEM_rd;
      MEMWB_MemToReg   <= EXMEM_MemToReg;

      if (EXMEM_MemWrite) begin
        memoria_dados[EXMEM_AluOut >> 2] <= EXMEM_WriteData;
        // Política de escrita: Invalida a linha da cache se o endereço bater.
        // Isso é uma estratégia simples (write-through com no-write-allocate e invalidação).
        if (cache_data_hit) begin
            data_cache_valid[data_cache_index] <= 1'b0;
        end
      end
      // Ação 2: Se a instrução for um LW (Load Word) e deu CACHE MISS
      // Política de alocação: Escreve o dado buscado da memória na cache.
      else if (EXMEM_MemRead && !cache_data_hit) begin
        data_cache_valid[data_cache_index] <= 1'b1;
        data_cache_tag[data_cache_index]   <= data_cache_tag_addr;
        data_cache_data[data_cache_index]  <= dado_lido_da_memoria_principal;
      end
    end
  end

  assign RegWriteData = MEMWB_MemToReg ? MEMWB_Dado_Lido : //se for LW, pego o dado lido da memoria
                    MEMWB_Dado; //Pego resultado de operações
  
  //====================
  // Write Back
  //====================
  always @(*) begin
      if (MEMWB_regwrite && MEMWB_rd != 0) begin
        banco_regs[MEMWB_rd] = RegWriteData;
      end
  end

endmodule
