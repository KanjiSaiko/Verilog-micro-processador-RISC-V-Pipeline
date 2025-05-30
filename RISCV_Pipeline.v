module RISCV_Pipeline (
    input wire clock,
    input wire reset
);
  integer i;
  //===============================================
  // Memãria de instruções, dados e registradores
  //===============================================
  reg [31:0] instr_mem [0:21];  // 16 instruções
  reg [15:0] data_mem  [0:255]; // memãria de dados
  reg [31:0] banco_regs   [0:31];  // 32 registradores
  reg [31:0] register_address; //x1 (register_address - return adress)

  //=======================
  // Registradores pipeline
  //=======================
  // IF/ID
  reg [31:0] IF_instr;
  reg [31:0] IF_PC;

  // ID
  reg [31:0] ID_instr;
  reg [4:0] ID_indiceR1, ID_indiceR2;
  reg [31:0] ID_r1, ID_r2;
  reg [19:0] ID_imm;
  reg [19:0] branch_valor;
  reg [31:0] ID_PC;
  reg [4:0]  ID_rd;
  reg [6:0]  ID_opcode;
  reg [2:0]  ID_funct3;
  reg [6:0]  ID_funct7;
  reg [31:0] link;
 
  // EX
  reg [31:0] EX_instr;
  reg [31:0] EX_alu_result, EX_r2;
  reg [4:0]  EX_rd;
  reg [6:0]  EX_opcode;
  reg [19:0] EX_imm;
  //Para instrução AUIPC
  reg [31:0] imm_sext;
  reg [31:0] imm_shift;
  reg [31:0] AUIPC_result;

  // MEM
  reg [31:0] MEM_instr;
  reg [31:0] MEM_data;
  reg [4:0]  MEM_rd;
  reg [6:0]  MEM_opcode;

  //=====================
  // Contador de programa
  //=====================
  reg [31:0] PC;

  // Flags
  reg EX_salto_cond, flag_jump;
  reg ID_regwrite, EX_regwrite, MEM_regwrite;

  // sinais intermediários do EX
  reg  [31:0] alu_result;
  reg         branch_taken;
  reg  [31:0] branch_target;

  // forwarding
  wire fwdEX_r1 = EX_regwrite  && (EX_rd == ID_indiceR1) && (EX_rd != 0);
  wire fwdWB_r1 = MEM_regwrite && (MEM_rd == ID_indiceR1) && !fwdEX_r1 && (MEM_rd != 0);
  wire fwdEX_r2 = EX_regwrite  && (EX_rd == ID_indiceR2) && (EX_rd != 0);
  wire fwdWB_r2 = MEM_regwrite && (MEM_rd == ID_indiceR2) && !fwdEX_r2 && (MEM_rd != 0);

  // mux de operandos
  wire [31:0] alu_in1 = fwdEX_r1 ? EX_alu_result 
                      : fwdWB_r1 ? MEM_data 
                      : ID_r1;
  wire [31:0] alu_in2 = (ID_opcode == 7'b0010011) ? ID_imm        // ADDI
                      : (ID_opcode == 7'b0000011 || ID_opcode == 7'b0100011) ? ID_imm        // LW/SW
                      : fwdEX_r2   ?  EX_alu_result
                      : fwdWB_r2   ?  MEM_data
                      : ID_r2;    // R-type
  // cálculo do branch
  reg bge_taken;
  reg blt_taken;

  //COMBINACIONAL EX (FORWARDING E ULA)
  always @(*) begin
     // default
    alu_result    = 0;
    branch_taken  = 0;
    branch_target = 0;
    // Forwarding
    case(ID_opcode)
      7'b0110011: begin //Tipo R
        case(ID_funct7)
          7'b0000000:
            alu_result = alu_in1 + alu_in2;
          7'b0000001:
            alu_result = alu_in1 * alu_in2;
          7'b0100000:
            alu_result = alu_in1 - alu_in2;
          default: alu_result = 0;
        endcase
      end
       
      7'b0010011,        //addi
      7'b0000011,        //lw
      7'b0100011: begin  // sw
        alu_result = alu_in1 + ID_imm; // endereço ou soma imediata
      end
      7'b0010111: //AUIPC
        alu_result = imm_shift + ID_PC;

      7'b1100011: begin //branch
        bge_taken = (ID_funct3==3'b101) && (alu_in1 >= alu_in2);
        blt_taken = (ID_funct3==3'b100) && (alu_in1< alu_in2);
        branch_taken = bge_taken||blt_taken;
        branch_target = ID_PC + ID_imm;
      end
      
      default: begin
        alu_result    = 0;
        branch_taken  = 0;
        branch_target = 0;
      end
    endcase
  end

  //=====================
  // Inicialização
  //=====================
  initial begin
    PC = 0;

    // 0: addi x1, x0, 10
    instr_mem[0]  = {32'b00000000101000000000000010010011};
    // addi x2, x0, 20
    instr_mem[1]  = {32'b00000001010000000000000100010011};

    // add x3, x1, x2
    instr_mem[2]  = 32'b00000000001000001000000110110011;

    // sub x4, x3, x5
    instr_mem[3]  = {32'b01000000010100011000001000110011};

    // mul x5, x4, x3
    instr_mem[4]  = {32'b00000010001100100000001010110011};

    // add x6, x5, x5
    instr_mem[5]  = {32'b0000000001010010100000110011001};



    // limpa banco de registradores e mem
    for (i = 0; i < 32; i = i + 1) banco_regs[i] = 0;
    for (i = 0; i < 256; i = i + 1) data_mem[i] = 0;
  end

  //====================
  // ATUALIZAÇÃO PC
  //====================
always @(posedge clock or posedge reset) begin
    if (reset) begin
      PC               <= 0;
      register_address <= 0;
      link             <= 0;

    end else begin
      if (EX_salto_cond == 1) begin //BGE/BLT
          PC <= branch_valor;
      end

      else if(flag_jump == 1) begin //JAL
          PC <= ID_PC + ID_imm;
          link <= PC + 4;
      end

      else
        PC <= PC + 4;
    end  
  end

  //====================
  // Estágio IF
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset || EX_salto_cond || EX_opcode == 1101111) begin
      IF_instr <= 0;
      IF_PC <= 0;
    end else begin
      IF_instr <= instr_mem[PC >> 2];
      IF_PC <= PC;
    end
  end

  //====================
  // Estágio ID
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset || EX_salto_cond || EX_opcode == 1101111) begin
      ID_indiceR1       <= 0;
      ID_indiceR2       <= 0;
      ID_imm      <= 0;
      ID_r2       <= 0;
      ID_r1       <= 0;
      ID_rd       <= 0;
      ID_opcode   <= 0;
      ID_funct3   <= 0;
      ID_funct7   <= 0;
      ID_PC       <= 0;
      ID_instr    <= 0;
      ID_regwrite <= 0;
      imm_sext    <= 0;
      imm_shift   <= 0;
      flag_jump   <= 0;
      
    end else begin
      ID_instr <= IF_instr;
      ID_PC    <= IF_PC;
      flag_jump <= 0;
      case(IF_instr[6:0])
        7'b0010011,       //addi
        7'b0000011: begin //lw
          ID_imm <= IF_instr[31:20];
          ID_indiceR1 <= banco_regs[IF_instr[19:15]];
          ID_r1 <= banco_regs[IF_instr[19:15]];
          ID_funct3   <= IF_instr[14:12];
          ID_rd       <= IF_instr[11:7];
          ID_opcode   <= IF_instr[6:0];
          ID_regwrite <= 1;
        end

        7'b0100011: begin //sw
          ID_imm <= {8'b0, IF_instr[31:25], IF_instr[11:7]};
          ID_indiceR2 <= IF_instr[24:20];
          ID_indiceR1 <= IF_instr[19:15];
          ID_r2 <= banco_regs[IF_instr[24:20]];
          ID_r1 <= banco_regs[IF_instr[19:15]];
          ID_funct3   <= IF_instr[14:12];
          ID_opcode   <= IF_instr[6:0];
          ID_regwrite <= 0;
        end
        
        7'b0110011: begin //tipo r
          ID_funct7   <= IF_instr[31:25];
          ID_indiceR2       <= IF_instr[24:20];
          ID_indiceR1       <= IF_instr[19:15];
          ID_r2             <= banco_regs[IF_instr[24:20]];
          ID_r1             <= banco_regs[IF_instr[19:15]];
          ID_funct3   <= IF_instr[14:12];
          ID_rd       <= IF_instr[11:7];
          ID_opcode   <= IF_instr[6:0];
          ID_regwrite <= 1;
        end

        7'b1100011: begin //bge e blt
          ID_imm      <= {8'b0, IF_instr[31:25], IF_instr[11:7]};
          ID_indiceR2       <= IF_instr[24:20];
          ID_indiceR1       <= IF_instr[19:15];
          ID_r2             <= banco_regs[IF_instr[24:20]];
          ID_r1             <= banco_regs[IF_instr[19:15]];
          ID_funct3   <= IF_instr[14:12];
          ID_opcode   <= IF_instr[6:0];
          ID_regwrite <= 0;
        end

        7'b1101111: begin //JAL
          ID_imm      <= {IF_instr[31:12]};
          ID_rd       <= IF_instr[11:7];
          ID_opcode   <= IF_instr[6:0];
          flag_jump   <= 1;
          ID_regwrite <= 0;
        end

        7'b0010111: begin //AUIPC
          ID_imm       = {IF_instr[31:12]};
          ID_rd       <= IF_instr[11:7];
          ID_opcode   <= IF_instr[6:0];
          imm_sext     = {{12{ID_imm[19]}}, ID_imm}; // sinal-extend de 20 para 32 bits
          imm_shift   <= imm_sext << 12; // shift de 12 bits (multiplica por 2^12)
          ID_regwrite <= 1;
        end
          
      endcase
    end
  end

  //====================
  // Estágio EX
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      EX_alu_result <= 0;
      EX_rd         <= 0;
      EX_r2         <= 0;
      EX_opcode     <= 0;
      EX_instr      <= 0;
      EX_salto_cond <= 0;
      EX_alu_result <= 0;
      branch_valor  <= 0;
      AUIPC_result  <= 0;
      EX_regwrite   <= 0;
      EX_imm        <= 0;
    end else begin
      EX_instr      <= ID_instr;
      EX_opcode     <= ID_opcode;
      EX_rd         <= ID_rd;
      EX_r2         <= alu_in2;
      EX_imm        <= ID_imm;
      EX_salto_cond <= branch_taken;
      branch_valor  <= branch_target;
      EX_alu_result <= alu_result;
      EX_regwrite   <= ID_regwrite;
    end
  end

  //====================
  // Estágio MEM
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      MEM_data     <= 0;
      MEM_rd       <= 0;
      MEM_opcode   <= 0;
      MEM_instr    <= 0;
      MEM_regwrite <=0;
    end else begin
      MEM_instr    <= EX_instr;
      MEM_rd       <= EX_rd;
      MEM_opcode   <= EX_opcode;
      MEM_regwrite <= EX_regwrite;
      if(EX_regwrite == 1)
        MEM_data <= EX_alu_result;

      case (EX_opcode)
        7'b0000011: // lw
          MEM_data <= data_mem[EX_alu_result];

        7'b0100011: // sw
          data_mem[EX_alu_result] <= EX_r2;
      endcase
    end
  end

  //====================
  // Estágio WB
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset) begin end
    else begin
      if(MEM_opcode == 7'b1101111) //jal
        register_address <= link;

      //se nao for sw e tipo B
      if(MEM_regwrite == 1)
        banco_regs[MEM_rd] <= MEM_data; //ou seja: AUIPC, tipo R, addi e LW
    end
  end

endmodule