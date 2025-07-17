module cache_instrucoes (
    input wire          clock,
    input wire          reset,
    input wire [31:0]   PC,
    output wire         stall_cache_instrucoes,
    output wire[31:0]   instrucao_do_processador
);
    integer i;

    // --- ESTRUTURA DA CACHE (MODIFICADO) ---
    reg [63:0]  instr_cache_data [0:7]; // MODIFICADO: 8 linhas de 64 bits
    reg [25:0]  instr_cache_tag  [0:7]; // MODIFICADO: 8 linhas, Tag de 26 bits
    reg         instr_cache_valid[0:7]; // MODIFICADO: 8 bits de validade

    // --- LÓGICA DE ENDEREÇAMENTO (MODIFICADO) ---
    wire [2:0]  cache_index = PC[5:3];  // MODIFICADO: Índice de 3 bits
    wire [25:0] cache_tag   = PC[31:6]; // MODIFICADO: Tag de 26 bits

    wire cache_instr_hit = instr_cache_valid[cache_index] && (instr_cache_tag[cache_index] == cache_tag);
    assign stall_cache_instrucoes = !cache_instr_hit;

    // --- LÓGICA DE LEITURA (MODIFICADO) ---
    wire [63:0] bloco_selecionado    = instr_cache_data[cache_index];
    wire        seletor_de_palavra = PC[2];
    assign instrucao_do_processador = (cache_instr_hit) ? 
                                      ((seletor_de_palavra == 1'b0) ? bloco_selecionado[31:0] :
                                                                       bloco_selecionado[63:32])
                                      : 32'b0;
                                      
    // --- LÓGICA DE RESET (MODIFICADO) ---
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // MODIFICADO: Loop vai até 8
            for (i = 0; i < 8; i = i + 1) begin
                instr_cache_valid[i] <= 0;
                instr_cache_tag[i]   <= 0;
                instr_cache_data[i]  <= 0;
            end
        end 
    end

endmodule
