`timescale 1ns / 1ps

// Testbench para o pipeline RISC-V completo
module tb_pipeline;

  // sinais de estímulo
  reg         clock;
  reg         reset;
  integer     pc_anterior;

  // instanciação do DUT (Device Under Test)
  RISCV_Pipeline uut (
    .clock(clock),
    .reset(reset)
  );

  //==================================================================
  // 1) Geração do clock: período de 10 ns (50 MHz)
  //==================================================================
  initial begin
    clock = 0;
    forever #5 clock = ~clock;
  end

  //==================================================================
  // 2) Sequência de reset e fim de simulação
  //==================================================================
  initial begin
    $display("=== Iniciando simulação ===");
    reset = 1;
    #10 reset = 0;        // libera o reset após 10 ns

    // aguarda 400 ns para executar instruções do programa
    #400;

    $display("\n=== Fim da simulação ===");
    $finish;
  end

  //==================================================================
  // 3) Monitoramento do pipeline a cada ciclo de clock
  //==================================================================
  initial begin
    // aguarda término do reset
    @(negedge reset);
    pc_anterior = 0;

    forever begin
      @(posedge clock);
      // detecta mudança de PC
      if (uut.PC !== pc_anterior) begin
        $display("PC mudou: %0d -> %0d", pc_anterior, uut.PC);
      end

      // exibe instrução que está em cada estágio
      $display(" IF_stage instr = %b", uut.IF_instr);
      $display(" ID_stage instr = %b", uut.ID_instr);
      $display(" EX_stage instr = %b", uut.EX_instr);

      // detecta e reporta branches na etapa ID
      if (uut.ID_instr[6:0] == 7'b1100011) begin
        if (uut.ID_instr[14:12] == 3'b101)
          $display("  [ID] Branch BGE detectado");
        else if (uut.ID_instr[14:12] == 3'b100)
          $display("  [ID] Branch BLT detectado");

        // mostra operandos da ULA (com forwarding)
        $display("  Comparando rs1=%0d  rs2=%0d",
                 uut.alu_u.alu_in1,
                 uut.alu_u.alu_in2);
        $display("  Branch tomado? %s", uut.branch_taken ? "SIM" : "NAO");
        $display("  Alvo do branch = %0d\n", uut.branch_target);
      end

      pc_anterior = uut.PC;
    end
  end

endmodule
