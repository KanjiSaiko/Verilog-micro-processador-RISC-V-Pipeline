module memoria_principal (
    // Entradas
    input wire           clock,
    input wire           reset,
    input wire           requisicao_de_leitura, // Vem da FSM da cache quando há um miss+-
    input wire [31:0]    pc_do_miss_reg,  // Endereço desejado
    output reg [127:0]   instrucao_em_bloco,  // Bloco de 64 bytes (com 4 instrucoes)
    output reg           memoria_pronta
);
    // Memória interna com as instruções (como você já tinha)
    reg [31:0] memoria_instrucoes [0:1023];
    
    // Para achar o endereço de início do bloco, basta zerar esses 4 bits.
    reg [31:0] block_base_addr;
    // Calcula os índices das 4 palavras dentro do bloco
    wire [9:0] index0 = block_base_addr >> 2;
    wire [9:0] index1 = (block_base_addr + 4)>>2; 
    wire [9:0] index2 = (block_base_addr + 8)>>2;
    wire [9:0] index3 = (block_base_addr + 12)>>2; 

    localparam LATENCIA = 1; // A memória leva 1 ciclo para responder
    reg [2:0] contador_latencia;
    reg ocupado; // Flag para indicar se a memória está no meio de uma leitura

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ocupado <= 0;
            contador_latencia <= 0;
            memoria_pronta <= 0;
            instrucao_em_bloco <= 0;
        end else begin
            memoria_pronta <= 0;
            if (requisicao_de_leitura && !ocupado) begin
                // A cache fez um novo pedido! Começa a contagem.
                ocupado <= 1;
                contador_latencia <= LATENCIA;
                block_base_addr <= {pc_do_miss_reg[31:4], 4'b0000};

            end else if (ocupado) begin
                // Se estamos ocupados, apenas decrementamos o contador.
                contador_latencia <= contador_latencia - 1;

                if (contador_latencia == 1) begin
                    // Monta o bloco de 128 bits usando os índices alinhados
                    instrucao_em_bloco <= {memoria_instrucoes[index3], memoria_instrucoes[index2], 
                                           memoria_instrucoes[index1], memoria_instrucoes[index0]};
                    // Sinalizas que está pronto
                    memoria_pronta <= 1;
                    // Libera a memória para o próximo pedido
                    ocupado <= 0;
                end
            end
        end
    end

endmodule