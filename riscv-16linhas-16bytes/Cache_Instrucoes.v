module cache_instrucoes (
    // Entradas
    input wire          clock,
    input wire          reset,
    input wire [31:0]   PC,
    output wire         stall_cache_instrucoes,
    output wire[31:0]   instrucao_do_processador
);
    integer i;
    
    reg [127:0] instr_cache_data [0:15]; // (16 linhas de 128 bits (4 instrucoes))
    reg [23:0]  instr_cache_tag  [0:15]; //Tags da cache (enderecados sem offset)
    reg         instr_cache_valid[0:15]; // Bits de validade da cache


    wire [3:0]  cache_index = PC[7:4];  
    wire [23:0] cache_tag   = PC[31:8]; 

    // --- LÓGICA DE HIT ---
    wire cache_instr_hit = instr_cache_valid[cache_index] && (instr_cache_tag[cache_index] == cache_tag);

    assign stall_cache_instrucoes = !cache_instr_hit;


    wire [127:0] bloco_selecionado = instr_cache_data[cache_index];
    wire [1:0]   seletor_de_palavra = PC[3:2];
    assign instrucao_do_processador = (cache_instr_hit) ? 
                                      ((seletor_de_palavra == 2'b00) ? bloco_selecionado[31:0]   :
                                       (seletor_de_palavra == 2'b01) ? bloco_selecionado[63:32]  :
                                       (seletor_de_palavra == 2'b10) ? bloco_selecionado[95:64]  :
                                                                        bloco_selecionado[127:96])
                                      : 32'b0; // Se for miss, a saida nao importa (pipeline parado)


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
