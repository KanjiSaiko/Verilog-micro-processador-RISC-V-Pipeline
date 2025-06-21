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
      uut.data_mem[0] = 32'd17;
      uut.data_mem[1] = 32'd97;
      uut.data_mem[2] = 32'd52;
      uut.data_mem[3] = 32'd58;
      // Algoritmo Mergesort para 4 elementos
      // Formato: uut.instr_mem[index] = 32'b...;
      // --- Código de Máquina ---
      // ======================= main =======================
      // PC=0x000: Inicializa o ponteiro da pilha (sp = x2) para um endereço alto.
      uut.instr_mem[0] = 32'b00001111110000000000000100010011; // addi sp, zero, 252
      // PC=0x004: Inicializa o contador de recursão (t0 = x5) em 3.
      uut.instr_mem[1] = 32'b00000000001100000000001010010011; // addi t0, zero, 3
      // PC=0x008: Chama a função 'ping'. Salva o endereço de retorno (0x0C) em ra.
      uut.instr_mem[2] = 32'b00000000110000000000000011101111; // jal ra, 12 (Alvo: 24)
      // PC=0x00C: Fim do programa. Loop infinito para parar.
      uut.instr_mem[3] = 32'b00000000000000000000000001101111; // jal zero, 0

      // ======================= Função ping =======================
      // PC=20: NOP para alinhamento (opcional, mas boa prática).
      uut.instr_mem[4] = 32'b00000000000000000000000000010011; // addi zero, zero, 0
      // PC=24: (ping) Base da recursão. Se t0 == 0, pula para o retorno.
      uut.instr_mem[5] = 32'b00000000000000101000111001100011; // beq t0, zero, 28 (Alvo: 0x30, ping_ret)
      // PC=28: Salva o ra na pilha. Primeiro, abre espaço.
      uut.instr_mem[6] = 32'b11111111110000010000000100010011; // addi sp, sp, -4
      // PC=32: Guarda o valor de ra no topo da pilha.
      uut.instr_mem[7] = 32'b00000000000100010010000000100011; // sw ra, 0(sp)
      // PC=36: Decrementa o contador.
      uut.instr_mem[8] = 32'b11111111111100101000001010010011; // addi t0, t0, -1
      // PC=40: Chama a função 'pong'. Salva o novo retorno (0x28) em ra.
      uut.instr_mem[9] = 32'b00000001000000000000000011101111; // jal ra, 16 (Alvo: 0x34)
      // PC=44: Restaura o 'ra' original da pilha para poder retornar ao chamador certo.
      uut.instr_mem[10] = 32'b00000000000000010010000010000011; // lw ra, 0(sp)
      // PC=48: Limpa a pilha.
      uut.instr_mem[11] = 32'b00000000010000010000000100010011; // addi sp, sp, 4
      // PC=50: (ping_ret) Retorna para quem chamou 'ping'.
      uut.instr_mem[12] = 32'b00000000000000001000000001100111; // jalr zero, 0(ra)

      // ======================= Função pong =======================
      // PC=0x034: (pong) Base da recursão. Se t0 == 0, pula para o retorno.
      uut.instr_mem[13] = 32'b00000000000000101000111001100011; // beq t0, zero, 28 (Alvo: 0x50, pong_ret)
      // PC=0x038: Salva o ra na pilha.
      uut.instr_mem[14] = 32'b11111111110000010000000100010011; // addi sp, sp, -4
      // PC=0x03C: Guarda o valor de ra no topo da pilha.
      uut.instr_mem[15] = 32'b00000000000100010010000000100011; // sw ra, 0(sp)
      // PC=0x040: Decrementa o contador.
      uut.instr_mem[16] = 32'b11111111111100101000001010010011; // addi t0, t0, -1
      // PC=0x044: *** SALTO PARA TRÁS *** Chama a função 'ping'.
      uut.instr_mem[17] = 32'b11111101000111111111000011101111; // jal ra, -48 (Alvo: 0x14)
      // PC=0x048: Restaura o 'ra' original da pilha.
      uut.instr_mem[18] = 32'b00000000000000010010000010000011; // lw ra, 0(sp)
      // PC=0x04C: Limpa a pilha.
      uut.instr_mem[19] = 32'b00000000010000010000000100010011; // addi sp, sp, 4
      // PC=0x050: (pong_ret) Retorna para quem chamou 'pong'.
      uut.instr_mem[20] = 32'b00000000000000001000000001100111; // jalr zero, 0(ra)
      // Passada 1.1: Ordena os dois primeiros elementos
      /*uut.instr_mem[0] = 32'b00000000000000000000001010000011; // 0x000: lw t0, 0(zero)
      uut.instr_mem[1] = 32'b00000000010000000000001100000011; // 0x004: lw t1, 4(zero)
      uut.instr_mem[2] = 32'b00000000011000101100100001100011; // 0x008: blt t0, t1, 16 -> (merge1_ok)
      uut.instr_mem[3] = 32'b00000000011000000010100000100011; // 0x00C: sw t1, 16(zero)
      uut.instr_mem[4] = 32'b00000000010100000010101000100011; // 0x010: sw t0, 20(zero)
      // PC=0x014, Alvo=0x020 , Offset = +12
      uut.instr_mem[5] = 32'b00000000110000000000000001101111; // 0x014: jal zero, 12  -> (merge2)
      uut.instr_mem[6] = 32'b00000000010100000010100000100011; // 0x018: (merge1_ok) sw t0, 16(zero)
      uut.instr_mem[7] = 32'b00000000011000000010101000100011; // 0x01C: sw t1, 20(zero)

      // Passada 1.2: Ordena os dois últimos elementos
      uut.instr_mem[8] = 32'b00000000100000000000001010000011; // 0x020: (merge2) lw t0, 8(zero)
      uut.instr_mem[9] = 32'b00000000110000000000001100000011; // 0x024: lw t1, 12(zero)
      // PC=0x028, Alvo=0x038 (merge2_ok), Offset = +16
      uut.instr_mem[10] = 32'b00000000011000101100100001100011; // 0x028: blt t0, t1, 16
      uut.instr_mem[11] = 32'b00000000011000000010110000100011; // 0x02C: sw t1, 24(zero)
      uut.instr_mem[12] = 32'b00000000010100000010111000100011; // 0x030: sw t0, 28(zero)
      // PC=0x034, Alvo=0x040 (final_merge), Offset = +12
      uut.instr_mem[13] = 32'b00000000110000000000000001101111; // 0x034: jal zero, 12
      uut.instr_mem[14] = 32'b00000000010100000010110000100011; // 0x038: (merge2_ok) sw t0, 24(zero)
      uut.instr_mem[15] = 32'b00000000011000000010111000100011; // 0x03C: sw t1, 28(zero)

      // Passada 2: Mesclagem Final
      uut.instr_mem[16] = 32'b00000001000000000000001010000011; // 0x040: (final_merge) lw t0, 16(zero)
      uut.instr_mem[17] = 32'b00000001010000000000001100000011; // 0x044: lw t1, 20(zero)
      uut.instr_mem[18] = 32'b00000001100000000000001110000011; // 0x048: lw t2, 24(zero)
      uut.instr_mem[19] = 32'b00000001110000000000010000000011; // 0x04C: lw t3, 28(zero)
      // PC=80, Alvo=0x08C , Offset = +60
      uut.instr_mem[20] = 32'b00000010011100101100111001100011; // 0x050: blt t0, t2, 60  -> (path_L)
      // Caminho R
      uut.instr_mem[21] = 32'b00000000011100000000000000100011; // 0x054: (path_R) sw t2, 0(zero)
      // PC=0x058, Alvo=0x06C (path_RL), Offset = +20
      uut.instr_mem[22] = 32'b00000001100100101100101001100011; // 0x058: blt t0, t3, 20
      // Caminho RR
      uut.instr_mem[23] = 32'b00000001110000000000001000100011; // 0x05C: sw t3, 4(zero)
      uut.instr_mem[24] = 32'b00000000010100000000010000100011; // 0x060: sw t0, 8(zero)
      uut.instr_mem[25] = 32'b00000000011000000000011000100011; // 0x064: sw t1, 12(zero)
      // PC=0x068, Alvo=0x0C4 (end_program), Offset = +92
      uut.instr_mem[26] = 32'b00001011100000000000000001101111; // 0x068: jal zero, 92
      // Caminho RL
      uut.instr_mem[27] = 32'b00000000010100000000001000100011; // 0x06C: (path_RL) sw t0, 4(zero)
      // PC=0x070, Alvo=0x080 (path_RL_L), Offset = +16
      uut.instr_mem[28] = 32'b00000001100100101100100001100011; // 0x070: blt t1, t3, 16
      uut.instr_mem[29] = 32'b00000001110000000000010000100011; // 0x074: sw t3, 8(zero)
      uut.instr_mem[30] = 32'b00000000011000000000011000100011; // 0x078: sw t1, 12(zero)
      // PC=0x07C, Alvo=0x0C4 (end_program), Offset = +72
      uut.instr_mem[31] = 32'b00001001000000000000000001101111; // 0x07C: jal zero, 72
      // Caminho RL_L
      uut.instr_mem[32] = 32'b00000000011000000000010000100011; // 0x080: (path_RL_L) sw t1, 8(zero)
      uut.instr_mem[33] = 32'b00000001110000000000011000100011; // 0x084: sw t3, 12(zero)
      // PC=0x088, Alvo=0x0C4 (end_program), Offset = +60
      uut.instr_mem[34] = 32'b00000111100000000000000001101111; // 0x088: jal zero, 60
      // Caminho L
      uut.instr_mem[35] = 32'b00000000010100000000000000100011; // 0x08C: (path_L) sw t0, 0(zero)
      // PC=0x090, Alvo=0x0B4 (path_LL), Offset = +36
      uut.instr_mem[36] = 32'b00000010011000101100001001100011; // 0x090: blt t1, t2, 36
      // Caminho LR
      uut.instr_mem[37] = 32'b00000000011100000000001000100011; // 0x094: sw t2, 4(zero)
      // PC=0x098, Alvo=0x0A8 (path_LR_L), Offset = +16
      uut.instr_mem[38] = 32'b00000001100100101100100001100011; // 0x098: blt t1, t3, 16
      uut.instr_mem[39] = 32'b00000001110000000000010000100011; // 0x09C: sw t3, 8(zero)
      uut.instr_mem[40] = 32'b00000000011000000000011000100011; // 0x0A0: sw t1, 12(zero)
      // PC=0x0A4, Alvo=0x0C4 (end_program), Offset = +32
      uut.instr_mem[41] = 32'b00001000000000000000000001101111; // 0x0A4: jal zero, 32
      // Caminho LR_L
      uut.instr_mem[42] = 32'b00000000011000000000010000100011; // 0x0A8: (path_LR_L) sw t1, 8(zero)
      uut.instr_mem[43] = 32'b00000001110000000000011000100011; // 0x0AC: sw t3, 12(zero)
      // PC=0x0B0, Alvo=0x0C4 (end_program), Offset = +20
      uut.instr_mem[44] = 32'b00000101000000000000000001101111; // 0x0B0: jal zero, 20
      // Caminho LL
      uut.instr_mem[45] = 32'b00000000011000000000001000100011; // 0x0B4: (path_LL) sw t1, 4(zero)
      uut.instr_mem[46] = 32'b00000000011100000000010000100011; // 0x0B8: sw t2, 8(zero)
      uut.instr_mem[47] = 32'b00000001110000000000011000100011; // 0x0BC: sw t3, 12(zero)
      // PC=0x0C0, Alvo=0x0C4 (end_program), Offset = +4
      uut.instr_mem[48] = 32'b00000000010000000000000001101111; // 0x0C0: jal zero, 4

      // --- Fim ---
      // PC=0x0C4, Alvo=0x0C4 (end_program), Offset = 0
      uut.instr_mem[49] = 32'b00000000000000000000000001101111; // 0x0C4: jal zero, 0*/

      uut.instr_mem[50] = 32'b0;
  end
  wire signed [31:0] extended_I_TYPE = $signed(uut.IF_instr[31:20]);
  wire signed [31:0] extended_B_TYPE = $signed({uut.IF_instr[31], uut.IF_instr[7], uut.IF_instr[30:25], uut.IF_instr[11:8], 1'b0});
  wire signed [31:0] extended_S_TYPE = $signed({uut.IF_instr[31:25], uut.IF_instr[11:7]});
  wire signed [31:0] extended_J_TYPE = $signed({uut.IF_instr[31], uut.IF_instr[19:12], uut.IF_instr[20], uut.IF_instr[30:21], 1'b0});
  reg signed [31:0] MEM_imm, WB_imm, MEM_r2;
  //PRINTANDO INSTRUCAO E ASSEMBLY
  initial begin
    wait (reset == 0);
    pc_anterior = 32'b0;
    forever begin
      @(posedge clock);
      if(reset == 0) begin
        MEM_imm <= uut.EX_imm;
        WB_imm <= MEM_imm;
        MEM_r2 <= uut.EX_r2;
        $display("\n\nPC alterado de %d para %d", pc_anterior, uut.PC);
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
            $display("Instrução IF  %b  -  LW x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[11:7], extended_I_TYPE, uut.IF_instr[19:15]);
          end
          7'b1100111:begin
            $display("Instrução IF  %b  -  JALR x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[11:7], extended_I_TYPE, uut.IF_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução IF  %b  -  ADDI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], extended_I_TYPE);
          end
          7'b1100011:begin //saltos
            case (uut.IF_instr[14:12])
              3'b101: begin
                $display("Instrução IF  %b  -  BGE x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              end
              3'b100: begin
                $display("Instrução IF  %b  -  BLT x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              end
              3'b001:
                $display("Instrução IF  %b  -  BNE x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              3'b000:
                $display("Instrução IF  %b  -  BEQ x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
            endcase
          end
          7'b1101111: begin
            $display("Instrução IF  %b  -  JAL x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], extended_J_TYPE);
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
            $display("Instrução ID  %b  -  SW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[24:20], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução ID  %b  -  LW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução ID  %b  -  ADDI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_imm);
          end
          7'b1100111: begin
            $display("Instrução ID  %b  -  JALR x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b1100011:
            case (uut.ID_funct3)
              3'b101: begin
                $display("Instrução ID  %b  -  BGE x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              end
              3'b100: begin
                $display("Instrução ID  %b  -  BLT x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              end
              3'b001:
                $display("Instrução ID  %b  -  BNE x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              3'b000:
                $display("Instrução ID  %b  -  BEQ x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
            endcase
          7'b1101111: begin
            $display("Instrução ID  %b  -  JAL x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm);
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
            $display("Instrução EX  %b  -  SW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[24:20], uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução EX  %b  -  LW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[11:7], uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução EX  %b  -  ADDI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_imm);
          end
          7'b1100111: begin
            $display("Instrução EX  %b  -  JALR x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[11:7],  uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b1100011:
            case (uut.EX_instr[14:12])
              3'b101: begin
                $display("Instrução EX  %b  -  BGE x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              end
              3'b100: begin
                $display("Instrução EX  %b  -  BLT x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              end
              3'b001:
                $display("Instrução EX  %b  -  BNE x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              3'b000:
                $display("Instrução EX  %b  -  BEQ x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
            endcase
          7'b1101111: begin
                $display("Instrução EX  %b  -  JAL x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_imm);
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
            $display("Instrução MEM  %b  -  SW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[24:20], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução MEM  %b  -  LW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução MEM  %b  -  ADDI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], MEM_imm);
          end
          7'b1100111: begin
            $display("Instrução MEM  %b  -  JALR x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b1100011:
            case (uut.MEM_instr[14:12])
              3'b101: begin
                $display("Instrução MEM  %b  -  BGE", uut.MEM_instr);
              end
              3'b100: begin
                $display("Instrução MEM  %b  -  BLT x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
              end
              3'b001:
                $display("Instrução MEM  %b  -  BNE x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
              3'b000:
                $display("Instrução MEM  %b  -  BEQ x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
            endcase
          7'b1101111: begin
            $display("Instrução MEM  %b  -  JAL x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm);
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
            $display("Instrução WB  %b  -  SW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[24:20], WB_imm, uut.WB_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução WB  %b  -  LW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[11:7], WB_imm, uut.WB_instr[19:15]);
          end
          7'b0010011: begin
            $display("Instrução WB  %b  -  ADDI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], WB_imm);
          end
          7'b1100111: begin
            $display("Instrução WB  %b  -  JALR x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[11:7], WB_imm, uut.WB_instr[19:15]);
          end
          7'b1100011:
            case (uut.WB_instr[14:12])
              3'b101: begin
                $display("Instrução WB  %b  -  BGE x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              end
              3'b100: begin
                $display("Instrução WB  %b  -  BLT x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              end
              3'b001:
                $display("Instrução WB  %b  -  BNE x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              3'b001:
                $display("Instrução WB  %b  -  BEQ x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
            endcase
          7'b1101111: begin
            $display("Instrução WB  %b  -  JAL x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], WB_imm);
          end

          default: $display("Instrução WB  %b", uut.WB_instr);
        endcase
      //PRINTS DAS OPERAÇOES
        case(uut.IF_instr[6:0])
          7'b0100011:begin//sw
            $display("SW - ETAPA ID: ID_r2 = banco_regs[%0d] = %0d", uut.IF_instr[24:20], uut.banco_regs[uut.IF_instr[24:20]]);
            $display("Destino de escrita na mem: %0d", uut.banco_regs[uut.IF_instr[19:15]]);
          end
          7'b1100011: //blt/bge
          $display("BLT - Etapa ID: id_r1: banco_regs[%0d] = %0d  ||  id_r2: banco_regs[%0d] = %0d",uut.IF_instr[19:15], uut.banco_regs[uut.IF_instr[19:15]], uut.IF_instr[24:20], uut.banco_regs[uut.IF_instr[24:20]]);
        endcase

        case (uut.ID_opcode)
          7'b0010011,  // ADDI
          7'b0000011:begin  // LW
          end

          7'b0100011:begin  // SW
          //$display("SW - ETAPA EX: Valor de reg[%0d] no endereço [%0d]",  uut.EX_rd, uut.EX_alu_result>>2);
          //$display("Soma do offset: %0d + %0d = %0d", uut.alu_in1, uut.ID_imm, uut.alu_result);
          end

          7'b1101111: begin //JAL
          $display("flag_jump: %0d", uut.flag_jump);
          $display("Salto -> endereço: PC %0d + %0d = %0d", uut.ID_PC, uut.ID_imm, uut.ID_imm + uut.ID_PC);
          end
        endcase

        case (uut.EX_opcode)
          7'b0100011:  // SW
            $display("SW - ETAPA MEM: Mem_data[%0d] = %0d  ||  destino: %0d", uut.EX_alu_result >> 2, uut.EX_r2, uut.EX_r1);

          7'b0000011:  // LW
            $display("LW - ETAPA MEM: Mem_data[%0d] = %0d", (uut.EX_alu_result >> 2), uut.MEM_data);
        endcase
        case(uut.MEM_opcode)
          7'b0100011:  // SW
            $display("SW - ETAPA WB: Mem_data[%0d] = %0d  ||  destino: %0d", uut.MEM_alu_result >> 2, MEM_r2, uut.MEM_r1);
        endcase

        //$display("Valor de ID_r1: %0d  || EX_r1: %0d", uut.ID_r1, uut.EX_r1);
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
          $display("Valor de ID_r1: %0d  ||  Valor de ID_r2: %0d", uut.ID_r1, uut.ID_r2);
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
