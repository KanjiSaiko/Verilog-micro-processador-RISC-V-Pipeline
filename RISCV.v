
module RISCV (clock, reset);
    input clock;
    input reset;


//memórias e registradores
reg [31:0] mem_instruc [0:65535]; //memoria de instruções com 65.536 posições de tamanho 32 bits (PC de tamanho 16 bits) (64kb)
reg [15:0] mem_dados [0:65535]; //memoria de dados com 65.536 posições de tamanho 32 bits (PC de tamanho 16 bits) (64kb)
reg [15:0] banco_regs [0:31]; //banco de 32 registradores de 16 bits
reg[15:0] ra; //x1 (ra - return adress)
reg[15:0] zero = 0; //registrador zero

task zera_meminstruc;
    integer i;
    begin
      for (i = 0; i < 65536; i = i + 1) begin
        mem_instruc[i] = 32'b0;
        $display("mem_instruc[%0d]=0x%0h", i, mem_instruc[i]);
      end
    end
endtask

task zera_memdados;
    integer i;
    begin
      for (i = 0; i < 65536; i = i + 1) begin
        mem_dados[i] = 16'b0;
        $display("mem_dados[%0d]=0x%0h", i, mem_dados[i]);
      end
    end
endtask

task zera_regs;
    integer i;
    begin
      for (i = 0; i < 32; i = i + 1) begin
        banco_regs[i] = 16'b0;
        $display("banco_regs[%0d]=0x%0h", i, banco_regs[i]);
      end
    ra = 16'b0;
    end
endtask

task atribui_instrucao; //Considerar atribuir esta task direto em zerar instruções
    begin
        //dados e setup
        mem_instruc[0] = 32'b000000000011_00000_010_10010_0000011; // LW s2, N
        mem_instruc[4] = 32'b000000000001_00000_000_10011_0010011; // addi s3, x0, 1 
        
        //width loop
        mem_instruc[8] = 32'b0000000_10010_10011_101_00100_1100011; // bge s3, s2, finish
        mem_instruc[12] = 32'b000000000000_00000_000_10100_0010011; // addi s4, x0, 0

        //inner loop (MODIFICAR OFFSET DEPOIS PARA ENDEREÇO CORRETO)
        mem_instruc[16] = 32'b0000000_10010_10100_101_00000_1100011; // bge s4, s2, next_width
        mem_instruc[20] = 32'b0000000_10011_10100_000_10101_0110011; // add s5, s4, s3
        mem_instruc[24] = 32'b111111111111_10101_000_10101_0010011; // addi s5, s5, -1
        mem_instruc[28] = 32'b0000001_00010_10011_000_00101_0110011; // mul t0, s3, 2
        mem_instruc[32] = 32'b0000000_00101_10100_000_10110_0110011; // add s6, s4, t0
        mem_instruc[36] = 32'b111111111111_10110_000_10110_0010011; // addi s6, s6, -1
        mem_instruc[40] = 32'b000000000111_00000_000_00110_0010011; // addi t1, x0, 7
        mem_instruc[44] = 32'b00000001010100110100000001100011; // blt t1, s5, inc_l
        mem_instruc[48] = 32'b00000000011010110100000001100011; // blt s6, t1, do_merge
        mem_instruc[52] = 32'b00000000000000110000101100110011; // add s6, t1, x0

        //do merge
        mem_instruc[32] = 32'b00000000000010100000101110110011; // add s7, s4, x0
        mem_instruc[32] = 32'b00000000000110101000110000010011; // add s8, s5, 1
        mem_instruc[32] = 32'b00000000000010100000110010110011; // add s9, s4, x0
    end
endtask

task atribui_dados; //Considerar atribuir esta task direto em zerar dados
    begin
         // vetor A (.word 29, 10, 14, 37, …)
        mem_dados[0] = 16'b0000000000011101;  // A[0] = 29
        mem_dados[1] = 16'b0000000000001010;  // A[1] = 10
        mem_dados[2] = 16'b0000000000001110;  // A[2] = 14
        mem_dados[3] = 16'b0000000000100101;  // A[3] = 37

        mem_dados[10] = 16'b0000000000001000; // Valor 8 (Numero de elementos no vetor a ser ordenado)
    end
endtask

initial begin //Executa de uma vez só
    zera_memdados;
    zera_meminstruc;
    zera_regs;
    atribui_instrucao;
    atribui_dados;
end

reg [15:0] PC; //Contador
// Pipeline registers
// IF/ID
reg [31:0] InIF_ID;
reg [15:0] PCIF_ID;

// ID/EX
reg [31:0] InID_EX;
reg [6:0] OpcodeID_EX;
reg[6:0] Funct7;
reg[2:0] Funct3;
reg[19:0] immID_EX;
reg [4:0] R1ID_EX, R2ID_EX, RdID_EX;
reg [15:0] PCID_EX;


// EX/MEM
reg[31:0] InEX_MEM;
reg [15:0] PCEX_MEM;
reg[6:0] OpcodeEX_MEM;
reg[19:0] immEX_MEM;
reg [4:0] RdEX_MEM;
reg [31:0] ulaEX_MEM;
reg salto, salto_jal;
//Para instrução AUIPC
reg [15:0] imm_sext  = {{8{immID_EX[7]}}, immID_EX};
reg [15:0] imm_shift = imm_sext <<< 4; 

// MEM/WB
reg[31:0] InMEM_WB;

//Atualização do PC
always @(posedge clock or posedge reset) begin
    if (reset) begin
      PC <= 0;
      ra <= 0;
    end
    else if (salto == 1) begin //BGE/BLT
            if(InMEM_WB[6:0] == 7'b1100011) //confirmo que a instrução de salto que sera realmente realizada
                PC <= PC + immEX_MEM;
    end

    else if(salto_jal) begin//JAL
            ra <= PC + 4;
            PC <= next_PC;
    end
    
      else
          PC <= PC + 4; //pensar se pode haver problemas deixando +1 ao invés de +4
  end

//IF/ID
  always @(posedge clock or posedge reset) begin
    if (reset || salto) begin
      PCIF_ID <= 0;
      InIF_ID <= 0;
    end 
    else begin
      InIF_ID <= mem_instruc[PC];
      PCIF_ID <= PC + 4;
    end
  end

//ID/EX
  always @(posedge clock or posedge reset) begin
    if (reset || salto) begin
      R1ID_EX <= 0;
      R2ID_EX <= 0;
      RdID_EX <= 0;
      PCID_EX <= 0;

      InID_EX <= 0;
      OpcodeID_EX <= 0;
      immID_EX <= 0;
      Funct3 <= 0;
      Funct7 <= 0;
    end 
    else begin
      // extrai campos
      InID_EX <= InIF_ID;
      PCID_EX <= PCIF_ID;
      OpcodeID_EX <= InIF_ID[6:0];

      case (InID_EX[6:0])
          7'b1101111: begin//JAL
            RdID_EX <= InIF_ID[11:7];
            immID_EX <= InIF_ID[31:12];
          end

          7'b0110011:begin //Tipo R
            R1ID_EX <= banco_regs[InIF_ID[19:15]];
            R2ID_EX <= banco_regs[InIF_ID[24:20]];
            RdID_EX <= IF_ID_instr[11:7];
            Funct3 <= InIF_ID[14:12];
            Funct7 <= InIF_ID[31:25];
          end

          7'b0010011, //tipo I
          7'b0000011:begin
            immID_EX <= {8'b0, InIF_ID[31:20]};
            R1ID_EX <= banco_regs[InIF_ID[19:15]];
            RdID_EX <= IF_ID_instr[11:7];
            Funct3 <= InIF_ID[14:12];
          end

          7'b0100011:begin //Tipo S (SW)
            R1ID_EX <= banco_regs[InIF_ID[19:15]];
            R2ID_EX <= banco_regs[InIF_ID[24:20]];
            immID_EX <= {8'b0, InIF_ID[31:25], InIF_ID[11:7]};
            Funct3 <= InIF_ID[14:12];
          end

          7'b1100011: begin// BGE/BLT
            R1ID_EX <= banco_regs[InIF_ID[19:15]];
            R2ID_EX <= banco_regs[InIF_ID[24:20]];
            immID_EX <= {8'b0, InIF_ID[31:25], InIF_ID[11:7]};
            Funct3 <= InIF_ID[14:12];
          end

          7'b0010111: begin//AUIPC
            RdID_EX <= IF_ID_instr[11:7];
            immID_EX <= InIF_ID[31:12]
          end
            

      endcase
    end
  end

//EX/MEM
 always @(posedge clock or posedge reset) begin
    
    if (reset || salto) begin
      OpcodeEX_MEM <= 0;
      InEX_MEM <= 0;
      ulaEX_MEM <= 0;
      immEX_MEM <= 0;
      salto <= 0;
    end

    else begin
      InEX_MEM <= InID_EX;
      OpcodeEX_MEM <= OpcodeID_EX;
      RdEX_MEM <= RdID_EX;
      immEX_MEM <= immID_EX;
        case (OpcodeID_EX) //analisa opcode para realizar operações
          7'b00101110: //AUIPC
              ulaEX_MEM <= imm_shift + (PC+4);

          7'b0110011: begin//Tipo R
            case (Funct7)
              7'b0000000: //ADD
                ulaEX_MEM <= R1ID_EX + R2ID_EX;

              7'b0100000: //SUB
                ulaEX_MEM <= R1ID_EX - R2ID_EX;
              
              7'b0000001: //MUL
                ulaEX_MEM <= R1ID_EX * R2ID_EX;
            endcase
          end

          7'b0010011, //ADDI
          7'b0000011, //LW
          7'b0100011: //SW
              ulaEX_MEM <= R1ID_EX + immID_EX;

          7'b1100011: begin//saltos condicionais
            if(Funct3 == 3'b101 and R1ID_EX >= R2ID_EX) //bge
              salto <= 1;
            else if(Funct3 == 3'b100 and R1ID_EX < R2ID_EX) //blt
              salto <= 1;
            else
              salto <= 0;

          end

          7'b1101111: begin//JAL
            InIF_ID <= 16'b0;
            InID_EX <= 16'b0;
            InEX_MEM <= 16'b0;
            ulaEX_MEM <= 8'b0;
            R1ID_EX <= 8'b0;
            R2ID_EX <= 8'b0;
            
            next_PC <= PCID_EX + immID_EX;
            salto_jal <= 1;
          end

          default:
              ulaEX_MEM <= 8'b0;

        endcase         
      end
  end

//MEM/WB
 always @(posedge clock or posedge reset) begin
    if (reset) begin
      InMEM_WB <= 0;
    end 
    else begin
      InMEM_WB <= InEX_MEM;
        case (OpcodeEX_MEM) //analisa opcode para realizar operações
            7'b0100011: //STORE WORD
                mem_dados[ulaEX_MEM] <= RdEX_MEM;

            7'b0000011: //LOAD WORD
                banco_regs[RdEX_MEM] <= mem_dados[ulaEX_MEM];

            7'b0010111: //AUIPC
                banco_regs[RdEX_MEM] <= ulaEX_MEM;

            7'b0110011, //tipo R e addi
            7'b0010011:
              banco_regs[RdEX_MEM] <= ulaEX_MEM;

            default:          
                
        endcase 
    end
  end


endmodule

