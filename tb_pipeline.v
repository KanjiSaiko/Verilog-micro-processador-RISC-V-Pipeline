`timescale 1ns / 1ps

module tb_pipeline;

  reg clock;
  reg reset;
  integer    i;
  // Instância do módulo principal
  RISCV_Pipeline uut (
    .clock(clock),
    .reset(reset)
  );


  reg [31:0] pc_anterior;

  //––––––––––––––––––––––––––––––––––––––––––––––––––––––
  // 1) Geração de clock
  initial begin
    clock = 0;
    forever #5 clock = ~clock;  // 10 ns de período
  end

  //––––––––––––––––––––––––––––––––––––––––––––––––––––––
  // 2) Pulso de reset
  initial begin
    reset = 1;
    for(i=0;i<256;i=i+1)begin
      uut.data_mem[i] = 0;
      uut.instr_mem[i] = 0;
    end
    #20;       // mantém reset alto por 20 ns
    reset = 0;
  end

  // Bloco de preload
  initial begin
      // aguarda sair do reset
      wait (reset == 0);
      // carrega os 4 valores que você quer ordenar:
     // Mergesort para 4 elementos, SEM saltos para trás (offsets negativos).
      // carrega os 4 valores que você quer ordenar:
      uut.data_mem[0] = 32'd42;
      uut.data_mem[1] = 32'd17;
      uut.data_mem[2] = 32'd93;
      uut.data_mem[3] = 32'd58;
      // Algoritmo Mergesort para 4 elementos
      // Formato: uut.instr_mem[index] = 32'b...;

      // Passada 1.1: Ordena os dois primeiros elementos
      uut.instr_mem[0] = 32'b00000000000000000000001010000011; // 0x000: lw t0, 0(zero)
      uut.instr_mem[1] = 32'b00000000010000000000001100000011; // 0x004: lw t1, 4(zero)
      uut.instr_mem[2] = 32'b00000000011000101100100001100011; // 0x008: blt t0, t1, 16 (pula para merge1_ok) // CORRIGIDO
      uut.instr_mem[3] = 32'b00000000011000000010100000100011; // 0x00C: sw t1, 16(zero) // CORRIGIDO
      uut.instr_mem[4] = 32'b00000000010100000010101000100011; // 0x010: sw t0, 20(zero) // CORRIGIDO
      uut.instr_mem[5] = 32'b00000000110000000000000001101111; // 0x014: jal zero,12 (merge2)
      uut.instr_mem[6] = 32'b00000000010100000010100000100011; // 0x018: (merge1_ok) sw t0, 16(zero) // CORRIGIDO
      uut.instr_mem[7] = 32'b00000000011000000010101000100011; // 0x01C: sw t1, 20(zero) // CORRIGIDO

      // Passada 1.2: Ordena os dois últimos elementos
      uut.instr_mem[8] = 32'b00000000100000000000001010000011; // 0x020: (merge2) lw t0, 8(zero)
      uut.instr_mem[9] = 32'b00000000110000000000001100000011; // 0x024: lw t1, 12(zero)
      uut.instr_mem[10] = 32'b00000000011000101100100001100011; // 0x028: blt t0, t1, 16 (pula para merge2_ok) // CORRIGIDO
      uut.instr_mem[11] = 32'b00000000011000000010110000100011; // 0x02C: sw t1, 24(zero) // CORRIGIDO
      uut.instr_mem[12] = 32'b00000000010100000010111000100011; // 0x030: sw t0, 28(zero) // CORRIGIDO
      uut.instr_mem[13] = 32'b00000000110000000000000001101111; // 0x034: jal zero,12 (final_merge)
      uut.instr_mem[14] = 32'b00000000010100000010110000100011; // 0x038: (merge2_ok) sw t0, 24(zero) // CORRIGIDO
      uut.instr_mem[15] = 32'b00000000011000000010111000100011; // 0x03C: sw t1, 28(zero) // CORRIGIDO

      // Passada 2: Mesclagem Final
      uut.instr_mem[16] = 32'b00000001000000000000001010000011; // 0x040: (final_merge) lw t0, 16(zero)
      uut.instr_mem[17] = 32'b00000001010000000000001100000011; // 0x044: lw t1, 20(zero)
      uut.instr_mem[18] = 32'b00000001100000000000001110000011; // 0x048: lw t2, 24(zero)
      uut.instr_mem[19] = 32'b00000001110000000000010000000011; // 0x04C: lw t3, 28(zero)
      uut.instr_mem[20] = 32'b00000100101000101100101001100011; // 0x050: blt t0, t2, 80 (pula para path_L)
      // Caminho R
      uut.instr_mem[21] = 32'b00000000101000000000000000100011; // 0x054: (path_R) sw t2, 0(zero)
      uut.instr_mem[22] = 32'b00000100110100101100011001100011; // 0x058: blt t0, t3, 24 (pula para path_RL)
      // Caminho RR
      uut.instr_mem[23] = 32'b00000000110100000000001000100011; // 0x05C: sw t3, 4(zero)
      uut.instr_mem[24] = 32'b00000000101000000000010000100011; // 0x060: sw t0, 8(zero)
      uut.instr_mem[25] = 32'b00000000101100000000011000100011; // 0x064: sw t1, 12(zero)
      uut.instr_mem[26] = 32'b00000101110000000000000001101111; // 0x068: jal zero,92 (end_program)
      // Caminho RL
      uut.instr_mem[27] = 32'b00000000101000000000001000100011; // 0x06C: (path_RL) sw t0, 4(zero)
      uut.instr_mem[28] = 32'b00000100110100101100011001100011; // 0x070: blt t1, t3, 24 (pula para path_RL_L)
      uut.instr_mem[29] = 32'b00000000110100000000010000100011; // 0x074: sw t3, 8(zero)
      uut.instr_mem[30] = 32'b00000000101100000000011000100011; // 0x078: sw t1, 12(zero)
      uut.instr_mem[31] = 32'b00000100100000000000000001101111; // 0x07C: jal zero,72 (end_program)
      // Caminho RL_L
      uut.instr_mem[32] = 32'b00000000101100000000010000100011; // 0x080: (path_RL_L) sw t1, 8(zero)
      uut.instr_mem[33] = 32'b00000000110100000000011000100011; // 0x084: sw t3, 12(zero)
      uut.instr_mem[34] = 32'b00000011110000000000000001101111; // 0x088: jal zero,60 (end_program)
      // Caminho L
      uut.instr_mem[35] = 32'b00000000101000000000000000100011; // 0x08C: (path_L) sw t0, 0(zero)
      uut.instr_mem[36] = 32'b00000100101000101100100001100011; // 0x090: blt t1, t2, 56 (pula para path_LL)
      // Caminho LR
      uut.instr_mem[37] = 32'b00000000101000000000001000100011; // 0x094: sw t2, 4(zero)
      uut.instr_mem[38] = 32'b00000100110100101100011001100011; // 0x098: blt t1, t3, 24 (pula para path_LR_L)
      uut.instr_mem[39] = 32'b00000000110100000000010000100011; // 0x09C: sw t3, 8(zero)
      uut.instr_mem[40] = 32'b00000000101100000000011000100011; // 0x0A0: sw t1, 12(zero)
      uut.instr_mem[41] = 32'b00000010000000000000000001101111; // 0x0A4: jal zero,32 (end_program)
      // Caminho LR_L
      uut.instr_mem[42] = 32'b00000000101100000000010000100011; // 0x0A8: (path_LR_L) sw t1, 8(zero)
      uut.instr_mem[43] = 32'b00000000110100000000011000100011; // 0x0AC: sw t3, 12(zero)
      uut.instr_mem[44] = 32'b00000001010000000000000001101111; // 0x0B0: jal zero,20 (end_program
      // Caminho LL
      uut.instr_mem[45] = 32'b00000000101100000000001000100011; // 0x0B4: (path_LL) sw t1, 4(zero)
      uut.instr_mem[46] = 32'b00000000101000000000010000100011; // 0x0B8: sw t2, 8(zero)
      uut.instr_mem[47] = 32'b00000000110100000000011000100011; // 0x0BC: sw t3, 12(zero)
      uut.instr_mem[48] = 32'b00000000010000000000000001101111; // 0x0C0: jal zero,4  (end_program)

      // Fim
      uut.instr_mem[49] = 32'b00000000000000000000000001101111; // 0x0C4: jal zero,0  (end_program)

      uut.instr_mem[50] = 32'b0;
  end

  //PRINTANDO INSTRUCAO E ASSEMBLY
  initial begin
    wait (reset == 0);
    pc_anterior = 32'b0;
    forever begin
      @(posedge clock);
      if(reset == 0) begin
        $display("\nPC alterado de %d para %d", pc_anterior, uut.PC);
        case (uut.IF_instr[6:0])
          7'b0110011: begin // R-Type
              case (uut.IF_instr[31:25])
                7'b0000000:begin $display("Instrução IF  %b  -  ADD x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]); end
                7'b0000001:begin $display("Instrução IF  %b  -  MUL x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]); end
                7'b0100000:begin $display("Instrução IF  %b  -  SUB x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]); end
              endcase
            end
          7'b0100011:begin
            $display("Instrução IF  %b  -  SW x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[24:20], {uut.IF_instr[31:25], uut.IF_instr[11:7]}, uut.IF_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução IF  %b  -  LW x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[31:20], uut.IF_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução IF  %b  -  ADDI", uut.IF_instr);
          end
          7'b1100011:
            case (uut.IF_instr[14:12])
              3'b101: begin
                $display("Instrução IF  %b  -  BGE", uut.IF_instr);
              end
              3'b100: begin
                $display("Instrução IF  %b  -  BLT x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], {uut.IF_instr[31:25], uut.IF_instr[11:7]});
              end
            endcase
          7'b1101111: begin
            $display("Instrução IF  %b  -  JAL x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], {uut.IF_instr[31], uut.IF_instr[19:12], uut.IF_instr[20], uut.IF_instr[30:21], 1'b0});
          end

          default: $display("Instrução IF  %b", uut.IF_instr);
        endcase

        case(uut.ID_opcode)
          7'b0110011: begin // R-Type
              case (uut.ID_funct7)
                7'b0000000:begin $display("Instrução ID  %b  -  ADD", uut.ID_instr); end
                7'b0000001:begin $display("Instrução ID  %b  -  MUL", uut.ID_instr); end
                7'b0100000:begin $display("Instrução ID  %b  -  SUB", uut.ID_instr); end
              endcase
            end
          7'b0100011:begin
            $display("Instrução ID  %b  -  SW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[24:20], {uut.ID_instr[31:25], uut.ID_instr[11:7]}, uut.ID_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução ID  %b  -  LW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[31:20], uut.ID_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução ID  %b  -  ADDI", uut.ID_instr);
          end
          7'b1100011:
            case (uut.ID_funct3)
              3'b101: begin
                $display("Instrução ID  %b  -  BGE", uut.ID_instr);
              end
              3'b100: begin
                $display("Instrução ID  %b  -  BLT x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], {uut.ID_instr[31:25], uut.ID_instr[11:7]});
              end
            endcase
          7'b1101111: begin
            $display("Instrução ID  %b  -  JAL x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], {uut.ID_instr[31], uut.ID_instr[19:12], uut.ID_instr[20], uut.ID_instr[30:21], 1'b0});
          end

          default: $display("Instrução ID  %b", uut.ID_instr);
        endcase

        case(uut.EX_opcode)
          7'b0110011: begin // R-Type
              case (uut.EX_instr[31:25])
                7'b0000000:begin $display("Instrução EX  %b  -  ADD", uut.EX_instr); end
                7'b0000001:begin $display("Instrução EX  %b  -  MUL", uut.EX_instr); end
                7'b0100000:begin $display("Instrução EX  %b  -  SUB", uut.EX_instr); end
              endcase
            end
          7'b0100011:begin
            $display("Instrução EX  %b  -  SW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[24:20], {uut.EX_instr[31:25], uut.EX_instr[11:7]}, uut.EX_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução EX  %b  -  LW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[31:20], uut.EX_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução EX  %b  -  ADDI", uut.EX_instr);
          end
          7'b1100011:
            case (uut.EX_instr[14:12])
              3'b101: begin
                $display("Instrução EX  %b  -  BGE", uut.EX_instr);
              end
              3'b100: begin
                $display("Instrução EX  %b  -  BLT x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], {uut.EX_instr[31:25], uut.EX_instr[11:7]});
              end
            endcase
          7'b1101111: begin
                $display("Instrução EX  %b  -  JAL x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], {uut.EX_instr[31], uut.EX_instr[19:12], uut.EX_instr[20], uut.EX_instr[30:21], 1'b0});
          end

          default: $display("Instrução EX  %b", uut.EX_instr);
        endcase

        case(uut.MEM_opcode)
          7'b0110011: begin // R-Type
              case (uut.MEM_instr[31:25])
                7'b0000000:begin $display("Instrução MEM  %b  -  ADD", uut.MEM_instr); end
                7'b0000001:begin $display("Instrução MEM  %b  -  MUL", uut.MEM_instr); end
                7'b0100000:begin $display("Instrução MEM  %b  -  SUB", uut.MEM_instr); end
              endcase
            end
          7'b0100011:begin
            $display("Instrução MEM  %b  -  SW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[24:20], {uut.MEM_instr[31:25], uut.MEM_instr[11:7]}, uut.MEM_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução MEM  %b  -  LW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[31:20], uut.MEM_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução MEM  %b  -  ADDI", uut.MEM_instr);
          end
          7'b1100011:
            case (uut.MEM_instr[14:12])
              3'b101: begin
                $display("Instrução MEM  %b  -  BGE", uut.MEM_instr);
              end
              3'b100: begin
                $display("Instrução MEM  %b  -  BLT x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], {uut.MEM_instr[31:25], uut.MEM_instr[11:7]});
              end
            endcase
          7'b1101111: begin
            $display("Instrução MEM  %b  -  JAL x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], {uut.MEM_instr[31], uut.MEM_instr[19:12], uut.MEM_instr[20], uut.MEM_instr[30:21], 1'b0});
          end

          default: $display("Instrução MEM  %b", uut.MEM_instr);
        endcase

        case(uut.WB_instr[6:0])
          7'b0110011: begin // R-Type
              case (uut.WB_instr[31:25])
                7'b0000000:begin $display("Instrução WB  %b  -  ADD", uut.WB_instr); end
                7'b0000001:begin $display("Instrução WB  %b  -  MUL", uut.WB_instr); end
                7'b0100000:begin $display("Instrução WB  %b  -  SUB", uut.WB_instr); end
              endcase
            end
         7'b0100011:begin
            $display("Instrução WB  %b  -  SW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[24:20], {uut.WB_instr[31:25], uut.WB_instr[11:7]}, uut.WB_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução WB  %b  -  LW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[31:20], uut.WB_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução WB  %b  -  ADDI", uut.WB_instr);
          end
          7'b1100011:
            case (uut.WB_instr[14:12])
              3'b101: begin
                $display("Instrução WB  %b  -  BGE", uut.WB_instr);
              end
              3'b100: begin
                $display("Instrução WB  %b  -  BLT x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], {uut.WB_instr[31:25], uut.WB_instr[11:7]});
              end
            endcase
          7'b1101111: begin
            $display("Instrução WB  %b  -  JAL x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], {uut.WB_instr[31], uut.WB_instr[19:12], uut.WB_instr[20], uut.WB_instr[30:21], 1'b0});
          end

          default: $display("Instrução WB  %b", uut.WB_instr);
        endcase
      //PRINTS DAS OPERAÇOES
        case (uut.ID_opcode)
          7'b0110011: begin // R-Type
          $display("R-TYPE:");
            case (uut.ID_funct7)
              7'b0000000: $display("ULA: %0d + %0d = %0d", uut.alu_in1, uut.alu_in2, (uut.alu_in1 + uut.alu_in2));
              7'b0000001: $display("ULA: %0d * %0d = %0d", uut.alu_in1, uut.alu_in2, (uut.alu_in1 * uut.alu_in2));
              7'b0100000: $display("ULA: %0d - %0d = %0d", uut.alu_in1, uut.alu_in2, (uut.alu_in1 - uut.alu_in2));
            endcase
          end

          7'b0010011,  // ADDI
          7'b0000011,  // LW
          7'b0100011:begin  // SW
          $display("I-Type");
          $display("ULA: %0d + %0d = %0d", uut.alu_in1, uut.ID_imm, (uut.alu_result));
          $display("ETAPA EX: EX-ALURESULT = %0d", uut.EX_alu_result);
          end

          7'b1101111: begin //JAL
          $display("flag_jump: %0d", uut.flag_jump);
          $display("Salto -> endereço em decimal: %0d + PC %0d = %0d", uut.ID_imm, uut.ID_PC, uut.ID_imm + uut.ID_PC);
          end
        endcase

        case (uut.EX_opcode)
          7'b0010011,  // ADDI
          7'b0100011:begin  // SW
          $display("ETAPA MEM: MEM_data = %0d || Reg Destino = %0d", uut.MEM_data, uut.MEM_rd);
          end

          7'b0000011:  // LW
          $display("ETAPA MEM: Valor na Memoria de Dados = %0d || Posicao da mem_dados = %0d", uut.data_mem[uut.EX_alu_result >> 2], (uut.EX_alu_result >> 2));
        endcase

        pc_anterior = uut.PC;
        $display("--------------------------------------------------------------------------------");
        $display("Reg[0]: %0d  || Reg[1]: %0d  || Reg[2]: %0d  || Reg[3]: %0d", uut.banco_regs[0], uut.banco_regs[1], uut.banco_regs[2], uut.banco_regs[3]);
        $display("Reg[4]: %0d  || Reg[5]: %0d  || Reg[6]: %0d  || Reg[7]: %0d", uut.banco_regs[4], uut.banco_regs[5], uut.banco_regs[6], uut.banco_regs[7]);
        $display("Reg[8]: %0d  || Reg[9]: %0d  || Reg[10]: %0d || Reg[11]: %0d", uut.banco_regs[8], uut.banco_regs[9], uut.banco_regs[10], uut.banco_regs[11]);
        $display("Reg[12]: %0d || Reg[13]: %0d || Reg[14]: %0d || Reg[15]: %0d", uut.banco_regs[12], uut.banco_regs[13], uut.banco_regs[14], uut.banco_regs[15]);
        $display("\ndata_mem[0] = %0d || data_mem[4] = %0d || data_mem[8]  = %0d", uut.data_mem[0], uut.data_mem[4], uut.data_mem[8]);
        $display("data_mem[1] = %0d || data_mem[5] = %0d || data_mem[9]  = %0d", uut.data_mem[1], uut.data_mem[5], uut.data_mem[9]);
        $display("data_mem[2] = %0d || data_mem[6] = %0d || data_mem[10] = %0d", uut.data_mem[2], uut.data_mem[6], uut.data_mem[10]);
        $display("data_mem[3] = %0d || data_mem[7] = %0d || data_mem[11] = %0d", uut.data_mem[3], uut.data_mem[7], uut.data_mem[11]);
        $display("--------------------------------------------------------------------------------");
        if (uut.ID_instr[6:0] == 7'b1100011) begin
          $display("=====================================================");
          if(uut.ID_funct3[3:0] == 3'b101)
            $display("BRANCH BGE detectado na etapa ID");
          else
            $display("BRANCH BLT detectado na etapa ID");

          $display("Comparando rs1: %d     rs2: %d", uut.alu_in1, uut.alu_in2);
          $display("Resultado da comparação: %s", uut.branch_taken ? "TOMADO" : "NAO TOMADO");
          $display("PC alvo: %d", uut.branch_target);
          $display("====================================================");
        end
      end
    end
  end

  // 4) Espera o mergesort rodar e imprime o resultado
  initial begin
    wait (reset == 0);
    #500;  // tempo suficiente para ordenar

    $display("\n--- Vetor ordenado em data_mem ---");
    for (i = 0; i < 32; i = i + 1)
      $display("data_mem[%0d] = %0d", i, uut.data_mem[i]);

    $finish;
  end


endmodule
