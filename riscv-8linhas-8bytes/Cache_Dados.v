module cache_dados (
    input wire clock,
    input wire reset,
    input wire        MemRead,
    input wire [31:0] endereco,
    output wire [31:0] dado_lido,
    output wire        stall_cache_dados
);
    integer i;
    
    // --- ESTRUTURA DA CACHE (MODIFICADO) ---
    reg [63:0]  data_cache_data [0:7];  // MODIFICADO: 8 linhas de 64 bits
    reg [25:0]  data_cache_tag  [0:7];  // MODIFICADO: 8 linhas, Tag de 26 bits
    reg         data_cache_valid[0:7];  // MODIFICADO: 8 bits de validade

    // --- LÓGICA DE ENDEREÇAMENTO (MODIFICADO) ---
    wire [2:0]  cache_index      = endereco[5:3];  // MODIFICADO: Índice de 3 bits
    wire [25:0] cache_tag_addr   = endereco[31:6]; // MODIFICADO: Tag de 26 bits
    wire        seletor_de_palavra = endereco[2];

    wire cache_data_hit = data_cache_valid[cache_index] && (data_cache_tag[cache_index] == cache_tag_addr);
    assign stall_cache_dados = MemRead && !cache_data_hit;

    // --- LÓGICA DE LEITURA (MODIFICADO) ---
    wire [63:0] bloco_selecionado = data_cache_data[cache_index];
    assign dado_lido = (seletor_de_palavra == 1'b0) ? bloco_selecionado[31:0] :
                                                      bloco_selecionado[63:32];

    // --- LÓGICA DE RESET (MODIFICADO) ---
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // MODIFICADO: Loop vai até 8
            for (i = 0; i < 8; i = i + 1) begin
                data_cache_valid[i] <= 0;
                data_cache_tag[i]   <= 0;
                data_cache_data[i]  <= 0;
            end
        end
    end

endmodule
