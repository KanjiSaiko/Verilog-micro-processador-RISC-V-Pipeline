// Cache de Instruções: 16 linhas, blocos de 32 bytes (8 palavras)
module cache_instrucoes (
    input wire          clock,
    input wire          reset,
    input wire [31:0]   PC,
    output wire         stall_cache_instrucoes,
    output wire[31:0]   instrucao_do_processador
);
    integer i;
    
    reg [255:0] instr_cache_data [0:15];
    reg [22:0]  instr_cache_tag  [0:15];
    reg         instr_cache_valid[0:15];

    wire [3:0]  cache_index = PC[8:5];
    wire [22:0] cache_tag   = PC[31:9];

    wire cache_instr_hit = instr_cache_valid[cache_index] && (instr_cache_tag[cache_index] == cache_tag);
    assign stall_cache_instrucoes = !cache_instr_hit;

    // --- LÓGICA DE LEITURA (MODIFICADO) ---
    wire [255:0] bloco_selecionado    = instr_cache_data[cache_index];
    wire [2:0]   seletor_de_palavra = PC[4:2];
    assign instrucao_do_processador = (cache_instr_hit) ? 
                                      ( (seletor_de_palavra == 3'b000) ? bloco_selecionado[31:0]   :
                                        (seletor_de_palavra == 3'b001) ? bloco_selecionado[63:32]  :
                                        (seletor_de_palavra == 3'b010) ? bloco_selecionado[95:64]  :
                                        (seletor_de_palavra == 3'b011) ? bloco_selecionado[127:96] :
                                        (seletor_de_palavra == 3'b100) ? bloco_selecionado[159:128]:
                                        (seletor_de_palavra == 3'b101) ? bloco_selecionado[191:160]:
                                        (seletor_de_palavra == 3'b110) ? bloco_selecionado[223:192]:
                                                                         bloco_selecionado[255:224] )
                                      : 32'b0;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                instr_cache_valid[i] <= 0;
                instr_cache_tag[i]   <= 0;
                instr_cache_data[i]  <= 0;
            end
        end 
    end

endmodule
