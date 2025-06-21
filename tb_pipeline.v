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
      // --- Dados Iniciais (Exemplo) ---
      uut.data_mem[0] = 32'd49;
      uut.data_mem[1] = 32'd17;
      uut.data_mem[2] = 32'd93;
      uut.data_mem[3] = 32'd58;
      uut.data_mem[255] = 32'd4; //N elementos que quero ordenar

      // ======================= main =======================
       // PC=0x000: addi sp, zero, 1020 -> Inicializa sp logo abaixo de N.
      uut.instr_mem[0] = 32'b00000000000001000000010100010011;
      // PC=0x004: lw s0, 1020(zero) -> Carrega N da memória para s0.
      uut.instr_mem[1] = 32'b00000110111101111101111001100011;
      // PC=0x008: addi a0, zero, 0 -> Prepara arg1: inicio = 0.
      uut.instr_mem[2] = 32'b00000000000000000000010100010011;
      // PC=0x12: addi a1, s0, -1 -> Prepara arg2: fim = N-1.
      uut.instr_mem[3] = 32'b11111111111101000000010110010011;
      // PC=0x16: jal ra, 52 -> Chama   (Alvo: 0x44).
      uut.instr_mem[4] = 32'b00000011010000000000000011101111; // 0x034000EF
      // PC=0x020: jal zero, 0 -> (halt) Fim do programa.
      uut.instr_mem[5] = 32'b00000000000000000000000001101111;

      // ======================= Função mergesort(a0=inicio, a1=fim) =======================
      // PC=0x024: (mergesort) addi sp, sp, -12 -> Aloca 3 palavras na pilha.
      uut.instr_mem[17] = 32'b11111111010000010000000100010011;
      // PC=0x028: sw ra, 8(sp) -> Salva ra na pilha.
      uut.instr_mem[18] = 32'b00000000000100010010010000100011;
      // PC=0x32: sw a0, 4(sp) -> Salva 'inicio' na pilha.
      uut.instr_mem[19] = 32'b00000101000100010010010000100011;
      // PC=0x36: sw a1, 0(sp) -> Salva 'fim' na pilha.
      uut.instr_mem[20] = 32'b00000101100100010010000000100011;
      // PC=0x40: bge a0, a1, 124 -> Caso Base: se inicio>=fim, pula para o retorno (Alvo: 0xD0).
      uut.instr_mem[21] = 32'b00001110101101010101111001100011;
      // PC=0x058: add t0, a0, a1 -> t0 = inicio + fim.
      uut.instr_mem[22] = 32'b00000000101101010000001010110011;
      // PC=0x05C: srli t0, t0, 1 -> t0 = meio = t0 / 2.
      uut.instr_mem[23] = 32'b00000000000100101101001010010011;
      // Chamada Recursiva 1: mergesort(inicio, meio)
      // PC=0x060: addi a1, t0, 0 -> Prepara arg2: fim = meio.
      uut.instr_mem[24] = 32'b00000000000000101000010110010011;
      // PC=0x064: jal ra, -20 -> Salto para trás para mergesort (Alvo: 0x50).
      // O seu valor original já estava correto.
      uut.instr_mem[25] = 32'b11111110110111111111000011101111; // 0xFEDFF0EF
      // Restaura args originais para a segunda chamada
      // PC=0x068: lw a0, 4(sp)
      uut.instr_mem[26] = 32'b00000000010000010010010100000011;
      // PC=0x06C: lw a1, 0(sp)
      uut.instr_mem[27] = 32'b00000000000000010010010110000011;
      // Prepara args para Chamada Recursiva 2: mergesort(meio+1, fim)
      // PC=0x070: add t0, a0, a1
      uut.instr_mem[28] = 32'b00000000101101010000001010110011;
      // PC=0x074: srli t0, t0, 1
      uut.instr_mem[29] = 32'b00000000000100101101001010010011;
      // PC=0x078: addi t1, t0, 1 -> t1 = meio + 1.
      uut.instr_mem[30] = 32'b00000000000100101001001100010011;
      // PC=0x07C: addi a0, t1, 0 -> Prepara arg1: inicio = meio + 1.
      uut.instr_mem[31] = 32'b00000000000000110000010100010011;
      // PC=0x080: jal ra, -48 -> Salto para trás para mergesort (Alvo: 0x50).
      // CORRIGIDO: O offset de -48 (-0x30) foi codificado corretamente.
      uut.instr_mem[32] = 32'b11111101000011111111000011101111; // 0xFD0FF0EF
      // Agora chama a função merge
      // PC=0x084: lw a0, 4(sp) -> Restaura arg 'inicio'
      uut.instr_mem[33] = 32'b00000000010000010010010100000011;
      // PC=0x088: lw a2, 0(sp) -> Reusa a2 para 'fim'
      uut.instr_mem[34] = 32'b00000000000000010010011000000011;
      // PC=0x08C: add t0, a0, a2 -> Calcula (inicio+fim)
      uut.instr_mem[35] = 32'b00000000110001010000001010110011;
      // PC=0x090: srli t0, t0, 1 -> Calcula 'meio'
      uut.instr_mem[36] = 32'b00000000000100101101001010010011;
      // PC=0x094: addi a1, t0, 0 -> Prepara arg 'meio'
      uut.instr_mem[37] = 32'b00000000000000101000010110010011;
      // PC=0x098: jal ra, -128 -> Salto para trás para o início da função merge (Alvo: 0x18).
      // CORRIGIDO: O offset de -128 (-0x80) foi codificado corretamente.
      uut.instr_mem[38] = 32'b11111000000011111111000011101111; // 0xF80FF0EF
      // Retorno da Função mergesort
      // PC=0x0D0: (merge_ret) lw ra, 8(sp) -> Restaura ra da pilha.
      uut.instr_mem[41] = 32'b00000000100000010010000010000011;
      // PC=0x0D4: addi sp, sp, 12 -> Limpa a pilha.
      uut.instr_mem[42] = 32'b00000001010000010000000100010011;
      // PC=0x0D8: jalr zero, 0(ra) -> Retorna para quem chamou.
      uut.instr_mem[43] = 32'b00000000000000001000000001100111; 
  end
  wire signed [31:0] extended_I_TYPE = $signed(uut.IF_instr[31:20]);
  wire signed [31:0] extended_B_TYPE = $signed({uut.IF_instr[31], uut.IF_instr[7], uut.IF_instr[30:25], uut.IF_instr[11:8], 1'b0});
  wire signed [31:0] extended_S_TYPE = $signed({uut.IF_instr[31:25], uut.IF_instr[11:7]});
  wire signed [31:0] extended_J_TYPE = $signed({uut.IF_instr[31], uut.IF_instr[19:12], uut.IF_instr[20], uut.IF_instr[30:21], 1'b0});
  reg signed [31:0] MEM_imm, WB_imm, MEM_r2, WB_r1, WB_r2;
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
        WB_r1 <= uut.MEM_r1;
        WB_r2 <= MEM_r2;
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
            case(uut.IF_instr[14:12])
              3'b000: $display("Instrução IF  %b  -  ADDI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], extended_I_TYPE);
              3'b001: $display("Instrução IF  %b  -  SLLI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
              3'b101: $display("Instrução IF  %b  -  SRLI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
            endcase
            
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
          7'b0110111: $display("Instrução IF  %b  -  LUI x%0d, %0d", uut.IF_instr[11:7], uut.{IF_instr[31:12], 12'b0});
          7'b0010111: $display("Instrução IF  %b  -  AUIPC x%0d, %0d", uut.IF_instr[11:7], uut.{IF_instr[31:12], 12'b0});

          default: $display("Instrução IF  %b", uut.IF_instr);
        endcase

        case(uut.ID_opcode)
          7'b0110011: begin // R-Type
              case (uut.ID_funct7)
                7'b0000000:begin $display("Instrução ID  %b  -  ADD x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2); end
                7'b0000001:begin $display("Instrução ID  %b  -  MUL x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2); end
                7'b0100000:begin $display("Instrução ID  %b  -  SUB x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2); end
              endcase
            end
          7'b0100011:begin
            $display("Instrução ID  %b  -  SW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[24:20], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução ID  %b  -  LW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.ID_funct3)
              3'b000: $display("Instrução ID  %b  -  ADDI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_imm);
              3'b001: $display("Instrução ID  %b  -  SLLI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_instr[24:20]);
              3'b101: $display("Instrução ID  %b  -  SRLI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_instr[24:20]);
            endcase
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

          7'b0110111: $display("Instrução ID  %b  -  LUI x%0d, %0d", uut.ID_rd, uut.ID_imm);
          7'b0010111: $display("Instrução ID  %b  -  AUIPC x%0d, %0d", uut.ID_rd, uut.ID_imm);
          default: $display("Instrução ID  %b", uut.ID_instr);
        endcase

        case(uut.EX_opcode)
          7'b0110011: begin // R-Type
              case (uut.EX_instr[31:25])
                7'b0000000:begin $display("Instrução EX  %b  -  ADD x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_r1, uut.EX_r2); end
                7'b0000001:begin $display("Instrução EX  %b  -  MUL x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_r1, uut.EX_r2); end
                7'b0100000:begin $display("Instrução EX  %b  -  SUB x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_r1, uut.EX_r2); end
              endcase
            end
          7'b0100011:begin
            $display("Instrução EX  %b  -  SW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[24:20], uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução EX  %b  -  LW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[11:7], uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.EX_funct3)
              3'b001: $display("Instrução EX  %b  -  SLLI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_instr[24:20]);
              3'b101: $display("Instrução EX  %b  -  SRLI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_instr[24:20]);
              3'b000: $display("Instrução EX  %b  -  ADDI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_imm);
            endcase
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
          7'b0110111: $display("Instrução EX  %b  -  LUI x%0d, %0d", uut.EX_rd, uut.EX_imm);
          7'b0010111: $display("Instrução EX  %b  -  AUIPC x%0d, %0d", uut.EX_rd, uut.EX_imm);
          default: $display("Instrução EX  %b", uut.EX_instr);
        endcase

        case(uut.MEM_opcode)
          
          7'b0110011: begin // R-Type
              case (uut.MEM_instr[31:25])
                7'b0000000:begin $display("Instrução MEM  %b  -  ADD x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_r1, MEM_r2); end
                7'b0000001:begin $display("Instrução MEM  %b  -  MUL x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_r1, MEM_r2); end
                7'b0100000:begin $display("Instrução MEM  %b  -  SUB x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_r1, MEM_r2); end
              endcase
            end
          7'b0100011:begin
            $display("Instrução MEM  %b  -  SW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[24:20], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução MEM  %b  -  LW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.MEM_instr[14:12])
              3'b001: $display("Instrução MEM  %b  -  SLLI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], uut.EX_instr[24:20]);
              3'b101: $display("Instrução MEM  %b  -  SRLI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], uut.EX_instr[24:20]);
              3'b000: $display("Instrução MEM  %b  -  ADDI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], MEM_imm);
            endcase
          end
          7'b1100111: begin
            $display("Instrução MEM  %b  -  JALR x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b1100011:
            case (uut.MEM_instr[14:12])
              3'b101: begin
                $display("Instrução MEM  %b  -  BGE x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
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
          7'b0110111: $display("Instrução MEM  %b  -  LUI x%0d, %0d", uut.MEM_rd, uut.MEM_data);
          7'b0010111: $display("Instrução MEM  %b  -  AUIPC x%0d, %0d", uut.MEM_rd, uut.MEM_data);
          default: $display("Instrução MEM  %b", uut.MEM_instr);
        endcase

        case(uut.WB_instr[6:0])
          7'b0110011: begin // R-Type
            case (uut.WB_instr[31:25])
              7'b0000000:begin $display("Instrução WB  %b  -  ADD x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, WB_r1, WB_r2); end
              7'b0000001:begin $display("Instrução WB  %b  -  MUL x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, WB_r1, WB_r2); end
              7'b0100000:begin $display("Instrução WB  %b  -  SUB x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, WB_r1, WB_r2); end
            endcase
          end
          7'b0100011:begin
            $display("Instrução WB  %b  -  SW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[24:20], WB_imm, uut.WB_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrução WB  %b  -  LW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[11:7], WB_imm, uut.WB_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.WB_instr[14:12])
              3'b001: $display("Instrução WB  %b  -  SLLI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], uut.EX_instr[24:20]);
              3'b101: $display("Instrução WB  %b  -  SRLI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], uut.EX_instr[24:20]);
              3'b000: $display("Instrução WB  %b  -  ADDI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], WB_imm);
            endcase
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
          7'b0110111: $display("Instrução WB  %b  -  LUI x%0d, %0d", uut.WB_rd, uut.WB_data);
          7'b0010111: $display("Instrução WB  %b  -  AUIPC x%0d, %0d", uut.WB_rd, uut.WB_data);
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
