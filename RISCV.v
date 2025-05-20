
module RISCV (clock, reset);
    input clock;
    input reset;


//memórias e registradores
reg [15:0] mem_instruc [0:255]; //memoria de instruções com 256 posições de tamanho 16 bits
reg [7:0] mem_dados [0:255]; //memoria de dados com 256 posições de tamanho 8 bits
reg [7:0] banco_regs [0:15]; //banco de 32 registradores de 8 bits

task zera_meminstruc;
    integer i;
    begin
      for (i = 0; i < 256; i = i + 1) begin
        mem_instruc[i] = 16'b0;
        $display("mem_instruc[%0d]=0x%0h", i, mem_instruc[i]);
      end
    end
endtask

task zera_memdados;
    integer i;
    begin
      for (i = 0; i < 256; i = i + 1) begin
        mem_dados[i] = 8'b0;
        $display("mem_dados[%0d]=0x%0h", i, mem_dados[i]);
      end
    end
endtask

task zera_regs;
    integer i;
    begin
      for (i = 0; i < 16; i = i + 1) begin
        banco_regs[i] = 8'b0;
        $display("banco_regs[%0d]=0x%0h", i, banco_regs[i]);
      end
    end
endtask

task atribui_instrucao; //Considerar atribuir esta task direto em zerar instruções
    begin
        mem_instruc[0] = 16'b0000000100100110; // LW s2, N
        mem_instruc[1] = 16'b0001000000110010; // addi s3, x0, 1 
        mem_instruc[2] = 16'b0010001100000011; // bge s3, s2, finish
        mem_instruc[3] = 16'b1010100000000111; // addi s4, x0, 0
    end
endtask

task atribui_dados; //Considerar atribuir esta task direto em zerar dados
    begin
        mem_dados[1] = 8'b00000111; // Valor 7
        mem_dados[2] = 8'b00000011; // Valor 3
    end
endtask

initial begin //Executa de uma vez só
    zera_memdados;
    zera_meminstruc;
    zera_regs;
    atribui_instrucao;
    atribui_dados;
end

reg greater_or_equal, less; //Sinais para os Branch's (BGE e BLT).
reg desvio;
reg [7:0] PC; //Contador

// Pipeline registers
// IF/ID
reg [15:0] InIF_ID;
reg [7:0] PCIF_ID;

// ID/EX
reg [15:0] InID_EX;
reg [3:0] R1ID_EX, R2ID_EX, R2wID_EX;
reg [7:0] PCID_EX;
        //Para instrução AUIPC
    reg [7:0] ID_EX_imm8_u;
    wire signed [15:0] imm_sext  = {{8{ID_EX_imm8_u[7]}}, ID_EX_imm8_u};
    wire signed [15:0] imm_shift = imm_sext <<< 4; 
    wire greater_or_equal = (ID_EX_rs1 >= ID_EX_rs2);
    wire less            = (ID_EX_rs1 <  ID_EX_rs2);
    wire is_bge = (ID_EX_instr[3:0] == 4'b0011) && greater_or_equal;
    wire is_blt = (ID_EX_instr[3:0] == 4'b0100) && less;
    wire salto = is_bge || is_blt;


// EX/MEM
reg [7:0] ulaEX_MEM;
reg [3:0] R2EX_MEM;
reg [3:0] R2wEX_MEM, R2wMEM_WB; //Registrador a ser escrito
reg [7:0] PCEX_MEM; //Contador de programa (Program Counter) que armazena o endereço atual de execuçao.
reg [15:0] InEX_MEM; //Instrucao Atual de cada estagio

// MEM/WB
reg [7:0] PCMEM_WB;
reg [15:0] InMEM_WB;


//Atualização do PC
always @(posedge clock or posedge reset) begin
    if (reset)
      PC <= 0;
    else if (desvio == 1) begin
            if((InEX_MEM[3:0] == 4'b0011) or (InEX_MEM[3:0] == 4'b0100)) //BGE/BLT
                PC <= PC + InEX_MEM[15:12];
    end

    else if(InEX_MEM[3:0] == 4'b0101) begin//JAL
            banco_regs[InEX_MEM[7:4]] <= PC + 1;
            PC <= PC + InEX_MEM[15:8];
    end
    
        else
            PC <= PC + 1; //pensar se pode haver problemas deixando +1 ao invés de +4
  end

//IF/ID
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      PCIF_ID <= 0;
      InIF_ID <= 16'b0;
    end 
    else begin
      InIF_ID <= mem_instruc[PC];
      PCIF_ID <= PC + 1;
    end
  end

//ID/EX
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      PCID_EX <= 0;
      InID_EX <= 16'b0;
      R0ID_EX <= 8'b0;
      R1ID_EX <= 8'b0;
      R2wID_EX <= 8'b0;
    end 
    else begin
      // extrai campos
      InID_EX <= InIF_ID;
      PCID_EX <= PCIF_ID;
      ID_EX_rs2       <= IF_ID_instr[24:20];
      ID_EX_rd        <= IF_ID_instr[11:7];
      // imediato e shift para AUIPC, por exemplo
      if(InID_EX[3:0] == 4'b0101) begin //JAL
            R2wID_EX <= 8'b0;
            R1ID_EX <= 8'b0;
            R2ID_EX <= 8'b0;
            InIF_ID <= 16'b1;
            InID_EX <= 16'b1;
        end

        else if((InID_EX[3:0] == 4'b0001) or (InID_EX[3:0] == 4'b0011) or (InID_EX[3:0] == 4'b0100) or (InID_EX[3:0] == 4'b1000) or (InID_EX[3:0] == 4'b0111) or (InID_EX[3:0] == 4'b1001)) begin
            //tipos: R / S / B
            R1ID_EX <= banco_regs[InID_EX[11:8]];
            R2ID_EX <= banco_regs[InID_EX[15:12]];
        end

        else if(InID_EX[3:0] == 4'b0000) begin //AUIPC (TIPO U)
        end

        else begin //I e J (que nao utiliza)
        //considerar utilizar isso para todas as instruções ao inves de if-else e colocar a condição apenas para U
            R1ID_EX <= banco_regs[InID_EX[11:8]];
            R2wID_EX <= banco_regs[InID_EX[15:12]]; 
        end
    end
  end

//EX/MEM
 always @(posedge clock or posedge reset) begin
    if (reset) begin
      PCEX_MEM <= 0;
      InEX_MEM <= 16'b0;
      ulaEX_MEM <= 8'b0;
      R2wEX_MEM <= 8'b0;
      
    end 
    else begin
      InEX_MEM <= InID_EX;
      PCEX_MEM <= PCID_EX;
      if(desvio == 1) begin //bolhas
            ulaEX_MEM <= 8'b0;
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
                case (InEX_MEM[3:0]) //analisa opcode para realizar operações
                    4'b0000: //AUIPC
                        ulaEX_MEM <= imm_shift + (PC+1);

                    4'b0001: //ADD
                        ulaEX_MEM <= R1ID_EX + R2ID_EX;

                    4'b0001: //ADDI
                        ulaEX_MEM <= R1ID_EX + InEX_MEM[15:12];

                    4'b1001: //SUB
                        ulaEX_MEM <= R1ID_EX - R2ID_EX;

                    4'b0111: //MUL
                        ulaEX_MEM <= R1ID_EX * R2ID_EX;

                    4'b0110: //LW
                        ulaEX_MEM <= R1ID_EX + InEX_MEM[15:12];

                    4'b1000: //SW
                        ulaEX_MEM <= R1ID_EX + InEX_MEM[7:4];

                    default:
                        ulaEX_MEM <= 8'b0;

                endcase         
        end
    end
  end

//MEM/WB
 always @(posedge clock or posedge reset) begin
    if (reset) begin
        PCMEM_WB <= 0;
        InMEM_WB <= 16'b0;
        R2wMEM_WB <= 8'b0;
    end 
    else begin
        InMEM_WB <= InEX_MEM;
        PCMEM_WB <= PCEX_MEM;
        case (InMEM_WB[3:0]) //analisa opcode para realizar operações
                    4'b1000: //STORE WORD
                        mem_dados[ulaEX_MEM] <= R2wEX_MEM;

                    4'b0110: //LOAD WORD
                        banco_regs[InMEM_WB[7:4]] <= mem_dados[ulaEX_MEM];

                    4'b0000: //AUIPC
                        banco_regs[InMEM_WB[11:7]] <= ulaEX_MEM;

                    4'b0011: //BGE
                    4'b0100: //BLT
                    4'b0101: //JAL
                    4'b1111: //BOLHA

                    default: //tipo R e I
                        banco_regs[InMEM_WB[[11:7]]] <= ulaEX_MEM;
                        
                endcase 
    end
  end


endmodule

