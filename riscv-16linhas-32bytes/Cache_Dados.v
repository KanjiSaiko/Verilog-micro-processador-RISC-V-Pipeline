// Cache de Dados: 16 linhas, blocos de 32 bytes (8 palavras)
module cache_dados (
    input wire clock,
    input wire reset,
    input wire        MemRead,
    input wire [31:0] endereco,
    output wire [31:0] dado_lido,
    output wire        stall_cache_dados
);
    integer i;
    
    reg [255:0] data_cache_data [0:15];
    reg [22:0]  data_cache_tag  [0:15];
    reg         data_cache_valid[0:15];

    wire [3:0]  cache_index      = endereco[8:5];
    wire [22:0] cache_tag_addr   = endereco[31:9];
    wire [2:0]  seletor_de_palavra = endereco[4:2];

    wire cache_data_hit = data_cache_valid[cache_index] && (data_cache_tag[cache_index] == cache_tag_addr);
    assign stall_cache_dados = MemRead && !cache_data_hit;

    // --- LÓGICA DE LEITURA (MODIFICADO) ---
    wire [255:0] bloco_selecionado = data_cache_data[cache_index];
    assign dado_lido = (seletor_de_palavra == 3'b000) ? bloco_selecionado[31:0]   :
                       (seletor_de_palavra == 3'b001) ? bloco_selecionado[63:32]  :
                       (seletor_de_palavra == 3'b010) ? bloco_selecionado[95:64]  :
                       (seletor_de_palavra == 3'b011) ? bloco_selecionado[127:96] :
                       (seletor_de_palavra == 3'b100) ? bloco_selecionado[159:128]:
                       (seletor_de_palavra == 3'b101) ? bloco_selecionado[191:160]:
                       (seletor_de_palavra == 3'b110) ? bloco_selecionado[223:192]:
                                                        bloco_selecionado[255:224];

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                data_cache_valid[i] <= 0;
                data_cache_tag[i]   <= 0;
                data_cache_data[i]  <= 0;
            end
        end
    end

endmodule
