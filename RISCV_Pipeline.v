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
  reg [15:0] banco_regs   [0:31];  // 32 registradores
  reg[15:0] register_address; //x1 (register_address - return adress)
  reg[15:0] zero = 0; //registrador zero

  //=======================
  // Registradores pipeline
  //=======================
  // IF/ID
  reg [31:0] IF_ID_instr;
  reg [31:0] IF_ID_PC;

  // ID/EX
  reg [31:0] ID_EX_instr;
  reg [15:0] ID_EX_r1, ID_EX_r2;
  reg [19:0] ID_EX_imm;
  reg [4:0]  ID_EX_rd;
  reg [6:0]  ID_EX_opcode;
  reg [2:0]  ID_EX_funct3;
  reg [6:0]  ID_EX_funct7;
  reg salto_cond, flag_jump;
  reg link;
 

  // EX/MEM
  reg [31:0] EX_MEM_instr;
  reg [15:0] EX_MEM_alu_result, EM_MEM_r2;
  reg [4:0]  EX_MEM_rd;
  reg [6:0]  EX_MEM_opcode;
  //Para instrução AUIPC
  reg [15:0] imm_sext;
  reg [15:0] imm_shift;

  // MEM/WB
  reg [31:0] MEM_WB_instr;
  reg [15:0] MEM_WB_data;
  reg [4:0]  MEM_WB_rd;
  reg [6:0]  MEM_WB_opcode;

  //=====================
  // Contador de programa
  //=====================
  reg [31:0] PC;

  //=====================
  // Inicialização
  //=====================
  initial begin
    PC = 0;

    // instruções:
    // addi x1, x0, 5     ; x1 = 5
    // addi x2, x0, 10    ; x2 = 10
    // add  x3, x1, x2    ; x3 = x1 + x2 = 15
    // sub  x4, x2, x1    ; x4 = x2 - x1 = 5
    // sw   x3, 0(x0)     ; mem[0] = x3 = 15
    // lw   x5, 0(x0)     ; x5 = mem[0] = 15

    // 0: addi x1, x0,  10       ; x1 =  5
    instr_mem[0]  = {12'd10,  5'd0, 3'b000, 5'd1, 7'b0010011};
    // 1: addi x2, x0, 5       ; x2 = 10
    instr_mem[1]  = {12'd5, 5'd0, 3'b000, 5'd2, 7'b0010011};

    // 2-4: NOPs (aguarda x1 e x2 serem escritos)
    instr_mem[2]  = 32'b0;
    instr_mem[3]  = 32'b0;
    instr_mem[4]  = 32'b0;

    // 5: 		bge x1, x2, +8
    instr_mem[5]  = {7'b0000000, 5'd2, 5'd1, 3'b101, 5'b01000, 7'b1100011};

    // 6: addi x3, x0, 0 (não deve executar)
    instr_mem[6]  = {12'd3, 5'd0, 3'b000, 5'd3, 7'b0110011};

    // 7: addi x3, x0, 1 (x3←1)
    instr_mem[7]  = {12'd1, 5'd0, 3'b000, 5'd3, 7'b0010011};

    instr_mem[8]  = 32'b0;
    instr_mem[9]  = 32'b0;

    // 8: blt x2, x1, +8
    instr_mem[10]  = {7'b0000000, 5'd1, 5'd2, 3'b100, 5'b01000, 7'b1100011};

    // 9: addi x4, x0, 0 (não deve executar)
    instr_mem[11]  = {7'b0000000, 5'd0, 3'b010, 5'd4, 7'b0100011};

    // 10: addi x4, x1, 1 (x4←1)
    instr_mem[112]  = {7'b0000001, 5'd1, 3'b010, 5'd4, 7'b0100011};

    // 10: addi x5, x1, 1 (x4←1)
    instr_mem[13]  = {7'b0000001, 5'd1, 3'b010, 5'd5, 7'b0100011};

    // 11?15: NOPs ou instruções livres
    instr_mem[14] = 32'b0;
    instr_mem[15] = 32'b0;



    // limpa banco de registradores e mem
    for (i = 0; i < 32; i = i + 1) banco_regs[i] = 0;
    for (i = 0; i < 256; i = i + 1) data_mem[i] = 0;
  end


  //====================
  // ATUALIZAÇÃO PC
  //====================
always @(posedge clock or posedge reset) begin
    if (reset) begin
      PC <= 0;
      register_address <= 0;
    end else begin
      if (salto_cond == 1) begin //BGE/BLT
          PC <= PC + ID_EX_imm;
          ID_EX_imm <= 0;
      end

      else if(flag_jump == 1) begin
          PC <= PC + ID_EX_imm;
          link <= PC + 4;
          ID_EX_imm <= 0;
      end

      else
        PC <= PC + 4;
    end  
  end


  //====================
  // Estágio IF
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      IF_ID_instr <= 0;
      IF_ID_PC <= 0;
    end else begin
      IF_ID_instr <= instr_mem[PC >> 2];
      IF_ID_PC <= PC;
    end
  end

  //====================
  // Estágio ID
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      ID_EX_r1 <= 0;
      ID_EX_r2 <= 0;
      ID_EX_imm      <= 0;
      ID_EX_rd       <= 0;
      ID_EX_opcode   <= 0;
      ID_EX_funct3   <= 0;
      ID_EX_funct7   <= 0;
    end else begin
      ID_EX_instr <= IF_ID_instr;
      flag_jump <= 0;
      case(IF_ID_instr[6:0])
        7'b0010011,       //addi
        7'b0000011: begin //lw
          ID_EX_imm <= {8'b0, IF_ID_instr[31:20]};
          ID_EX_r1 <= banco_regs[IF_ID_instr[19:15]];
          ID_EX_funct3   <= IF_ID_instr[14:12];
          ID_EX_rd       <= IF_ID_instr[11:7];
          ID_EX_opcode   <= IF_ID_instr[6:0];
        end

        7'b0100011: begin //sw
          ID_EX_imm <= {8'b0, IF_ID_instr[31:25], IF_ID_instr[11:7]};
          ID_EX_r2 <= banco_regs[IF_ID_instr[24:20]];
          ID_EX_r1 <= banco_regs[IF_ID_instr[19:15]];
          ID_EX_funct3   <= IF_ID_instr[14:12];
          ID_EX_opcode   <= IF_ID_instr[6:0];
        end
        
        7'b0110011: begin //tipo r
          ID_EX_funct7   <= IF_ID_instr[31:25];
          ID_EX_r2 <= banco_regs[IF_ID_instr[24:20]];
          ID_EX_r1 <= banco_regs[IF_ID_instr[19:15]];
          ID_EX_funct3   <= IF_ID_instr[14:12];
          ID_EX_rd       <= IF_ID_instr[11:7];
          ID_EX_opcode   <= IF_ID_instr[6:0];
        end

        7'b1100011: begin //bge e blt
          ID_EX_imm <= {8'b0, IF_ID_instr[31:25], IF_ID_instr[11:7]};
          ID_EX_r2 <= banco_regs[IF_ID_instr[24:20]];
          ID_EX_r1 <= banco_regs[IF_ID_instr[19:15]];
          ID_EX_funct3   <= IF_ID_instr[14:12];
          ID_EX_opcode   <= IF_ID_instr[6:0];
        end

        7'b1100011: begin //JAL
          ID_EX_imm <= {IF_ID_instr[31:12]};
          ID_EX_rd       <= IF_ID_instr[11:7];
          ID_EX_opcode   <= IF_ID_instr[6:0];
          flag_jump <= 1;
        end

        7'b0010111: begin //AUIPC
          ID_EX_imm <= {IF_ID_instr[31:12]};
          ID_EX_rd       <= IF_ID_instr[11:7];
          ID_EX_opcode   <= IF_ID_instr[6:0];
        end
          
      endcase
    end
  end

  //====================
  // Estágio EX
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      EX_MEM_alu_result <= 0;
      EX_MEM_rd         <= 0;
      EM_MEM_r2         <= 0;
      EX_MEM_opcode     <= 0;
      salto_cond        <= 0;
    end else begin
      EX_MEM_instr      <= ID_EX_instr;
      EX_MEM_opcode     <= ID_EX_opcode;
      EX_MEM_rd         <= ID_EX_rd;
      EM_MEM_r2         <= ID_EX_r2;
      salto_cond        <= 0;
        //para auipc
      imm_sext  <= {{8{ID_EX_imm[7]}}, ID_EX_imm};  
      imm_shift <= imm_sext <<< 4;

      case (ID_EX_opcode)
        7'b0110011: begin // R-type (add, sub)
          case(ID_EX_funct7)
            7'b0100000:  //sub
              EX_MEM_alu_result <= ID_EX_r1 - ID_EX_r2;

            7'b0000000:  //add
              EX_MEM_alu_result <= ID_EX_r1 + ID_EX_r2;

            7'b0000001:  //mul
              EX_MEM_alu_result <= ID_EX_r1 * ID_EX_r2;
          endcase
        end

        7'b0010011: begin // addi
          EX_MEM_alu_result <= ID_EX_r1 + ID_EX_imm;
        end

        7'b0010111: //AUIPC
          EX_MEM_alu_result <= imm_shift + (PC+4);
        
        7'b1100011: begin//tipo B
          if(ID_EX_funct3 == 3'b101 && ID_EX_r1 >= ID_EX_r2) begin //bge
            IF_ID_instr <= 0;
            ID_EX_instr <= 0;
            ID_EX_opcode <= 0;
            ID_EX_funct3 <= 0;
            ID_EX_funct7 <= 0;
            ID_EX_r1 <= 0;
            ID_EX_r2 <= 0;
            ID_EX_rd <= 0;

            salto_cond <= 1;
          end
          else if(ID_EX_funct3 == 3'b100 && ID_EX_r1 < ID_EX_r2) begin//blt
            IF_ID_instr <= 0;
            ID_EX_instr <= 0;
            ID_EX_opcode <= 0;
            ID_EX_funct3 <= 0;
            ID_EX_funct7 <= 0;
            ID_EX_r1 <= 0;
            ID_EX_r2 <= 0;
            ID_EX_rd <= 0;

            salto_cond <= 1;
          end
        end

        7'b1101111: begin //JAL
          //2 BOLHAS -> nas etapas IF e ID
            IF_ID_instr <= 0;
            ID_EX_opcode <= 0;
            ID_EX_funct3 <= 0;
            ID_EX_funct7 <= 0;
            ID_EX_r1 <= 0;
            ID_EX_r2 <= 0;
            ID_EX_rd <= 0;
        end

        7'b0000011,        //lw
        7'b0010011,        // addi
        7'b0100011: begin  // sw
          EX_MEM_alu_result <= ID_EX_r1 + ID_EX_imm; // endereço ou soma imediata
        end
      endcase
    end
  end

  //====================
  // Estágio MEM
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      MEM_WB_data   <= 0;
      MEM_WB_rd     <= 0;
      MEM_WB_opcode <= 0;
    end else begin
      MEM_WB_instr  <= EX_MEM_instr;
      MEM_WB_rd     <= EX_MEM_rd;
      MEM_WB_opcode <= EX_MEM_opcode;

      case (EX_MEM_opcode)
        7'b0000011: // lw
          MEM_WB_data <= data_mem[EX_MEM_alu_result];

        7'b0100011: // sw
          data_mem[EX_MEM_alu_result] <= EM_MEM_r2;
          
        7'b0010011,  // addi
        7'b0110011:  // tipo r
          MEM_WB_data <= EX_MEM_alu_result;
          
      endcase
    end
  end

  //====================
  // Estágio WB
  //====================
  always @(posedge clock or posedge reset) begin
    if (reset) begin end
    else begin
      if(MEM_WB_opcode != 7'b1101111) //jal
        register_address <= link;
      //se nao for sw e tipo B
      if((MEM_WB_opcode != 7'b0100011 || MEM_WB_opcode != 7'b1100011) && MEM_WB_rd != 0 )
        banco_regs[MEM_WB_rd] <= MEM_WB_data;
    end
  end

endmodule