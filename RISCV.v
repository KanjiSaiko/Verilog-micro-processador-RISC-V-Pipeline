
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
reg [7:0] ulaEX_MEM;
reg [7:0] R0ID_EX, R1ID_EX;
reg [7:0] RwID_EX, RwEX_MEM, RwMEM_WB; //Registrador a ser escrito
reg [7:0] PCIF_ID, PCID_EX, PCEX_MEM, PCMEM_WB //Contador de programa (Program Counter) que armazena o endereço atual de execuçao.
reg [15:0] InIF_ID, InID_EX, InEX_MEM, InMEM_WB //Instrucao Atual de cada estagio


initial begin //Executa de uma vez só
    zera_memdados(mem_dados);
    zera_meminstruc(mem_instruc);
    zera_regs(banco_regs);
    atribui_instrucao(mem_instruc);
    atribui_dados(mem_dados);
end

always @(*) begin //Lógica Combinacional
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


always @(posedge clock, posedge reset) //Lógica Sequencial
begin
    if(reset)
        PC <= 0;
        PCIF_ID <= 0;
        PCID_EX <= 0;
        PCEX_MEM <= 0;
        PCMEM_WB <= 0;

        InIF_ID <= 16'b0;
        InID_EX <= 16'b0;
        InEX_MEM <= 16'b0;
        InMEM_WB <= 16'b0;

        ulaEX_MEM <= 8'b0;

        R0ID_EX <= 8'b0;
        R1ID_EX <= 8'b0;
        RwID_EX <= 8'b0;
        RwEX_MEM <= 8'b0;
        RwMEM_WB <= 8'b0;

        //bloco
    else
        //IF_ID
        InIF_ID <= mem_instruc[PC];
        InID_EX <= InIF_ID;
        InEX_MEM <= InID_EX;
        InMEM_WB <= InEX_MEM;

        PCIF_ID <= PC;
        PCID_EX <= PCIF_ID;
        PCEX_MEM <= PCID_EX;
        PCMEM_WB <= PCEX_MEM;

        if (desvio == 1) begin
            if((InEX_MEM[15:12] == 4'b0101) or (InEX_MEM[15:12] == 4'b0110))
                PC <= PC + InEX_MEM[3:0]; //BEQ/BNE
        end
        
        else if(InEX_MEM[15:12] == 4'b0100)
            PC <= InEX_MEM[7:0]; //JUMP

        else
            PC <= PC + 1;

        
        //ID_EX
        if(InID_EX[15:12] == 4'b0100) begin //JUMP
            RwID_EX <= 8'b0;
            R0ID_EX <= 8'b0;
            R1ID_EX <= 8'b0;
            InID_EX <= 16'b1;
            InIF_ID <= 16'b1;
        end

        else if((InID_EX[15:12] == 4'b0001) or (InID_EX[15:12] == 4'b0010) or (InID_EX[15:12] == 4'b0011)) begin
            //R
            R0ID_EX <= banco_regs[InID_EX[7:4]];
            R1ID_EX <= banco_regs[InID_EX[11:8]];
        end

        else begin
            R0ID_EX <= banco_regs[InID_EX[7:4]];
            RwID_EX <= banco_regs[InID_EX[11:8]];
        end

        //EX_MEM
        if(desvio == 1) begin //bolhas
            ulaEX_MEM <= 16'b0;
            RwID_EX <= 8'b0;
            R0ID_EX <= 8'b0;
            R1ID_EX <= 8'b0;
            InEX_MEM <= 16'b1;
            InID_EX <= 16'b1;
            InIF_ID <= 16'b1;
        end

        else begin
            RwEX_MEM <= RwID_EX;
            case (InEX_MEM[15:12])
                4'b0001: //ADD
                    ulaEX_MEM <= R0ID_EX + R1ID_EX;
                
                4'b0010: //SUB
                    ulaEX_MEM <= R0ID_EX - R1ID_EX;
                
                4'b0001: //MULT
                    ulaEX_MEM <= R0ID_EX * R1ID_EX;

                4'b0001: //ADDI
                    ulaEX_MEM <= R0ID_EX + InEX_MEM[3:0];
                
                4'b0001: //SUBI
                    ulaEX_MEM <= R0ID_EX - InEX_MEM[3:0];

                4'b0001: //MULTI
                    ulaEX_MEM <= R0ID_EX * InEX_MEM[3:0];
            endcase
        end

        //MEM_WB
        if(InMEM_WB[15:12] == 4'b0111) //STORE
            mem_dados[InMEM_WB[7:0]] <= RwMEM_WB;

        else if(InMEM_WB[15:12] == 4'b0000) //LOAD
            banco_regs[InMEM_WB[11:8]] <= mem_dados[InMEM_WB[7:0]];

        else if(InMEM_WB[15:12] == 4'b1010) //LOAD-I
            banco_regs[InMEM_WB[11:8]] <= InMEM_WB[7:0];
        
        else if((InMEM_WB[15:12] == 4'b0101) or (InMEM_WB[15:12] == 4'b0110) or (InMEM_WB[15:12] == 4'b0100) or (InMEM_WB[15:12] == 4'b1111))

        else
            banco_regs[InMEM_WB[[11:8]]] <= ulaEX_MEM;

end
endmodule

