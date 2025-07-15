`timescale 1ns / 1ns

module tb_pipeline;

  reg clock;
  reg reset;
  integer    i;
  // Instância do módulo principal
  RISCV_Pipeline uut (
    .clock(clock),
    .reset(reset)
  );

  reg [31:0] block_base_addr;
  reg [9:0]  index0, index1, index2, index3;
  reg [127:0] bloco_de_dados;
  reg [4:0]  cache_index_miss;
  reg [22:0] cache_tag_miss;
  reg [31:0] endereco_miss;

  reg [4:0]  dado_cache_index;
  reg [22:0] dado_cache_tag;
  reg [31:0] dado_da_memoria;
  reg [4:0]  dado_cache_index_escrita;

  //––––––––––––––––––––––––––––––––––––––––––––––––––––––
  // 1) Geracao de clock
  initial begin
    clock = 0;
    forever #5 clock = ~clock;  // 10 ns de período
  end

  //––––––––––––––––––––––––––––––––––––––––––––––––––––––
  // 2) Pulso de reset
  initial begin
    reset = 1;
    for(i=0;i<1023;i=i+1)begin
      uut.memoria_dados[i] <= 0;
      uut.memoria_instrucoes[i] <= 0;
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
     //  uut.banco_regs[2] = 255 * 4; // Aponta para o endereço logo após o fim da memória
      // carrega os 4 valores que você quer ordenar:
      uut.memoria_dados[0] = 32'd167;
      uut.memoria_dados[1] = 32'd165;
      uut.memoria_dados[2] = 32'd186;
      uut.memoria_dados[3] = 32'd172;
      uut.memoria_dados[4] = 32'd94;
      uut.memoria_dados[5] = 32'd27;
      uut.memoria_dados[6] = 32'd60;
      uut.memoria_dados[7] = 32'd35;
      uut.memoria_dados[8] = 32'd13;
      uut.memoria_dados[9] = 32'd15;
      uut.memoria_dados[10] = 32'd79;
      uut.memoria_dados[11] = 32'd170;
      uut.memoria_dados[12] = 32'd106;
      uut.memoria_dados[13] = 32'd59;
      uut.memoria_dados[14] = 32'd190;
      uut.memoria_dados[15] = 32'd136;
      uut.memoria_dados[16] = 32'd196;
      uut.memoria_dados[17] = 32'd159;
      uut.memoria_dados[18] = 32'd59;
      uut.memoria_dados[19] = 32'd137;
      uut.memoria_dados[20] = 32'd49;
      uut.memoria_dados[21] = 32'd142;
      uut.memoria_dados[22] = 32'd86;
      uut.memoria_dados[23] = 32'd123;
      uut.memoria_dados[24] = 32'd102;
      uut.memoria_dados[25] = 32'd11;
      uut.memoria_dados[26] = 32'd8;
      uut.memoria_dados[27] = 32'd25;
      uut.memoria_dados[28] = 32'd71;
      uut.memoria_dados[29] = 32'd199;
      uut.memoria_dados[30] = 32'd40;
      uut.memoria_dados[31] = 32'd146;
      uut.memoria_dados[32] = 32'd138;
      uut.memoria_dados[33] = 32'd195;
      uut.memoria_dados[34] = 32'd19;
      uut.memoria_dados[35] = 32'd14;
      uut.memoria_dados[36] = 32'd170;
      uut.memoria_dados[37] = 32'd138;
      uut.memoria_dados[38] = 32'd88;
      uut.memoria_dados[39] = 32'd15;
      uut.memoria_dados[40] = 32'd104;
      uut.memoria_dados[41] = 32'd52;
      uut.memoria_dados[42] = 32'd156;
      uut.memoria_dados[43] = 32'd105;
      uut.memoria_dados[44] = 32'd54;
      uut.memoria_dados[45] = 32'd99;
      uut.memoria_dados[46] = 32'd65;
      uut.memoria_dados[47] = 32'd151;
      uut.memoria_dados[48] = 32'd6;
      uut.memoria_dados[49] = 32'd73;
      // Algoritmo Mergesort para 4 elementos
      // Formato: uut.memoria_instrucoes[index] = 32'b...;
      // --- Código de Máquina ---
      // --- Dados Iniciais (Exemplo) ---
      // main
      uut.memoria_instrucoes[0] = 32'h03200a13; // addi	x20,zero,50 
      uut.memoria_instrucoes[1] = 32'h00100293; // addi	x5,zero,1
      // width_loop
      uut.memoria_instrucoes[2] = 32'h1142d463; // bge	x5,x20,110 <done>
      uut.memoria_instrucoes[3] = 32'h00000313; // addi	x6,zero,0
      // i_loop
      uut.memoria_instrucoes[4] = 32'h0f435c63; // bge	x6,x20,108 <after_i_loop>
      uut.memoria_instrucoes[5] = 32'h005303b3; // add	x7,x6,x5
      uut.memoria_instrucoes[6] = 32'h0143d463; // bge	x7,x20,20 <mid_eq_N>
      uut.memoria_instrucoes[7] = 32'h0080006f; // jal	zero,24 <conx6>
      // mid_eq_N
      uut.memoria_instrucoes[8] = 32'h000a03b3; // add	x7,x20,zero
      // conx6
      uut.memoria_instrucoes[9] = 32'h00129893; // slli	x17,x5,0x1
      uut.memoria_instrucoes[10] = 32'h01130433; // add	x8,x6,x17
      uut.memoria_instrucoes[11] = 32'h01445463; // bge	x8,x20,34 <end_eq_N>
      uut.memoria_instrucoes[12] = 32'h0080006f; // jal	zero,38 <conx7>
      // end_eq_N
      uut.memoria_instrucoes[13] = 32'h000a0433; // add	x8,x20,zero
      // conx7
      uut.memoria_instrucoes[14] = 32'h0c83d463; // bge	x7,x8,100 <after_merge>
      uut.memoria_instrucoes[15] = 32'h000304b3; // add	x9,x6,zero
      uut.memoria_instrucoes[16] = 32'h00038533; // add	x10,x7,zero
      uut.memoria_instrucoes[17] = 32'h000305b3; // add	x11,x6,zero
      // merge_loop
      uut.memoria_instrucoes[18] = 32'h0474d663; // bge	x9,x7,94 <merge_left_loop>
      uut.memoria_instrucoes[19] = 32'h04855463; // bge	x10,x8,94 <merge_left_loop>
      uut.memoria_instrucoes[20] = 32'h00249913; // slli	x18,x9,0x2
      uut.memoria_instrucoes[21] = 32'h00092603; // lw	x12,0(x18)
      uut.memoria_instrucoes[22] = 32'h00251993; // slli	x19,x10,0x2
      uut.memoria_instrucoes[23] = 32'h0009a683; // lw	x13,0(x19)
      uut.memoria_instrucoes[24] = 32'h00d64e63; // blt	x12,x13,7c <left_smaller>
      // right_smaller
      uut.memoria_instrucoes[25] = 32'h01458ab3; // add	x21,x11,x20
      uut.memoria_instrucoes[26] = 32'h002a9b13; // slli	x22,x21,0x2
      uut.memoria_instrucoes[27] = 32'h00db2023; // sw	x13,0(x22)
      uut.memoria_instrucoes[28] = 32'h00158593; // addi	x11,x11,1
      uut.memoria_instrucoes[29] = 32'h00150513; // addi	x10,x10,1
      uut.memoria_instrucoes[30] = 32'hfd1ff06f; // jal	zero,48 <merge_loop>
      // left_smaller
      uut.memoria_instrucoes[31] = 32'h01458ab3; // add	x21,x11,x20
      uut.memoria_instrucoes[32] = 32'h002a9b13; // slli	x22,x21,0x2
      uut.memoria_instrucoes[33] = 32'h00cb2023; // sw	x12,0(x22)
      uut.memoria_instrucoes[34] = 32'h00158593; // addi	x11,x11,1
      uut.memoria_instrucoes[35] = 32'h00148493; // addi	x9,x9,1
      uut.memoria_instrucoes[36] = 32'hfb9ff06f; // jal	zero,48 <merge_loop>
      // merge_left_loop
      uut.memoria_instrucoes[37] = 32'h0274d263; // bge	x9,x7,b8 <copy_right_remaining>
      uut.memoria_instrucoes[38] = 32'h00249913; // slli	x18,x9,0x2
      uut.memoria_instrucoes[39] = 32'h00092603; // lw	x12,0(x18)
      uut.memoria_instrucoes[40] = 32'h01458ab3; // add	x21,x11,x20
      uut.memoria_instrucoes[41] = 32'h002a9b13; // slli	x22,x21,0x2
      uut.memoria_instrucoes[42] = 32'h00cb2023; // sw	x12,0(x22)
      uut.memoria_instrucoes[43] = 32'h00158593; // addi	x11,x11,1
      uut.memoria_instrucoes[44] = 32'h00148493; // addi	x9,x9,1
      uut.memoria_instrucoes[45] = 32'hfe1ff06f; // jal	zero,94 <merge_left_loop>
      // copy_right_remaining
      uut.memoria_instrucoes[46] = 32'h02855263; // bge	x10,x8,dc <copy_back>
      uut.memoria_instrucoes[47] = 32'h00251993; // slli	x19,x10,0x2
      uut.memoria_instrucoes[48] = 32'h0009a683; // lw	x13,0(x19)
      uut.memoria_instrucoes[49] = 32'h01458ab3; // add	x21,x11,x20
      uut.memoria_instrucoes[50] = 32'h002a9b13; // slli	x22,x21,0x2
      uut.memoria_instrucoes[51] = 32'h00db2023; // sw	x13,0(x22)
      uut.memoria_instrucoes[52] = 32'h00158593; // addi	x11,x11,1
      uut.memoria_instrucoes[53] = 32'h00150513; // addi	x10,x10,1
      uut.memoria_instrucoes[54] = 32'hfe1ff06f; // jal	zero,b8 <copy_right_remaining>
      // copy_back
      uut.memoria_instrucoes[55] = 32'h00030bb3; // add	x23,x6,zero
      // copy_back_loop
      uut.memoria_instrucoes[56] = 32'h028bd063; // bge	x23,x8,100 <after_merge>
      uut.memoria_instrucoes[57] = 32'h014b8ab3; // add	x21,x23,x20
      uut.memoria_instrucoes[58] = 32'h002a9b13; // slli	x22,x21,0x2
      uut.memoria_instrucoes[59] = 32'h000b2c03; // lw	x24,0(x22)
      uut.memoria_instrucoes[60] = 32'h002b9c93; // slli	x25,x23,0x2
      uut.memoria_instrucoes[61] = 32'h018ca023; // sw	x24,0(x25)
      uut.memoria_instrucoes[62] = 32'h001b8b93; // addi	x23,x23,1
      uut.memoria_instrucoes[63] = 32'hfe5ff06f; // jal zero,e0 <copy_back_loop>
      // after_merge
      uut.memoria_instrucoes[64] = 32'h01130333; // add	x6,x6,x17
      uut.memoria_instrucoes[65] = 32'hf0dff06f; // jal	zero,10 <i_loop>
      // after_i_loop
      uut.memoria_instrucoes[66] = 32'h00129293; // slli	x5,x5,0x1
      uut.memoria_instrucoes[67] = 32'hefdff06f; // jal	zero,8 <width_loop>
      // done
      uut.memoria_instrucoes[68] = 32'h000000ef; // jal	ra,110 <done>
  end



  // Lógica de Simulação do Atraso da Cache (o "cérebro" do testbench)
  always @(posedge clock) begin
    if(!reset)begin
      if(uut.stall_cache_instrucoes && uut.stall_cache_dados)begin
        $display("Cache de Instruçoes e dados - MISS no PC = %0d. Simulando latencia...", uut.PC);
        //Espera de 4 ciclos de clock (1 para detectar + 3 de espera)
        repeat (3) @(posedge clock);
        $display("Latencia de 3 ciclos concluida. Preenchendo a cache...");
        // --- Lógica de preenchimento da CACHE DE INSTRUÇÕES ---
        block_base_addr = {uut.PC[31:4], 4'b0000};
        index0 = block_base_addr >> 2;
        index1 = (block_base_addr + 4) >> 2;
        index2 = (block_base_addr + 8) >> 2;
        index3 = (block_base_addr + 12) >> 2;

        bloco_de_dados = {uut.memoria_instrucoes[index3], uut.memoria_instrucoes[index2],
                          uut.memoria_instrucoes[index1], uut.memoria_instrucoes[index0]};

        cache_index_miss = uut.PC[8:4];
        cache_tag_miss   = uut.PC[31:9];

        uut.u_cacheInst.instr_cache_data[cache_index_miss]  <= bloco_de_dados;
        uut.u_cacheInst.instr_cache_tag[cache_index_miss]   <= cache_tag_miss;
        uut.u_cacheInst.instr_cache_valid[cache_index_miss] <= 1'b1;

        $display("Cache de Instruções preenchida para o índice %0d.",cache_index_miss);

        // --- Lógica de preenchimento da CACHE DE DADOS ---
        block_base_addr = {uut.EXMEM_AluOut[31:4], 4'b0000};
        index0 = block_base_addr >> 2;
        index1 = (block_base_addr + 4) >> 2;
        index2 = (block_base_addr + 8) >> 2;
        index3 = (block_base_addr + 12) >> 2;

        bloco_de_dados = {uut.memoria_dados[index3], uut.memoria_dados[index2],
                          uut.memoria_dados[index1], uut.memoria_dados[index0]};

        endereco_miss    = uut.EXMEM_AluOut;
        dado_cache_index = endereco_miss[8:4];
        dado_cache_tag   = endereco_miss[31:9];

        uut.u_cacheDados.data_cache_data[dado_cache_index] <= bloco_de_dados;
        uut.u_cacheDados.data_cache_tag[dado_cache_index]  <= dado_cache_tag;
        uut.u_cacheDados.data_cache_valid[dado_cache_index]<= 1'b1;

        $display("Cache de Dados preenchida para o índice %0d. Pipeline vai continuar.", dado_cache_index);
      end else if (uut.stall_cache_instrucoes) begin
        $display("Cache de Instruçoes - MISS no PC = %0d. Simulando latencia...", uut.PC);
        repeat (3) @(posedge clock);
        $display("Latencia de 3 ciclos concluida. Preenchendo a cache...");
        //Preparar os dados para preencher a cache
        block_base_addr = {uut.PC[31:4], 4'b0000};
        
        index0 = block_base_addr >> 2;
        index1 = (block_base_addr + 4)>>2;
        index2 = (block_base_addr + 8)>>2;
        index3 = (block_base_addr + 12)>>2;

        // Monta o bloco de 128 bits (16 bytes)
        bloco_de_dados = {uut.memoria_instrucoes[index3], uut.memoria_instrucoes[index2], 
                          uut.memoria_instrucoes[index1], uut.memoria_instrucoes[index0]};

        // Preencher a cache
        cache_index_miss = uut.PC[8:4];
        cache_tag_miss   = uut.PC[31:9];

        uut.u_cacheInst.instr_cache_data[cache_index_miss]  <= bloco_de_dados;
        uut.u_cacheInst.instr_cache_tag[cache_index_miss]   <= cache_tag_miss;
        uut.u_cacheInst.instr_cache_valid[cache_index_miss] <= 1'b1;

        $display("Cache de Instrucoes preenchida para o indice %0d com a tag %0d. Pipeline vai continuar.", cache_index_miss, cache_tag_miss);
      // --- MISS DE CACHE DE DADOS ---
      end else if (uut.stall_cache_dados) begin
        $display("Cache de Dados - MISS no PC = %0d. Simulando latencia...", uut.PC);
        repeat (3) @(posedge clock);
        $display("Latencia de 3 ciclos concluida. Preenchendo a cache...");

        block_base_addr = {uut.EXMEM_AluOut[31:4], 4'b0000};
              
        // Índices das 4 palavras na memória do TB
        index0 = block_base_addr >> 2;
        index1 = (block_base_addr + 4) >> 2;
        index2 = (block_base_addr + 8) >> 2;
        index3 = (block_base_addr + 12) >> 2;
        
        // Lê o dado da memória
        bloco_de_dados = {uut.memoria_dados[index3], uut.memoria_dados[index2], 
                          uut.memoria_dados[index1], uut.memoria_dados[index0]};

        endereco_miss = uut.EXMEM_AluOut;
        // O índice e a tag agora são calculados
        dado_cache_index = endereco_miss[8:4];  // 5 bits
        dado_cache_tag   = endereco_miss[31:9]; // 23 bits

        // Preenche a cache de dados
        uut.u_cacheDados.data_cache_data[dado_cache_index] <= bloco_de_dados;
        uut.u_cacheDados.data_cache_tag[dado_cache_index]  <= dado_cache_tag;
        uut.u_cacheDados.data_cache_valid[dado_cache_index]<= 1'b1;

        $display("dado_1 do bloco na cache: %0d || dado_2 do bloco na cache: %0d || dado_3 do bloco na cache: %0d || dado_4 do bloco na cache: %0d", 
            uut.u_cacheDados.endereco, uut.u_cacheDados.cache_index, uut.u_cacheDados.cache_tag_addr, uut.u_cacheDados.data_cache_data[uut.u_cacheDados.cache_index][31:0],
            uut.u_cacheDados.data_cache_data[uut.u_cacheDados.cache_index][63:32], uut.u_cacheDados.data_cache_data[uut.u_cacheDados.cache_index][95:64], uut.u_cacheDados.data_cache_data[uut.u_cacheDados.cache_index][127:96]);
        $display("Cache de Dados preenchida para o indice %0d. Pipeline vai continuar.", dado_cache_index);
      end
    end
  end

    // Lógica separada para ESCRITA na memória (Store Word)
  always @(posedge clock) begin
    if (!reset && uut.EXMEM_MemWrite) begin
      // SW não para o pipeline, mas o testbench precisa atualizar sua memória
      $display("Store Word detectado. Escrevendo %0d no endereço %0d da memória.", uut.EXMEM_WriteData, uut.EXMEM_AluOut);
      uut.memoria_dados[uut.EXMEM_AluOut >> 2] = uut.EXMEM_WriteData;

      // Política de escrita: Invalida a linha correspondente na cache de dados, se houver
      // Isso evita que o processador leia um dado velho da cache após uma escrita
      dado_cache_index_escrita = uut.EXMEM_AluOut[8:4];

      // Apenas invalida se o endereço bater
      if (uut.u_cacheDados.data_cache_valid[dado_cache_index_escrita] && uut.u_cacheDados.data_cache_tag[dado_cache_index_escrita] == uut.EXMEM_AluOut[31:9]) begin
            uut.u_cacheDados.data_cache_valid[dado_cache_index_escrita] = 1'b0;
            $display("Linha %d da cache de dados invalidada devido a escrita.", dado_cache_index_escrita);
      end
    end
  end

  wire signed [31:0] extended_I_TYPE = $signed(uut.IFID_instr[31:20]);
  wire signed [31:0] extended_B_TYPE = $signed({{20{uut.IFID_instr[31]}}, uut.IFID_instr[7], uut.IFID_instr[30:25], uut.IFID_instr[11:8], 1'b0});
  wire signed [31:0] extended_S_TYPE = $signed({uut.IFID_instr[31:25], uut.IFID_instr[11:7]});
  wire signed [31:0] extended_J_TYPE = $signed({uut.IFID_instr[31], uut.IFID_instr[19:12], uut.IFID_instr[20], uut.IFID_instr[30:21], 1'b0});
  reg signed [31:0] EXMEM_imm, MEMWB_imm, WB_imm, WB_instr, WB_data;
  reg [4:0] WB_rd;


  //PRINTANDO INSTRUCAO E ASSEMBLY
initial begin
  wait (reset == 0);
  forever begin
  @(posedge clock);
  if (reset == 1) begin
    WB_instr <= 0;
  end else if(reset == 0) begin
    EXMEM_imm <= uut.IDEX_imm;
    MEMWB_imm <= EXMEM_imm;
    WB_imm <= MEMWB_imm;
    WB_instr <= uut.MEMWB_instr;
    WB_rd <= uut.MEMWB_rd;
    WB_data <= uut.RegWriteData;
    $display("\n\n=================================== PC: %0d ===================================", uut.PC);
    // O estado da cache é a informação mais crucial agora

    $display("| HIT CACHE DE INSTRUCAO: %b | STALL CACHE DE INSTRUCAO: %b  ||  HIT CACHE DE DADOS: %b | STALL CACHE DE DADOS: %b |", 
              uut.u_cacheInst.cache_instr_hit, uut.stall_cache_instrucoes, 
              uut.u_cacheDados.cache_data_hit, uut.stall_cache_dados);
    case (uut.IFID_instr[6:0])
        7'b0110011: begin // R-Type
          // <--- INÍCIO DA MODIFICAÇÃO PARA O ESTÁGIO IF
          case (uut.IFID_instr[31:25]) // Checa o funct7
            7'b0000000: begin // funct7 para ADD, SLT, SLTU
              case (uut.IFID_instr[14:12]) // Checa o funct3
                3'b000: $display("Instrucao IF  %b  -  ADD x%0d, x%0d, x%0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], uut.IFID_instr[24:20]);
                3'b010: $display("Instrucao IF  %b  -  SLT x%0d, x%0d, x%0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], uut.IFID_instr[24:20]);
                3'b011: $display("Instrucao IF  %b  -  SLTU x%0d, x%0d, x%0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], uut.IFID_instr[24:20]);
              endcase
            end
            7'b0000001: $display("Instrucao IF  %b  -  MUL x%0d, x%0d, x%0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], uut.IFID_instr[24:20]);
            7'b0100000: $display("Instrucao IF  %b  -  SUB x%0d, x%0d, x%0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], uut.IFID_instr[24:20]);
          endcase
          // <--- FIM DA MODIFICAÇÃO PARA O ESTÁGIO IF
        end
        7'b0100011:begin
          $display("Instrucao IF  %b  -  SW x%0d, %0d(x%0d)", uut.IFID_instr, uut.IFID_instr[24:20], extended_S_TYPE, uut.IFID_instr[19:15]);
        end
        7'b0000011: begin
          $display("Instrucao IF  %b  -  LW x%0d, %0d(x%0d)", uut.IFID_instr, uut.IFID_instr[11:7], extended_I_TYPE, uut.IFID_instr[19:15]);
        end
        7'b1100111:begin
          $display("Instrucao IF  %b  -  JALR x%0d, %0d(x%0d)", uut.IFID_instr, uut.IFID_instr[11:7], extended_I_TYPE, uut.IFID_instr[19:15]);
        end
        7'b0010011: begin
          case(uut.IFID_instr[14:12])
            3'b000: $display("Instrucao IF  %b  -  ADDI x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], extended_I_TYPE);
            3'b001: $display("Instrucao IF  %b  -  SLLI x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], uut.IFID_instr[24:20]);
            3'b101: $display("Instrucao IF  %b  -  SRLI x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], uut.IFID_instr[24:20]);
            3'b010: $display("Instrucao IF  %b  -  SLTI x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], extended_I_TYPE);
            3'b011: $display("Instrucao IF  %b  -  SLTIU x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[11:7], uut.IFID_instr[19:15], extended_I_TYPE);
          
          endcase
        end
        7'b1100011:begin //saltos
          case (uut.IFID_instr[14:12])
            3'b101: $display("Instrucao IF  %b  -  BGE x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[19:15], uut.IFID_instr[24:20], extended_B_TYPE);
            3'b100: $display("Instrucao IF  %b  -  BLT x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[19:15], uut.IFID_instr[24:20], extended_B_TYPE);
            3'b001: $display("Instrucao IF  %b  -  BNE x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[19:15], uut.IFID_instr[24:20], extended_B_TYPE);
            3'b000: $display("Instrucao IF  %b  -  BEQ x%0d, x%0d, %0d", uut.IFID_instr, uut.IFID_instr[19:15], uut.IFID_instr[24:20], extended_B_TYPE);
          endcase
        end
        7'b1101111: begin
          $display("Instrucao IF  %b  -  JAL x%0d, %0d", uut.IFID_instr, uut.IFID_instr[11:7], extended_J_TYPE);
        end
        7'b0110111: $display("Instrucao IF  %b  -  LUI x%0d, %0d", uut.IFID_instr, uut.IFID_instr[11:7], {uut.IFID_instr[31:12], 12'b0});
        7'b0010111: $display("Instrucao IF  %b  -  AUIPC x%0d, %0d", uut.IFID_instr, uut.IFID_instr[11:7], {uut.IFID_instr[31:12], 12'b0});
        default: $display("Instrucao IF  %b", uut.IFID_instr);
    endcase

    case(uut.IDEX_instr[6:0])
        7'b0110011: begin // R-Type
          // <--- INÍCIO DA MODIFICAÇÃO PARA O ESTÁGIO ID
          case (uut.IDEX_funct7)
            7'b0000000: begin
              case (uut.IDEX_funct3)
                3'b000: $display("Instrucao ID  %b  -  ADD x%0d, x%0d, x%0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_indiceR2);
                3'b010: $display("Instrucao ID  %b  -  SLT x%0d, x%0d, x%0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_indiceR2); 
                3'b011: $display("Instrucao ID  %b  -  SLTU x%0d, x%0d, x%0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_indiceR2); 
              endcase
            end
            7'b0000001: $display("Instrucao ID  %b  -  MUL x%0d, x%0d, x%0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_indiceR2);
            7'b0100000: $display("Instrucao ID  %b  -  SUB x%0d, x%0d, x%0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_indiceR2);
          endcase
          // <--- FIM DA MODIFICAÇÃO PARA O ESTÁGIO ID
        end
        7'b0100011:begin
          $display("Instrucao ID  %b  -  SW x%0d, %0d(x%0d)", uut.IDEX_instr, uut.IDEX_indiceR2, uut.IDEX_imm, uut.IDEX_indiceR1);
        end
        7'b0000011: begin
          $display("Instrucao ID  %b  -  LW x%0d, %0d(x%0d) (Endereco[%0d]: %0d)", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_imm, uut.IDEX_indiceR1, uut.alu_result>>2, uut.memoria_dados[uut.EXMEM_AluOut>>2]);
        end
        7'b0010011: begin
          case(uut.IDEX_funct3)
            3'b000: $display("Instrucao ID  %b  -  ADDI x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_imm);
            3'b001: $display("Instrucao ID  %b  -  SLLI x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_shamt);
            3'b101: $display("Instrucao ID  %b  -  SRLI x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_shamt);
            3'b010: $display("Instrucao ID  %b  -  SLTI x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_imm);
            3'b011: $display("Instrucao ID  %b  -  SLTIU x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_indiceR1, uut.IDEX_imm);
          endcase
        end
        7'b1100111: begin
          $display("Instrucao ID  %b  -  JALR x%0d, %0d(x%0d)", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_imm, uut.IDEX_indiceR1);
        end
        7'b1100011:
          case (uut.IDEX_funct3)
            3'b101: $display("Instrucao ID  %b  -  BGE x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_indiceR1, uut.IDEX_indiceR2, uut.IDEX_imm);
            3'b100: $display("Instrucao ID  %b  -  BLT x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_indiceR1, uut.IDEX_indiceR2, uut.IDEX_imm);
            3'b001: $display("Instrucao ID  %b  -  BNE x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_indiceR1, uut.IDEX_indiceR2, uut.IDEX_imm);
            3'b000: $display("Instrucao ID  %b  -  BEQ x%0d, x%0d, %0d", uut.IDEX_instr, uut.IDEX_indiceR1, uut.IDEX_indiceR2, uut.IDEX_imm);
          endcase
        7'b1101111: begin
          $display("Instrucao ID  %b  -  JAL x%0d, %0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_imm);
        end
        7'b0110111: $display("Instrucao ID  %b  -  LUI x%0d, %0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_imm);
        7'b0010111: $display("Instrucao ID  %b  -  AUIPC x%0d, %0d", uut.IDEX_instr, uut.IDEX_rd, uut.IDEX_imm);
        default: $display("Instrucao ID  %b", uut.IDEX_instr);
    endcase

    case(uut.EXMEM_instr[6:0])
        7'b0110011: begin // R-Type
          // <--- INÍCIO DA MODIFICAÇÃO PARA O ESTÁGIO EX
          case (uut.EXMEM_instr[31:25])
            7'b0000000: begin
              case(uut.EXMEM_instr[14:12])
                3'b000: $display("Instrucao EX  %b  -  ADD x%0d, x%0d, x%0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20]);
                3'b010: $display("Instrucao EX  %b  -  SLT x%0d, x%0d, x%0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20]); 
                3'b011: $display("Instrucao EX  %b  -  SLTU x%0d, x%0d, x%0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20]); 
              endcase
            end
            7'b0000001: $display("Instrucao EX  %b  -  MUL x%0d, x%0d, x%0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20]);
            7'b0100000: $display("Instrucao EX  %b  -  SUB x%0d, x%0d, x%0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20]);
          endcase
          // <--- FIM DA MODIFICAÇÃO PARA O ESTÁGIO EX
        end
        7'b0100011:begin
          $display("Instrucao EX  %b  -  SW x%0d, %0d(x%0d)", uut.EXMEM_instr, uut.EXMEM_instr[24:20], EXMEM_imm, uut.EXMEM_instr[19:15]);
        end
        7'b0000011: begin
          $display("Instrucao EX  %b  -  LW x%0d, %0d(x%0d) (Memoria[%0d]=%0d)", uut.EXMEM_instr, uut.EXMEM_rd, EXMEM_imm, uut.EXMEM_instr[19:15], uut.EXMEM_AluOut>>2, uut.memoria_dados[uut.EXMEM_AluOut>>2]);
        end
        7'b0010011: begin
          case(uut.EXMEM_instr[14:12])
            3'b001: $display("Instrucao EX  %b  -  SLLI x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20]);
            3'b101: $display("Instrucao EX  %b  -  SRLI x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20]);
            3'b000: $display("Instrucao EX  %b  -  ADDI x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], EXMEM_imm);
            3'b010: $display("Instrucao EX  %b  -  SLTI x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], EXMEM_imm);
            3'b011: $display("Instrucao EX  %b  -  SLTIU x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_rd, uut.EXMEM_instr[19:15], EXMEM_imm);
          endcase
        end
        7'b1100111: begin
          $display("Instrucao EX  %b  -  JALR x%0d, %0d(x%0d)", uut.EXMEM_instr, uut.EXMEM_rd, EXMEM_imm, uut.EXMEM_instr[19:15]);
        end
        7'b1100011:
          case (uut.EXMEM_instr[14:12])
            3'b101: $display("Instrucao EX  %b  -  BGE x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20], EXMEM_imm);
            3'b100: $display("Instrucao EX  %b  -  BLT x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20], EXMEM_imm);
            3'b001: $display("Instrucao EX  %b  -  BNE x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20], EXMEM_imm);
            3'b000: $display("Instrucao EX  %b  -  BEQ x%0d, x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_instr[19:15], uut.EXMEM_instr[24:20], EXMEM_imm);
          endcase
        7'b1101111: begin
            $display("Instrucao EX  %b  -  JAL x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_rd, EXMEM_imm);
        end
        7'b0110111: $display("Instrucao EX  %b  -  LUI x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_rd, EXMEM_imm);
        7'b0010111: $display("Instrucao EX  %b  -  AUIPC x%0d, %0d", uut.EXMEM_instr, uut.EXMEM_rd, EXMEM_imm);
        default: $display("Instrucao EX  %b", uut.EXMEM_instr);
    endcase

    case(uut.MEMWB_instr[6:0])
        7'b0110011: begin // R-Type
          // <--- INÍCIO DA MODIFICAÇÃO PARA O ESTÁGIO MEM
          case (uut.MEMWB_instr[31:25])
            7'b0000000: begin
              case(uut.MEMWB_instr[14:12])
                3'b000: $display("Instrucao MEM %b  -  ADD x%0d, x%0d, x%0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20]);
                3'b010: $display("Instrucao MEM %b  -  SLT x%0d, x%0d, x%0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20]); 
                3'b011: $display("Instrucao MEM %b  -  SLTU x%0d, x%0d, x%0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20]); 
              endcase
            end
            7'b0000001: $display("Instrucao MEM %b  -  MUL x%0d, x%0d, x%0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20]);
            7'b0100000: $display("Instrucao MEM %b  -  SUB x%0d, x%0d, x%0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20]);
          endcase
          // <--- FIM DA MODIFICAÇÃO PARA O ESTÁGIO MEM
        end
        7'b0100011:begin
          $display("Instrucao MEM %b  -  SW x%0d, %0d(x%0d)", uut.MEMWB_instr, uut.MEMWB_instr[24:20], MEMWB_imm, uut.MEMWB_instr[19:15]);
        end
        7'b0000011: begin
          $display("Instrucao MEM %b  -  LW x%0d, %0d(x%0d)", uut.MEMWB_instr, uut.MEMWB_rd, MEMWB_imm, uut.MEMWB_instr[19:15]);
        end
        7'b0010011: begin
          case(uut.MEMWB_instr[14:12])
            3'b001: $display("Instrucao MEM %b  -  SLLI x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20]);
            3'b101: $display("Instrucao MEM %b  -  SRLI x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20]);
            3'b000: $display("Instrucao MEM %b  -  ADDI x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], MEMWB_imm);
            3'b010: $display("Instrucao EX  %b  -  SLTI x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], MEMWB_imm);
            3'b011: $display("Instrucao EX  %b  -  SLTIU x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_instr[19:15], MEMWB_imm);          
          endcase
        end
        7'b1100111: begin
          $display("Instrucao MEM %b  -  JALR x%0d, %0d(x%0d)", uut.MEMWB_instr, uut.MEMWB_rd, MEMWB_imm, uut.MEMWB_instr[19:15]);
        end
        7'b1100011:
          case (uut.MEMWB_instr[14:12])
            3'b101: $display("Instrucao MEM %b  -  BGE x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20], MEMWB_imm);
            3'b100: $display("Instrucao MEM %b  -  BLT x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20], MEMWB_imm);
            3'b001: $display("Instrucao MEM %b  -  BNE x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20], MEMWB_imm);
            3'b000: $display("Instrucao MEM %b  -  BEQ x%0d, x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_instr[19:15], uut.MEMWB_instr[24:20], MEMWB_imm);
          endcase
        7'b1101111: begin
          $display("Instrucao MEM %b  -  JAL x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_rd, MEMWB_imm);
        end
        7'b0110111: $display("Instrucao MEM %b  -  LUI x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_Dado);
        7'b0010111: $display("Instrucao MEM %b  -  AUIPC x%0d, %0d", uut.MEMWB_instr, uut.MEMWB_rd, uut.MEMWB_Dado);
        default: $display("Instrucao MEM %b", uut.MEMWB_instr);
    endcase

    case(WB_instr[6:0])
        7'b0110011: begin // R-Type
          // <--- INÍCIO DA MODIFICAÇÃO PARA O ESTÁGIO WB
          case (WB_instr[31:25])
            7'b0000000: begin
              case(WB_instr[14:12])
                3'b000: $display("Instrucao WB  %b  -  ADD x%0d, x%0d, x%0d", WB_instr, WB_rd, WB_instr[19:15], WB_instr[24:20]);
                3'b010: $display("Instrucao WB  %b  -  SLT x%0d, x%0d, x%0d", WB_instr, WB_rd, WB_instr[19:15], WB_instr[24:20]); 
                3'b011: $display("Instrucao WB  %b  -  SLTU x%0d, x%0d, x%0d", WB_instr, WB_rd, WB_instr[19:15], WB_instr[24:20]); 
                default: $display("Instrucao WB  %b  -  R-Type (funct7=0) Desconhecido", WB_instr);
              endcase
            end
            7'b0000001: $display("Instrucao WB  %b  -  MUL x%0d, x%0d, x%0d", WB_instr, WB_rd, WB_instr[19:15], WB_instr[24:20]);
            7'b0100000: $display("Instrucao WB  %b  -  SUB x%0d, x%0d, x%0d", WB_instr, WB_rd, WB_instr[19:15], WB_instr[24:20]);
            default: $display("Instrucao WB  %b  -  R-Type Desconhecido", WB_instr);
          endcase
          // <--- FIM DA MODIFICAÇÃO PARA O ESTÁGIO WB
        end
        7'b0100011:begin
          $display("Instrucao WB  %b  -  SW x%0d, %0d(x%0d)", WB_instr, WB_instr[24:20], WB_imm, WB_instr[19:15]);
        end
        7'b0000011: begin
          $display("Instrucao WB  %b  -  LW x%0d, %0d(x%0d)", WB_instr, WB_rd, WB_imm, WB_instr[19:15]);
        end
        7'b0010011: begin
          case(WB_instr[14:12])
            3'b001: $display("Instrucao WB  %b  -  SLLI x%0d, x%0d, %0d", WB_instr, WB_rd, WB_instr[19:15], WB_instr[24:20]);
            3'b101: $display("Instrucao WB  %b  -  SRLI x%0d, x%0d, %0d", WB_instr, WB_rd, WB_instr[19:15], WB_instr[24:20]);
            3'b000: $display("Instrucao WB  %b  -  ADDI x%0d, x%0d, %0d", WB_instr, WB_rd, WB_instr[19:15], WB_imm);
            3'b010: $display("Instrucao EX  %b  -  SLTI x%0d, x%0d, %0d", WB_instr, WB_rd, WB_instr[19:15], WB_imm);
            3'b011: $display("Instrucao EX  %b  -  SLTIU x%0d, x%0d, %0d", WB_instr, WB_rd, WB_instr[19:15], WB_imm);          
          endcase
        end
        7'b1100111: begin
          $display("Instrucao WB  %b  -  JALR x%0d, %0d(x%0d)", WB_instr, WB_rd, WB_imm, WB_instr[19:15]);
        end
        7'b1100011:
          case (WB_instr[14:12])
            3'b101: $display("Instrucao WB  %b  -  BGE x%0d, x%0d, %0d", WB_instr, WB_instr[19:15], WB_instr[24:20], WB_imm);
            3'b100: $display("Instrucao WB  %b  -  BLT x%0d, x%0d, %0d", WB_instr, WB_instr[19:15], WB_instr[24:20], WB_imm);
            3'b001: $display("Instrucao WB  %b  -  BNE x%0d, x%0d, %0d", WB_instr, WB_instr[19:15], WB_instr[24:20], WB_imm);
            3'b000: $display("Instrucao WB  %b  -  BEQ x%0d, x%0d, %0d", WB_instr, WB_instr[19:15], WB_instr[24:20], WB_imm);
          endcase
        7'b1101111: begin
          $display("Instrucao WB  %b  -  JAL x%0d, %0d", WB_instr, WB_rd, WB_imm);
        end
        7'b0110111: $display("Instrucao WB  %b  -  LUI x%0d, %0d", WB_instr, WB_rd, WB_data);
        7'b0010111: $display("Instrucao WB  %b  -  AUIPC x%0d, %0d", WB_instr, WB_rd, WB_data);
        default: $display("Instrucao WB  %b", WB_instr);
    endcase

    //$display("Valor de IDEX_r1: %0d  || EXMEM_r1: %0d", uut.IDEX_r1, uut.EXMEM_r1);
      $display("--------------------------------------------------------------------------------");
      $display("Reg[0]: %0d   || Reg[1]: %0d   || Reg[2]: %0d   || Reg[3]: %0d", uut.banco_regs[0], uut.banco_regs[1], uut.banco_regs[2], uut.banco_regs[3]);
      $display("Reg[4]: %0d   || Reg[5]: %0d   || Reg[6]: %0d   || Reg[7]: %0d", uut.banco_regs[4], uut.banco_regs[5], uut.banco_regs[6], uut.banco_regs[7]);
      $display("Reg[8]: %0d   || Reg[9]: %0d   || Reg[10]: %0d  || Reg[11]: %0d", uut.banco_regs[8], uut.banco_regs[9], uut.banco_regs[10], uut.banco_regs[11]);
      $display("Reg[12]: %0d  || Reg[13]: %0d  || Reg[14]: %0d  || Reg[15]: %0d", uut.banco_regs[12], uut.banco_regs[13], uut.banco_regs[14], uut.banco_regs[15]);
      $display("Reg[16]: %0d  || Reg[17]: %0d  || Reg[18]: %0d  || Reg[19]: %0d", uut.banco_regs[16], uut.banco_regs[17], uut.banco_regs[18], uut.banco_regs[19]);
      $display("Reg[20]: %0d  || Reg[21]: %0d  || Reg[22]: %0d  || Reg[23]: %0d", uut.banco_regs[20], uut.banco_regs[21], uut.banco_regs[22], uut.banco_regs[23]);
      $display("Reg[24]: %0d  || Reg[25]: %0d  || Reg[26]: %0d  || Reg[27]: %0d", uut.banco_regs[24], uut.banco_regs[25], uut.banco_regs[26], uut.banco_regs[27]);
      $display("Reg[28]: %0d  || Reg[29]: %0d  || Reg[30]: %0d  || Reg[31]: %0d\n", uut.banco_regs[28], uut.banco_regs[29], uut.banco_regs[30], uut.banco_regs[31]);
      $display("memoria_dados[0] = %0d   || memoria_dados[1] = %0d    || memoria_dados[2]  = %0d    || memoria_dados[3] = %0d", uut.memoria_dados[0], uut.memoria_dados[1], uut.memoria_dados[2], uut.memoria_dados[3]);
      $display("memoria_dados[4] = %0d     || memoria_dados[5] = %0d    || memoria_dados[6]  = %0d    || memoria_dados[7] = %0d", uut.memoria_dados[4], uut.memoria_dados[5], uut.memoria_dados[6], uut.memoria_dados[7]);
      $display("memoria_dados[8] = %0d     || memoria_dados[9] = %0d    || memoria_dados[10]  = %0d   || memoria_dados[11] = %0d", uut.memoria_dados[8], uut.memoria_dados[9], uut.memoria_dados[10], uut.memoria_dados[11]);
      $display("memoria_dados[12] = %0d    || memoria_dados[13] = %0d   || memoria_dados[14]  = %0d   || memoria_dados[15] = %0d", uut.memoria_dados[12], uut.memoria_dados[13], uut.memoria_dados[14], uut.memoria_dados[15]);
      $display("memoria_dados[16] = %0d     || memoria_dados[17] = %0d    || memoria_dados[18]  = %0d   || memoria_dados[19] = %0d", uut.memoria_dados[16], uut.memoria_dados[17], uut.memoria_dados[18], uut.memoria_dados[19]);
      $display("memoria_dados[20] = %0d    || memoria_dados[21] = %0d   || memoria_dados[22]  = %0d   || memoria_dados[23] = %0d", uut.memoria_dados[20], uut.memoria_dados[21], uut.memoria_dados[22], uut.memoria_dados[23]);
      $display("--------------------------------------------------------------------------------");
      if (uut.stall_cache_instrucoes)
        $display("MISS NA CACHE DE INSTRUCAO -> STALL");
      else
        $display("HIT NA CACHE DE INSTRUCAO");
      if(uut.stall_cache_dados)
        $display("MISS NA CACHE DE DADOS -> STALL");
      else if(uut.EXMEM_instr[6:0] == 7'b0000011 || uut.EXMEM_instr[6:0] == 7'b0000011) begin
        $display("HIT NA CACHE DE DADOS");
      end

      if(uut.stall)
        $display("STALL DE DEPENDENCIA DE DADOS");
      else if (uut.IDEX_instr[6:0] == 7'b1100011) begin
        $display("=====================================================");
        $display("Comparando Operando 1: %0d  ||  Operando 2: %0d", uut.Operando_1, uut.Operando_2);
        $display("FWD_R1: %0d  ||  FWD_R2: %0d", uut.fwdEXMEM_r1, uut.fwdMEMWB_r2);
        $display("PC será atualizado para: %d", uut.Somatorio_PCeIMM);
        $display("====================================================");
      end
      else if(uut.EXMEM_instr[6:0] == 7'b1100011) begin
        $display("Resultado da comparacao: %s", uut.BranchOutCome ? "TOMADO" : "NAO TOMADO");
      end
    end
  end
end

  // 4) Espera o mergesort rodar e imprime o resultado
  initial begin
    wait (reset == 0);
    #110000;  // tempo suficiente para ordenar

    $display("\n--- Vetor ordenado em memoria_dados ---");
    for (i = 0; i < 50; i = i + 1)
      $display("memoria_dados[%0d] = %0d", i, uut.memoria_dados[i]);

    $finish;
  end
endmodule
