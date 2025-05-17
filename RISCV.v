
module RISCV (clock, reset);
    input clock;
    input reset;

reg [15:0] mem_instruc [0:255]; //memoria de instruções com 256 posições de tamanho 16 bits
reg [7:0] mem_dados [0:255]; //memoria de dados com 256 posições de tamanho 8 bits
reg [7:0] banco_regs [0:15]; //banco de 16 registradores de 8 bits

task automatic zera_meminstruc (output reg[15:0] mem_instruc [0:255]);
    integer i;
    begin
        for(i = 0; i < 255; i = i+1) //for para limpar a memoria de instruções com valor 0
            mem_instruc[i] = 16'b0;
            $display("mem_dados[%0d] = 0x%0h", i, mem_instruc[i]);
    end
endtask

task automatic zera_memdados (output reg[7:0] mem_dados [0:255]);
    integer i;
    begin
        for(i = 0; i < 255; i = i+1) //for para limpar a memoria de dados com valor 0
            mem_dados[i] = 8'b0;
            $display("mem_dados[%0d] = 0x%0h", i, mem_dados[i]);
    end
endtask

task automatic zera_regs (output reg[7:0] mem_dados [0:15]);
    integer i;
    begin
        for(i = 0; i < 15; i = i+1) //for para limpar o banco de registradores com valor 0
            banco_regs[i] = 8'b0;
            $display("mem_dados[%0d] = 0x%0h", i, banco_regs[i]);
    end
endtask

//Considerar atribuir esta task direto em zerar instruções
task automatic atribui_instrucao (output reg[15:0] mem_instruc [0:255]);
    mem_instruc[0] = 16'b0110000000001010; // BNE R0 != R1 FALSO
    mem_instruc[1] = 16'b0000000000000001; // LDA endereço 1 para R0 (Valor 1)
    mem_instruc[2] = 16'b0000000100000010; // LDA endereço 2 para R1 (Valor 3)
    mem_instruc[3] = 16'b1010100000000111; // LWI Valor 7 no registrador 8
    mem_instruc[4] = 16'b1111111111111111; // Bolha artificial
endtask

//Considerar atribuir esta task direto em zerar dados
task automatic atribui_dados (output reg[7:0] mem_dados [0:255]);
    mem_dados[1] = 8'b00000001; // Valor 1
    mem_dados[2] = 8'b00000011; // Valor 3
endtask

reg [7:0] PC; //Contador
reg desvio; //Controle para indicar se deve ocorrer um salto (branch).
reg equal; //Sinal para verificar se R0 e igual a R1 (usado em instruçoes de comparaçao).
reg [7:0] R0ID_EX, R1ID_EX;
reg [7:0] RwID_EX, RwEX_MEM, RwMEM_WB; //Registrador a ser escrito
reg [7:0] PCIF_ID, PCID_EX, PCEX_MEM, PCMEM_WB //Contador de programa (Program Counter) que armazena o endereço atual de execuçao.
reg [15:0] InIF_ID, InID_EX, InEX_MEM, InMEM_WB //Instrucao Atual de cada estagio


initial begin //executa de uma vez só
    zera_memdados(mem_dados);
    zera_meminstruc(mem_instruc);
    zera_regs(banco_regs);
    atribui_instrucao(mem_instruc);
    atribui_dados(mem_dados);
end

always @(*) begin
    //Verifica se R0 e R1 tem valores iguais
    if (R0ID_EX == RwEX_MEM)
        equal <= 1;
    else
        equal <= 0;

    //Indica se um salto deve ocorrer
    if (InEX_MEM[15:12] == 4'b0110 and equal == 0) or (InEX_MEM[15:12] == 4'b0101 and equal == 1)
        desvio <= 1;
    else
        desvio <= 0;
end


always @(posedge clock, posedge reset) //sensivel ao clock
begin
    if(reset)
        //bloco
    else
        //bloco 
end
endmodule

