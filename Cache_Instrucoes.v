module cache_instrucoes (
    // Entradas
    input wire           clock,
    input wire           reset,
    input wire [31:0]    PC,
    output wire          stall_cache_instrucoes,
    output wire[31:0]    instrucao_do_processador
);
    integer i;
    reg [127:0] instr_cache_data [0:31]; // (32 linhas de 128 bits (4 instrucoes))
    reg [22:0] instr_cache_tag  [0:31];  // Tags da cache (enderea§os sem offset)
    reg        instr_cache_valid[0:31];  // Bits de validade da cache

    wire [4:0]  cache_index = PC[8:4]; 
    wire [22:0] cache_tag   = PC[31:9]; // 32 - 5 (indice) - 4 (offset) = 23bits

    wire cache_instr_hit = instr_cache_valid[cache_index] && (instr_cache_tag[cache_index] == cache_tag);

    assign stall_cache_instrucoes = !cache_instr_hit;

    wire [127:0] bloco_selecionado = instr_cache_data[cache_index];
    wire [1:0] seletor_de_palavra = PC[3:2];
    assign instrucao_do_processador = (cache_instr_hit) ? 
                                      ((seletor_de_palavra == 2'b00) ? bloco_selecionado[31:0]   :
                                       (seletor_de_palavra == 2'b01) ? bloco_selecionado[63:32]  :
                                       (seletor_de_palavra == 2'b10) ? bloco_selecionado[95:64]  :
                                                                       bloco_selecionado[127:96])
                                      : 32'b0; // Se for miss, a saída não importa (pipeline parado)
//===========================
//Busca na Cache
//=========================== 
  always @(posedge clock or posedge reset) begin
    if (reset) begin
        // Invalida a cache
      for (i = 0; i < 32; i = i + 1) begin
        instr_cache_valid[i] <= 0;
        instr_cache_tag[i]   <= 0;
        instr_cache_data[i]  <= 0;
      end
    end 
  end

endmodule

//Bits de Offset: Para endereçar cada um dos 16 bytes dentro do bloco, precisamos de log₂(16) = 4 bits.
//Bits de Índice: Para selecionar uma das 32 linhas da cache, precisamos de log₂(32) = 5 bits. Estes são os próximos 5 bits do endereço.
    //Índice: PC[8:4] (5 bits)

//Bits de Tag: O resto dos bits do endereço.
//Tag: 32 - 5 (Índice) - 4 (Offset) = 23 bits.
    //Tag: PC[31:9]