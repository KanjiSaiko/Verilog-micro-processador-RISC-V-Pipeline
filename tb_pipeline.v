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


      // registradores no seu módulo pipeline:
      uut.banco_regs[10] = 32'd0;   // x10 = 0   → endereço base do array (em bytes)
      uut.banco_regs[11] = 32'd16;  // x11 = 16  → endereço base do buffer temporário(4*4 bytes)

      // Parâmetros iniciais
      // Vamos ordenar 4 elementos de 32 bits.

      // width = 1
      uut.instr_mem[0] = 32'b00000000000100000000011000010011; // addi x12,x0,1

    // Outer: if (width >= 4) goto done
      // bge x12, x13(=4), done
      uut.instr_mem[1] = 32'b00000000010001100101000001100011; // bge x12,x13, +8

      // i = 0
      uut.instr_mem[2] = 32'b00000000000000000000011010010011; // addi x13,x0,0

    // Inner:
      // blt i, 4, merge
      uut.instr_mem[3] = 32'b00000000100001100100000101100011; // blt x13,x13, +8
      // j up_width
      uut.instr_mem[4] = 32'b00000000000100000000000001101111; // jal x0, +4

    // merge:
      // mid = i + width
      uut.instr_mem[5] = 32'b00000000010001110100000010110011; // add  x14,x13,x12
      // lptr = base + i*4
      uut.instr_mem[6] = 32'b00000000010001101100001010100011; // slli x16,x13,2
      uut.instr_mem[7] = 32'b00000010000001010010001000110011; // add  x16,x10,x16
      // mptr = base + mid*4
      uut.instr_mem[8] = 32'b00000000100001111100001010100011; // slli x17,x14,2
      uut.instr_mem[9] = 32'b00000100000001010010001000110011; // add  x17,x10,x17
      // k = 0
      uut.instr_mem[10]= 32'b00000000000000000000111100010011; // addi x15,x0,0

    // merge_loop:
      // beq k,width, copy_back
      uut.instr_mem[11]= 32'b00000001110001110110001101100011; // beq x15,x12, +8
      // lw   t0,0(lptr)
      uut.instr_mem[12]= 32'b00000000000010001110010000000011; // lw   x14,0(x16)
      // lw   t1,0(mptr)
      uut.instr_mem[13]= 32'b00000000000010010100010000000011; // lw   x16,0(x17)
      // blt  t0,t1, store_l
      uut.instr_mem[14]= 32'b00000000110010010100010101100011; // blt x14,x16, +8
      // store_r: sw t1,0(tmp)
      uut.instr_mem[15]= 32'b00000010000001100010010000100011; // sw   x16,0(x11)
      // addi mptr,mptr,4
      uut.instr_mem[16]= 32'b00000000010010010110010010010011; // addi x17,x17,4
      // j merge_inc
      uut.instr_mem[17]= 32'b00000000000100000000000001101111; // jal x0, +4

    // store_l:
      uut.instr_mem[18]= 32'b00000000000001110100010000100011; // sw   x14,0(x11)
    // merge_inc:
      // addi tmp,tmp,4
      uut.instr_mem[19]= 32'b00000000010001011110010110010011; // addi x11,x11,4
      // addi k,k,1
      uut.instr_mem[20]= 32'b00000000000101111110010100010011; // addi x15,x15,1
      // j merge_loop
      uut.instr_mem[21]= 32'b11111111100000000000000011101111; // jal x0, -8

    // copy_back:
      uut.instr_mem[22]= 32'b00000000000000000000111100010011; // addi x15,x0,0
      // copy_loop:
      // beq k,width, up_i
      uut.instr_mem[23]= 32'b00000001110001110110001101100011; // beq x15,x12, +8
      // lw   t0,0(tmp)
      uut.instr_mem[24]= 32'b00000000000010111000010000000011; // lw   x14,0(x11)
      // sw   t0,0(base+i*4)
      uut.instr_mem[25]= 32'b00000000000010001110001000100011; // sw   x14,0(x10)
      // addi tmp,tmp,4
      uut.instr_mem[26]= 32'b00000000010001011110010110010011; // addi x11,x11,4
      // slli t2,k,2
      uut.instr_mem[27]= 32'b00000000010001111100001010100011; // slli x17,x15,2
      // add  ptr,base, t2
      uut.instr_mem[28]= 32'b00000100000001011010001000110011; // add  x17,x10,x17
      // addi k,k,1
      uut.instr_mem[29]= 32'b00000000000101111110010100010011; // addi x15,x15,1
      // jal x0, -32 (copy_loop)
      uut.instr_mem[30]= 32'b11111100000000000000000011101111; // jal x0, -32

    // up_i:
      uut.instr_mem[31]= 32'b00000000100001100100110100010011; // addi x13,x13,2

    // up_width:
      uut.instr_mem[32]= 32'b00000000000101100101011000100011; // slli x12,x12,1

      // jal back to outer
      uut.instr_mem[33]= 32'b11111110000000000000000011101111; // jal x0, -52

    // done:
      uut.instr_mem[34]= 32'b00000000000000000000000001101111; // jal x0,0
      uut.instr_mem[35] = 32'b0;

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
