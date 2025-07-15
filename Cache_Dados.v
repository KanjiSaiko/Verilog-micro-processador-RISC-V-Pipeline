//Mapeamento Direto com 32 linhas de cache e 16 bytes por linha - Politica "No-Write-Allocate"
module cache_dados (
    // Entradas
    input wire clock,
    input wire reset,
    input wire        MemRead,       // Sinal que indica uma operação de leitura (LW)
    input wire [31:0] endereco,      // Endereço do dado (vem da ULA)

    output wire [31:0] dado_lido,       // Dado lido da cache (em caso de hit)
    output wire        stall_cache_dados // Sinal de stall em caso de read miss
);
    integer i;
    // Estrutura da cache
    reg [127:0] data_cache_data [0:31];  // 32 linhas de 128 bits
    reg [22:0]  data_cache_tag  [0:31];  // Tags de 23 bits
    reg         data_cache_valid[0:31];  // 32 bits de validade

    // Lógica de endereçamento
    wire [4:0]  cache_index    = endereco[8:4];   // 5 bits para o índice
    wire [22:0] cache_tag_addr = endereco[31:9];  // 23 bits para a tag
    wire [1:0]   seletor_de_palavra = endereco[3:2]; // Bits 3 e 2 selecionam a palavra

    // Lógica de Hit
    wire cache_data_hit = data_cache_valid[cache_index] && (data_cache_tag[cache_index] == cache_tag_addr);

    // Para escritas (SW), não geramos stall (política no-write-allocate).
    assign stall_cache_dados = MemRead && !cache_data_hit;

    wire [127:0] bloco_selecionado = data_cache_data[cache_index];
    
    // Saída do dado lido (só é valido em caso de hit)
    assign dado_lido = (seletor_de_palavra == 2'b00) ? bloco_selecionado[31:0]   :
                       (seletor_de_palavra == 2'b01) ? bloco_selecionado[63:32]  :
                       (seletor_de_palavra == 2'b10) ? bloco_selecionado[95:64]  :
                                                       bloco_selecionado[127:96];


    // Stall ocorre se for uma leitura (MemRead) e der miss na cache.


    // Lógica para invalidar a cache no reset
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                data_cache_valid[i] <= 0;
                data_cache_tag[i] <= 0;
                data_cache_data[i] <= 0;
            end
        end
    end

endmodule