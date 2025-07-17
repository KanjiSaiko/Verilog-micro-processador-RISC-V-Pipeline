// Mapeamento Direto com 16 linhas de cache e 16 bytes por linha
module cache_dados (
    // Entradas
    input wire clock,
    input wire reset,
    input wire        MemRead,
    input wire [31:0] endereco,

    output wire [31:0] dado_lido,
    output wire        stall_cache_dados
);
    integer i;
    

    reg [127:0] data_cache_data [0:15]; 
    reg [23:0]  data_cache_tag  [0:15];
    reg         data_cache_valid[0:15];


    wire [3:0]  cache_index      = endereco[7:4];  
    wire [23:0] cache_tag_addr   = endereco[31:8];
    wire [1:0]  seletor_de_palavra = endereco[3:2];

    // --- LOGICA DE HIT ---
    wire cache_data_hit = data_cache_valid[cache_index] && (data_cache_tag[cache_index] == cache_tag_addr);

    assign stall_cache_dados = MemRead && !cache_data_hit;


    wire [127:0] bloco_selecionado = data_cache_data[cache_index];
    
    assign dado_lido = (seletor_de_palavra == 2'b00) ? bloco_selecionado[31:0]   :
                       (seletor_de_palavra == 2'b01) ? bloco_selecionado[63:32]  :
                       (seletor_de_palavra == 2'b10) ? bloco_selecionado[95:64]  :
                                                       bloco_selecionado[127:96];


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
