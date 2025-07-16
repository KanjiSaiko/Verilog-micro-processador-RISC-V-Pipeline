module RISCV_Pipeline (
    input wire clock,
    input wire reset,

    output wire [31:0] result_out,
    output wire [4:0]  reg_addr_out,
    output wire        write_enable_out
);

  integer i;

  //===============================
  // Memórias e banco de registradores
  //===============================
  reg [31:0] memoria_instrucoes [0:1023];
  reg signed [31:0] memoria_dados [0:1023];
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
    // Campos da Instruçao e Sinais de Controle de Múltiplos Bits
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

  wire stall_cache_instrucoes, stall_cache_dados;

  //=======================
  // Atualizaçao do PC
  //=======================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      PC <= 0;
    end else begin
      PC <= (BranchOutCome) ? branch_target           : 
            (stall || stall_cache_instrucoes || stall_cache_dados)  ?  PC  :
             PC_4;
    end  
  end

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
    if(reset)begin
      IFID_instr <= 0;
      IFID_PC    <= 0;
      IFID_PC4   <= 0;
    end else begin
      if (stall || stall_cache_dados) begin
        IFID_instr    <= IFID_instr;
        IFID_PC       <= IFID_PC;
        IFID_PC4      <= IFID_PC4;
      end
      else if (BranchOutCome || stall_cache_instrucoes) begin
        IFID_instr <= 0;
        IFID_PC    <= 0;
        IFID_PC4   <= 0;
      end else begin
        IFID_instr    <= instrucao_do_processador;
        IFID_PC       <= PC;
        IFID_PC4      <= PC + 4;
      end
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
    AluSrcA       = 0; // Padrao: usa rs1 || Se for 1 -> Utiliza PC
    AluSrcB       = 0; // Padrao: usa rs2 || Se for 1 -> Utiliza IMM

    case (IFID_instr[6:0])
      7'b0010011: begin// ADDI e SLRI e SLLI
        RegWrite      = 1;
        AluControl    = 4'b0001; //ADD
        AluSrcB       = 1;
        Imediato      = {{20{IFID_instr[31]}}, IFID_instr[31:20]};
        case(IFID_instr[14:12])
          3'b101: AluControl = 4'b0011; //SRLI
          3'b010: AluControl = 4'b0101; // SLTI
          3'b011: AluControl = 4'b0110; // SLTIU 
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
              3'b010: AluControl = 4'b0101; // SLT 
              3'b011: AluControl = 4'b0110; // SLTU
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
        AluControl    = 4'b0010; //SUB 
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
    if(reset)begin
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
    end else begin
      if (BranchOutCome || stall) begin
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
      end else if(stall_cache_dados) begin
        IDEX_instr      <= IDEX_instr;
        IDEX_PC         <= IDEX_PC;
        IDEX_AluControl <= IDEX_AluControl;
        IDEX_AluSrcA    <= IDEX_AluSrcA;
        IDEX_AluSrcB    <= IDEX_AluSrcB;
        IDEX_BranchVal  <= IDEX_BranchVal;
        IDEX_BranchJal  <= IDEX_BranchJal;
        IDEX_BranchJalr <= IDEX_BranchJalr;
        IDEX_BranchBxx  <= IDEX_BranchBxx;
        IDEX_BranchOnSign <= IDEX_BranchOnSign;
        IDEX_RegWrite   <= IDEX_RegWrite;
        IDEX_MemRead    <= IDEX_MemRead;
        IDEX_MemWrite   <= IDEX_MemWrite;
        IDEX_MemToReg   <= IDEX_MemToReg;
        IDEX_r1         <= IDEX_r1;
        IDEX_r2         <= IDEX_r2;
        IDEX_rd         <= IDEX_rd;
        IDEX_indiceR1   <= IDEX_indiceR1;
        IDEX_indiceR2   <= IDEX_indiceR2;
        IDEX_shamt      <= IDEX_shamt;
        IDEX_funct3     <= IDEX_funct3;
        IDEX_funct7     <= IDEX_funct7;
        IDEX_imm        <= IDEX_imm;
        IDEX_PC4        <= IDEX_PC4;
      end else begin
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
  end

  //=======================
  // Forwarding Logic
  //=======================
      //Loads nao podem entrar pois sequer pegaram valor na memoria, e resultado da ula é endereço e nao valor do registrador
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
    if(reset)begin
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
      if (BranchOutCome) begin
      // Atribuições para limpar/anular a instruçao no estágio EX/MEM
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
      end else if(stall_cache_dados) begin
        EXMEM_instr          <= EXMEM_instr;
        EXMEM_regwrite       <= EXMEM_regwrite;
        EXMEM_MemRead        <= EXMEM_MemRead;
        EXMEM_MemWrite       <= EXMEM_MemWrite;
        EXMEM_MemToReg       <= EXMEM_MemToReg;
        EXMEM_BranchVal      <= EXMEM_BranchVal;
        EXMEM_BranchJal      <= EXMEM_BranchJal;
        EXMEM_BranchJalr     <= EXMEM_BranchJalr;
        EXMEM_BranchBxx      <= EXMEM_BranchBxx;
        EXMEM_BranchOnSign   <= EXMEM_BranchOnSign;
        EXMEM_flagZero       <= EXMEM_flagZero;
        EXMEM_flagNegative   <= EXMEM_flagNegative;
        EXMEM_WriteData      <= EXMEM_WriteData;
        EXMEM_rd             <= EXMEM_rd;
        EXMEM_Somatorio_PCeIMM <= EXMEM_Somatorio_PCeIMM;
        EXMEM_PC4            <= EXMEM_PC4;
        EXMEM_AluOut         <= EXMEM_AluOut;
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
  // Cache de Dados
  //====================
  wire [31:0] dado_lido_da_cache;

  cache_dados u_cacheDados (
    .clock(clock),
    .reset(reset),
    .MemRead(EXMEM_MemRead), // Controlado pelo estágio EX/MEM
    .endereco(EXMEM_AluOut), // Endereço calculado pela ULA
    .dado_lido(dado_lido_da_cache), // Saída para o pipeline
    .stall_cache_dados(stall_cache_dados) // Saída de stall para o controle
  );

  wire [31:0] dado_lido = dado_lido_da_cache;
  //====================
  // Estagio MEM/WB
  //====================
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      MEMWB_instr    <= 32'b0;
      MEMWB_regwrite <= 1'b0;
      MEMWB_Data     <= 32'b0;
      MEMWB_DadoMUX  <= 32'b0;
      MEMWB_rd       <= 5'b0;
      MEMWB_MemToReg <= 1'b0;
    end else begin
      if (stall_cache_dados) begin
        MEMWB_instr    <= 32'b0;
        MEMWB_regwrite <= 1'b0;
        MEMWB_Data     <= 32'b0;
        MEMWB_DadoMUX  <= 32'b0;
        MEMWB_rd       <= 5'b0;
        MEMWB_MemToReg <= 1'b0;
      end else begin
        MEMWB_instr      <= EXMEM_instr;
        MEMWB_regwrite   <= EXMEM_regwrite;
        MEMWB_Dado       <= Dado_MUX;
        MEMWB_Dado_Lido  <= dado_lido;
        MEMWB_rd         <= EXMEM_rd;
        MEMWB_MemToReg   <= EXMEM_MemToReg;
      end
    end
  end

  assign RegWriteData = MEMWB_MemToReg ? MEMWB_Dado_Lido : //se for LW, pego o dado lido da memoria
                    MEMWB_Dado; //Pego resultado de operações
  
  //====================
  // Write Back
  //====================
  always @(*) begin
    if(reset) for (i = 0; i < 32; i = i + 1) banco_regs[i] <= 0;
    else begin
      if (MEMWB_regwrite && MEMWB_rd != 0) begin
        banco_regs[MEMWB_rd] <= RegWriteData;
      end
    end
  end


assign result_out       = RegWriteData;
assign reg_addr_out     = MEMWB_rd;
assign write_enable_out = MEMWB_regwrite;

endmodule
