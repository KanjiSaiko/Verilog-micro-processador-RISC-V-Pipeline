
module RISCV (clock, reset);
    input clock;
    input reset;

reg [31:0] mem_instruc [0:255]; //memoria de instruções com 256 posições de tamanho 16 bits
reg [7:0] mem_dados [0:255]; //memoria de dados com 256 posições de tamanho 8 bits
reg [7:0] banco_regs [0:31]; //banco de 32 registradores de 8 bits

task automatic zera_meminstruc (output reg[31:0] mem_instruc [0:255]);
    integer i;
    begin
        for(i = 0; i < 255; i = i+1) //for para limpar a memoria de instruções com valor 0
            mem_instruc[i] = 32'b0;
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

task automatic zera_regs (output reg[7:0] banco_regss [0:31]);
    integer i;
    begin
        for(i = 0; i < 15; i = i+1) //for para limpar o banco de registradores com valor 0
            banco_regs[i] = 8'b0;
            $display("mem_dados[%0d] = 0x%0h", i, banco_regs[i]);
    end
endtask

//Considerar atribuir esta task direto em zerar instruções
task automatic atribui_instrucao (output reg[15:0] mem_instruc [0:255]);
    mem_instruc[0] = 32'b0110000000001010; // BNE R0 != R1 FALSO
    mem_instruc[1] = 32'b0000000000000001; // LDA endereço 1 para R0 (Valor 1)
    mem_instruc[2] = 32'b0000000100000010; // LDA endereço 2 para R1 (Valor 3)
    mem_instruc[3] = 32'b1010100000000111; // LWI Valor 7 no registrador 8
    mem_instruc[4] = 32'b1111111111111111; // Bolha artificial
endtask

//Considerar atribuir esta task direto em zerar dados
task automatic atribui_dados (output reg[7:0] mem_dados [0:255]);
    mem_dados[1] = 8'b00000001; // Valor 1
    mem_dados[2] = 8'b00000011; // Valor 3
endtask

reg [15:0] PC; //Contador
reg greater_or_equal, less; //Sinais para os Branch's (BGE e BLT).
reg desvio;
reg [7:0] ulaEX_MEM;
reg [7:0] R1ID_EX, R2ID_EX, R2EX_MEM;
reg [7:0] R2wID_EX, R2wEX_MEM, R2wMEM_WB; //Registrador a ser escrito
reg [15:0] PCIF_ID, PCID_EX, PCEX_MEM, PCMEM_WB //Contador de programa (Program Counter) que armazena o endereço atual de execuçao.
reg [31:0] InIF_ID, InID_EX, InEX_MEM, InMEM_WB //Instrucao Atual de cada estagio

//Para instrução AUIPC
assign imm20
assign imm_sext
assign imm_shift

initial begin //Executa de uma vez só
    zera_memdados(mem_dados);
    zera_meminstruc(mem_instruc);
    zera_regs(banco_regs);
    atribui_instrucao(mem_instruc);
    atribui_dados(mem_dados);
end

always @(*) begin //Lógica Combinacional
    //Verifica se R1 é maior ou igual a R2
    if (R1ID_EX >= R2wEX_MEM)
        greater_or_equal <= 1;
    else
        greater_or_equal <= 0;

    //Verifica se R1 é menor que R2
    if (R1ID_EX < R2wEX_MEM)
        less <= 1;
    else
        less <= 0;

    //Indica se um salto deve ocorrer a partir do opcode, funct3 e da condição
    if ((InEX_MEM[6:0] == 7'b1100011) and (InEX_MEM[14:12] == 3'b101) and (greater_or_equal == 1)) or ((InEX_MEM[6:0] == 7'b1100011) and (InEX_MEM[14:12] == 3'b100) and (less == 1))
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
        R2wID_EX <= 8'b0;
        R2wEX_MEM <= 8'b0;
        R2wMEM_WB <= 8'b0;

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
            if(InEX_MEM[6:0] == 7'b1100011) //BGE/BLT
                PC <= PC + InEX_MEM[31:25] + InEX_MEM[11:7]; 
        end
        
        else if(InEX_MEM[6:0] == 7'b1101111) //JAL
            banco_regs[InEX_MEM[11:7]] <= PC + 1;
            PC <= PC + InEX_MEM[31:12]; 

        else
            PC <= PC + 1; //pensar se pode haver problemas deixando +1 ao invés de +4

        
        //ID_EX
        if(InID_EX[6:0] == 7'b1101111) begin //JUMP
            R2wID_EX <= 8'b0;
            R1ID_EX <= 8'b0;
            R2ID_EX <= 8'b0;
            InIF_ID <= 16'b1;
            InID_EX <= 16'b1;
        end

        else if((InID_EX[6:0] == 7'b0010011) or (InID_EX[6:0] == 7'b0110011) or (InID_EX[6:0] == 7'b1100011) or (InID_EX[6:0] == 7'b0100011)) begin
            //tipos: R / S / B
            R1ID_EX <= banco_regs[InID_EX[19:15]];
            R2ID_EX <= banco_regs[InID_EX[24:20]];
        end

        else if(InID_EX[6:0] == 7'b0010111) begin //AUIPC
            imm20 <= InID_EX[31:12];
            imm_sext  = {{12{imm20[19]}}, imm20};
            imm_shift = imm_sext << 12;
        end

        else begin
            R1ID_EX <= banco_regs[InID_EX[19:15]];
            //R2wID_EX <= banco_regs[InID_EX[11:8]];
        end

        //EX_MEM
        if(desvio == 1) begin //bolhas
            ulaEX_MEM <= 16'b0;
            R2wID_EX <= 8'b0;
            R1ID_EX <= 8'b0;
            R2ID_EX <= 8'b0;
            R2EX_MEM <= 8'b0;
            InEX_MEM <= 16'b1;
            InID_EX <= 16'b1;
            InIF_ID <= 16'b1;
        end

        else begin
            R2wEX_MEM <= R2wID_EX;
            R2EX_MEM <= R2ID_EX;
            if(InEX_MEM[6:0] == 0110011) begin
                case (InEX_MEM[31:25]) //analisa funct7 do tipo R

                    7'b0000000: //ADD
                        ulaEX_MEM <= R1ID_EX + R2ID_EX;

                    7'b0100000: //SUB
                        ulaEX_MEM <= R1ID_EX - R2ID_EX;

                    7'b0000001: //MUL
                        ulaEX_MEM <= R1ID_EX * R2ID_EX;
                endcase
            end
            else if(InEX_MEM[6:0] == 0010111) //AUIPC 
                ulaEX_MEM <= imm_shift + (PC+4);
                
        end

        //MEM_WB
        if(InMEM_WB[6:0] == 7'b0100011) //STORE WORD
            mem_dados[banco_regs[19:15] + InMEM_WB[31:25] + InMEM_WB[11:7]] <= R2MEM_WB;

        else if(InMEM_WB[6:0] == 7'b0000011) //LOAD WORD
            banco_regs[InMEM_WB[11:7]] <= mem_dados[banco_regs[19:15] + InMEM_WB[31:20]];

        else if(InMEM_WB[6:0] == 7'b0010111) //AUIPC
            banco_regs[InMEM_WB[11:7]] <= ulaEX_MEM;

        else if((InMEM_WB[15:12] == 4'b0101) or (InMEM_WB[15:12] == 4'b0110) or (InMEM_WB[15:12] == 4'b0100) or (InMEM_WB[15:12] == 4'b1111))

        else
            banco_regs[InMEM_WB[[11:7]]] <= ulaEX_MEM;

end
endmodule

