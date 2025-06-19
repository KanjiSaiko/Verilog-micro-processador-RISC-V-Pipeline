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
    #20;       // mantém reset alto por 20 ns
    reset = 0;
  end

  // Bloco de preload e imprimir informações a cada ciclo
  initial begin
      // aguarda sair do reset
      wait (reset == 0);
      // um ciclo para o DUT “acordar”
      @(posedge clock);

      // carrega os 4 valores que você quer ordenar:
      uut.data_mem[0] = 32'd42;
      uut.data_mem[1] = 32'd17;
      uut.data_mem[2] = 32'd93;
      uut.data_mem[3] = 32'd58;
 

      // Parâmetros iniciais
      // Vamos ordenar 4 elementos de 32 bits.
      uut.banco_regs[14] = 32'd1;
      // i=0
      uut.instr_mem[0] = 32'b00000000000000000000001000010011; // addi x10,x0,0  → endereço base do array (em bytes)
      uut.instr_mem[1] = 32'b00000000100000000001001000010011; // addi x11,x0,16 → endereço base do buffer temporário(4*4 bytes)
      uut.instr_mem[2] = 32'b00000000010000000001100000010011; // addi x12,x0,4  → constante 4 (para offset ×4)

      // merge [0,1]
      uut.instr_mem[3] = 32'b00000000000001101000001110000011; // lw  x15,0(x13)  (aguardando x13=0)
      uut.instr_mem[4] = 32'b00000000000000000011001100010011; // addi x13,x0,0
      uut.instr_mem[5] = 32'b00000000000100110001010010110011; // mul  x13,x13,x12
      uut.instr_mem[6] = 32'b00000000000000110100101010110011; // mul  x14,x14,x12  (pré-carregar x14=1 em TB)
      uut.instr_mem[7] = 32'b00000000110101010010101000110011; // add  x13,x10,x13
      uut.instr_mem[8] = 32'b00000000111001010100101000110011; // add  x14,x10,x14
      uut.instr_mem[9] = 32'b00000000000001101000010000000011; // lw   x16,0(x13)
      uut.instr_mem[10] = 32'b00000000000001111000010100000011; // lw   x17,0(x14)
      uut.instr_mem[11] = 32'b00000000100001110100010001100011; // blt  x15,x16,+8
      uut.instr_mem[12] = 32'b00000010000101100010010000100011; // sw   x16,0(x11)
      uut.instr_mem[13] = 32'b00000000010001100010010010010011; // addi x11,x11,4
      uut.instr_mem[14] = 32'b00000000000001101000001100100011; // sw   x15,0(x11)
      uut.instr_mem[15] = 32'b00000000010001100010010010010011; // addi x11,x11,4
      uut.instr_mem[16] = 32'b00000000010000000000000001101111; // jal  x0,+4
      uut.instr_mem[17] = 32'b00000000000001101000001100100011; // sw   x15,0(x11)
      uut.instr_mem[18] = 32'b00000000010001100010010010010011; // addi x11,x11,4

      // merge [2,3] — cargas de índices em TB: x13=2, x14=3
      uut.instr_mem[19] = 32'b00000000001000000011001100010011; // addi x13,x0,2
      uut.instr_mem[20] = 32'b00000000001100000011100100010011; // addi x14,x0,3
      uut.instr_mem[21] = 32'b00000000000100110001010010110011; // mul   x13,x13,x12
      uut.instr_mem[22] = 32'b00000000001000100001101010110011; // mul   x14,x14,x12
      uut.instr_mem[23] = 32'b00000000110101010010101000110011; // add   x13,x10,x13
      uut.instr_mem[24] = 32'b00000000111001010100101000110011; // add   x14,x10,x14
      uut.instr_mem[25] = 32'b00000000000001101000010000000011; // lw    x16,0(x13)
      uut.instr_mem[26] = 32'b00000000000001111000010100000011; // lw    x17,0(x14)
      uut.instr_mem[27] = 32'b00000000100001110100010001100011; // blt   x16,x17,+8
      uut.instr_mem[28] = 32'b00000010000101100010010000100011; // sw    x17,0(x11)
      uut.instr_mem[29] = 32'b00000000010001100010010010010011; // addi  x11,x11,4
      uut.instr_mem[30] = 32'b00000000000001101000001100100011; // sw    x16,0(x11)
      uut.instr_mem[31] = 32'b00000000010001100010010010010011; // addi  x11,x11,4

      // copy-back (unrolled)
      uut.instr_mem[32] = 32'b00000000100000000100001100010011; // addi x17,x0,16
      uut.instr_mem[33] = 32'b00000000000000000011001100010011; // addi x13,x0,0
      uut.instr_mem[34] = 32'b00000000000010001000010000000011; // lw   x15,0(x17)
      uut.instr_mem[35] = 32'b00000000000001010010000000100011; // sw   x15,0(x13)
      uut.instr_mem[36] = 32'b00000000010010001000010010010011; // addi x17,x17,4
      uut.instr_mem[37] = 32'b00000000010001010010010010010011; // addi x13,x13,4
      uut.instr_mem[38] = 32'b00000000000010001000010000000011; // lw   x15,0(x17)
      uut.instr_mem[39] = 32'b00000000000001010010000000100011; // sw   x15,0(x13)
      uut.instr_mem[40] = 32'b00000000010010001000010010010011; // addi x17,x17,4
      uut.instr_mem[41] = 32'b00000000010001010010010010010011; // addi x13,x13,4

      // fim
      uut.instr_mem[42] = 32'b00000000000000000000000001101111; // jal x0,0


      uut.instr_mem[43] = 32'b0;

      pc_anterior = 32'b0;
      forever begin
          @(posedge clock);
          if(reset == 0)begin
                $display("\nPC alterado de %d para %d", pc_anterior, uut.PC);
                $display("Instrução IF  %b", uut.IF_instr);
                $display("Instrução ID  %b", uut.ID_instr);
                $display("Instrução EX  %b", uut.EX_instr);
                $display("Instrução MEM %b", uut.MEM_instr);
                $display("Instrução WB  %b", uut.WB_instr);
            pc_anterior = uut.PC;
                $display("----------------------------------");
                $display("data_mem[0] = %0d", uut.data_mem[0]);
                $display("data_mem[1] = %0d", uut.data_mem[1]);
                $display("data_mem[2] = %0d", uut.data_mem[2]);
                $display("data_mem[3] = %0d", uut.data_mem[3]);
                $display("----------------------------------");
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
    for (i = 0; i < 4; i = i + 1)
      $display("data_mem[%0d] = %0d", i, uut.data_mem[i]);

    $finish;
  end


endmodule
