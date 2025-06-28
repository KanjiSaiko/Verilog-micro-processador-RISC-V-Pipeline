module cache_instrucoes (
    // Entradas
    input wire           clock,
    input wire           reset,
    input wire [31:0]    PC,
    input wire           memoria_pronta,
    input wire [127:0]   instrucao_em_bloco,
    output reg           requisicao_de_leitura, // Vem da FSM da cache quando há um miss+-
    output reg [31:0]    pc_do_miss_reg,  // Endereço desejado
    output wire          stall_cache_instrucoes,
    output wire[31:0]    instrucao_do_processador
);
    integer i;
    localparam IDLE = 0, FETCH_MEM = 1, REFILL = 2; 
    reg [127:0] instr_cache_data [0:31]; // (32 linhas de 128 bits (4 instrucoes))
    reg [22:0] instr_cache_tag  [0:31];  // Tags da cache (enderea§os sem offset)
    reg        instr_cache_valid[0:31];  // Bits de validade da cache

    wire [4:0]  cache_index = PC[8:4]; 
    wire [22:0] cache_tag   = PC[31:9]; // 32 - 5 (indice) - 4 (offset) = 23bits
    wire cache_instr_hit = instr_cache_valid[cache_index] && (instr_cache_tag[cache_index] == cache_tag);

    reg  [22:0] cache_tag_do_miss_reg;
    reg  [1:0]  estado_cache;

    wire miss_prestes_a_acontecer = (estado_cache == IDLE) && (!cache_instr_hit);
    assign stall_cache_instrucoes = miss_prestes_a_acontecer || (estado_cache != IDLE);

    wire [127:0] bloco_selecionado = instr_cache_data[cache_index];
    wire [1:0] seletor_de_palavra = PC[3:2];
    assign instrucao_do_processador = (seletor_de_palavra == 2'b00) ? bloco_selecionado[31:0]   :
                                      (seletor_de_palavra == 2'b01) ? bloco_selecionado[63:32]  :
                                      (seletor_de_palavra == 2'b10) ? bloco_selecionado[95:64]  :
                                                                      bloco_selecionado[127:96];

    // Extrai o índice do PC que causou o miss, não do PC atual.
    wire [4:0] index_para_escrita = pc_do_miss_reg[8:4];

//===========================
//Busca na Cache
//=========================== 
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      estado_cache <= IDLE;
      requisicao_de_leitura <= 0;
        // Invalida a cache
      for (i = 0; i < 32; i = i + 1) begin
        instr_cache_valid[i] <= 0;
        instr_cache_tag[i]   <= 0;
        instr_cache_data[i]  <= 0;
      end
    end else begin
        requisicao_de_leitura  <= 0;
        case (estado_cache)
            IDLE: begin //Ocioso, esperando por pedido
                if (!cache_instr_hit) begin
                    // Miss! Precisa buscar na memória.
                    requisicao_de_leitura <= 1;         // 1. Pede para a memória ler
                    pc_do_miss_reg        <= PC;        // 2. Trava o PC do miss
                    cache_tag_do_miss_reg <= cache_tag; // 3. Trava a Tag do miss
                    estado_cache <= FETCH_MEM; 
                end
            end
            
            FETCH_MEM: begin //Enviou o pedido da instrução
                // Assume que a memória leva ciclos e sinaliza 'memoria_pronta'
                requisicao_de_leitura <= 1;
                pc_do_miss_reg <= pc_do_miss_reg;
                if (memoria_pronta) begin
                    estado_cache <= REFILL;
                end
            end

            REFILL: begin
                // Escreve os dados, tag e validade (com atribuição não-bloqueante!)
                instr_cache_data[index_para_escrita]  <= instrucao_em_bloco;
                instr_cache_tag[index_para_escrita]   <= cache_tag_do_miss_reg; // Um reg que guardou a tag do miss
                instr_cache_valid[index_para_escrita] <= 1;
                estado_cache                          <= IDLE;
                
            end
        endcase
    end
  end

endmodule

//Bits de Offset: Para endereçar cada um dos 16 bytes dentro do bloco, precisamos de log₂(16) = 4 bits.
//Bits de Índice: Para selecionar uma das 32 linhas da cache, precisamos de log₂(32) = 5 bits. Estes são os próximos 5 bits do endereço.
    //Índice: PC[8:4] (5 bits)

//Bits de Tag: O resto dos bits do endereço.
//Tag: 32 - 5 (Índice) - 4 (Offset) = 23 bits.
    //Tag: PC[31:9]