`timescale 1ns / 1ps

module tb_pipeline;

  reg clock;
  reg reset;
  integer    i;
  // Instância do módulo principal
  RISCV_Pipeline uut (
    .clock(clock),
    .reset(reset)
  );


  reg [31:0] pc_anterior;

  //––––––––––––––––––––––––––––––––––––––––––––––––––––––
  // 1) Geraçao de clock
  initial begin
    clock = 0;
    forever #5 clock = ~clock;  // 10 ns de período
  end

  //––––––––––––––––––––––––––––––––––––––––––––––––––––––
  // 2) Pulso de reset
  initial begin
    reset = 1;
    for(i=0;i<256;i=i+1)begin
      uut.data_mem[i] = 0;
      uut.instr_mem[i] = 0;
    end
    #20;       // mantém reset alto por 20 ns
    reset = 0;
  end

  // Bloco de preload
  initial begin
      // aguarda sair do reset
      wait (reset == 0);
      // carrega os 4 valores que você quer ordenar:
     // Mergesort para 4 elementos, SEM saltos para trás (offsets negativos).
      // carrega os 4 valores que você quer ordenar:
      uut.data_mem[0] = 32'd17;
      uut.data_mem[1] = 32'd97;
      uut.data_mem[2] = 32'd52;
      uut.data_mem[3] = 32'd58;
      uut.data_mem[4] = 32'd67;
      uut.data_mem[5] = 32'd85;
      uut.data_mem[6] = 32'd101;
      uut.data_mem[7] = 32'd7;
      uut.data_mem[8] = 32'd44;
      uut.data_mem[9] = 32'd32;
      // Algoritmo Mergesort para 4 elementos
      // Formato: uut.instr_mem[index] = 32'b...;
      // --- Código de Máquina ---
      // --- Dados Iniciais (Exemplo) ---
uut.instr_mem[0] = 32'h00a00a13;

uut.instr_mem[1] = 32'h00100293;

uut.instr_mem[2] = 32'h1142d863;

uut.instr_mem[3] = 32'h00000313;

uut.instr_mem[4] = 32'h11435063;

uut.instr_mem[5] = 32'h005303b3;

uut.instr_mem[6] = 32'h0143d463;

uut.instr_mem[7] = 32'h0080006f;

uut.instr_mem[8] = 32'h000a03b3;

uut.instr_mem[9] = 32'h00129893;

uut.instr_mem[10] = 32'h01130433;

uut.instr_mem[11] = 32'h01445463;

uut.instr_mem[12] = 32'h0080006f;

uut.instr_mem[13] = 32'h000a0433;

uut.instr_mem[14] = 32'h0c83d863;

uut.instr_mem[15] = 32'h000304b3;

uut.instr_mem[16] = 32'h00038533;

uut.instr_mem[17] = 32'h000305b3;

uut.instr_mem[18] = 32'h0474d663;

uut.instr_mem[19] = 32'h04855463;

uut.instr_mem[20] = 32'h00249913;

uut.instr_mem[21] = 32'h00092603;

uut.instr_mem[22] = 32'h00251993;

uut.instr_mem[23] = 32'h0009a683;

uut.instr_mem[24] = 32'h00d64e63;

uut.instr_mem[25] = 32'h01458ab3;

uut.instr_mem[26] = 32'h002a9b13;

uut.instr_mem[27] = 32'h00db2023;

uut.instr_mem[28] = 32'h00158593;

uut.instr_mem[29] = 32'h00150513;

uut.instr_mem[30] = 32'hfd1ff06f;

uut.instr_mem[31] = 32'h01458ab3;

uut.instr_mem[32] = 32'h002a9b13;

uut.instr_mem[33] = 32'h00cb2023;

uut.instr_mem[34] = 32'h00158593;

uut.instr_mem[35] = 32'h00148493;

uut.instr_mem[36] = 32'hfb9ff06f;

uut.instr_mem[37] = 32'h0274d463;

uut.instr_mem[38] = 32'h0274d263;

uut.instr_mem[39] = 32'h00249913;

uut.instr_mem[40] = 32'h00092603;

uut.instr_mem[41] = 32'h01458ab3;

uut.instr_mem[42] = 32'h002a9b13;

uut.instr_mem[43] = 32'h00cb2023;

uut.instr_mem[44] = 32'h00158593;

uut.instr_mem[45] = 32'h00148493;

uut.instr_mem[46] = 32'hfe1ff06f;

uut.instr_mem[47] = 32'h02855463;

uut.instr_mem[48] = 32'h02855263;

uut.instr_mem[49] = 32'h00251993;

uut.instr_mem[50] = 32'h0009a683;

uut.instr_mem[51] = 32'h01458ab3;

uut.instr_mem[52] = 32'h002a9b13;

uut.instr_mem[53] = 32'h00db2023;

uut.instr_mem[54] = 32'h00158593;

uut.instr_mem[55] = 32'h00150513;

uut.instr_mem[56] = 32'hfe1ff06f;

uut.instr_mem[57] = 32'h00030bb3;

uut.instr_mem[58] = 32'h028bd063;

uut.instr_mem[59] = 32'h014b8ab3;

uut.instr_mem[60] = 32'h002a9b13;

uut.instr_mem[61] = 32'h000b2c03;

uut.instr_mem[62] = 32'h002b9c93;

uut.instr_mem[63] = 32'h018ca023;

uut.instr_mem[64] = 32'h001b8b93;

uut.instr_mem[65] = 32'hfe5ff06f;

uut.instr_mem[66] = 32'h01130333;

uut.instr_mem[67] = 32'hf05ff06f;

uut.instr_mem[68] = 32'h00129293;

uut.instr_mem[69] = 32'hef5ff06f;

uut.instr_mem[70] = 32'h000000ef;
  end
  wire signed [31:0] extended_I_TYPE = $signed(uut.IF_instr[31:20]);
  wire signed [31:0] extended_B_TYPE = $signed({uut.IF_instr[31], uut.IF_instr[7], uut.IF_instr[30:25], uut.IF_instr[11:8], 1'b0});
  wire signed [31:0] extended_S_TYPE = $signed({uut.IF_instr[31:25], uut.IF_instr[11:7]});
  wire signed [31:0] extended_J_TYPE = $signed({uut.IF_instr[31], uut.IF_instr[19:12], uut.IF_instr[20], uut.IF_instr[30:21], 1'b0});
  reg signed [31:0] MEM_imm, WB_imm, MEM_r2, WB_r1, WB_r2;
  //PRINTANDO INSTRUCAO E ASSEMBLY
  initial begin
    wait (reset == 0);
    pc_anterior = 32'b0;
    forever begin
      @(posedge clock);
      if(reset == 0) begin
        MEM_imm <= uut.EX_imm;
        WB_imm <= MEM_imm;
        MEM_r2 <= uut.EX_r2;
        WB_r1 <= uut.MEM_r1;
        WB_r2 <= MEM_r2;
        $display("\n\nPC alterado de %d para %d", pc_anterior, uut.PC);
        case (uut.IF_instr[6:0])
          7'b0110011: begin // R-Type
              case (uut.IF_instr[31:25])
                7'b0000000: $display("Instruçao IF  %b  -  ADD x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
                7'b0000001: $display("Instruçao IF  %b  -  MUL x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
                7'b0100000: $display("Instruçao IF  %b  -  SUB x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
              endcase
            end
          7'b0100011:begin
            $display("Instruçao IF  %b  -  SW x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[24:20], {uut.IF_instr[31:25], uut.IF_instr[11:7]}, uut.IF_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instruçao IF  %b  -  LW x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[11:7], extended_I_TYPE, uut.IF_instr[19:15]);
          end
          7'b1100111:begin
            $display("Instruçao IF  %b  -  JALR x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[11:7], extended_I_TYPE, uut.IF_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.IF_instr[14:12])
              3'b000: $display("Instruçao IF  %b  -  ADDI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], extended_I_TYPE);
              3'b001: $display("Instruçao IF  %b  -  SLLI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
              3'b101: $display("Instruçao IF  %b  -  SRLI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
            endcase
            
          end
          7'b1100011:begin //saltos
            case (uut.IF_instr[14:12])
              3'b101: begin
                $display("Instruçao IF  %b  -  BGE x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              end
              3'b100: begin
                $display("Instruçao IF  %b  -  BLT x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              end
              3'b001:
                $display("Instruçao IF  %b  -  BNE x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              3'b000:
                $display("Instruçao IF  %b  -  BEQ x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
            endcase
          end
          7'b1101111: begin
            $display("Instruçao IF  %b  -  JAL x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], extended_J_TYPE);
          end
          7'b0110111: $display("Instruçao IF  %b  -  LUI x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], {uut.IF_instr[31:12], 12'b0});
          7'b0010111: $display("Instruçao IF  %b  -  AUIPC x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], {uut.IF_instr[31:12], 12'b0});

          default: $display("Instruçao IF  %b", uut.IF_instr);
        endcase

        case(uut.ID_opcode)
          7'b0110011: begin // R-Type
              case (uut.ID_funct7)
                7'b0000000:$display("Instruçao ID  %b  -  ADD x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2);
                7'b0000001:$display("Instruçao ID  %b  -  MUL x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2);
                7'b0100000:$display("Instruçao ID  %b  -  SUB x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2);
              endcase
            end
          7'b0100011:begin
            $display("Instruçao ID  %b  -  SW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[24:20], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instruçao ID  %b  -  LW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.ID_funct3)
              3'b000: $display("Instruçao ID  %b  -  ADDI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_imm);
              3'b001: $display("Instruçao ID  %b  -  SLLI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_instr[24:20]);
              3'b101: $display("Instruçao ID  %b  -  SRLI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_instr[24:20]);
            endcase
          end
          7'b1100111: begin
            $display("Instruçao ID  %b  -  JALR x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b1100011:
            case (uut.ID_funct3)
              3'b101: begin
                $display("Instruçao ID  %b  -  BGE x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              end
              3'b100: begin
                $display("Instruçao ID  %b  -  BLT x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              end
              3'b001:
                $display("Instruçao ID  %b  -  BNE x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              3'b000:
                $display("Instruçao ID  %b  -  BEQ x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
            endcase
          7'b1101111: begin
            $display("Instruçao ID  %b  -  JAL x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm);
          end

          7'b0110111: $display("Instruçao ID  %b  -  LUI x%0d, %0d", uut.ID_instr, uut.ID_rd, uut.ID_imm);
          7'b0010111: $display("Instruçao ID  %b  -  AUIPC x%0d, %0d", uut.ID_instr, uut.ID_rd, uut.ID_imm);
          default: $display("Instruçao ID  %b", uut.ID_instr);
        endcase

        case(uut.EX_opcode)
          7'b0110011: begin // R-Type
              case (uut.EX_instr[31:25])
                7'b0000000:$display("Instruçao EX  %b  -  ADD x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_r1, uut.EX_r2);
                7'b0000001:$display("Instruçao EX  %b  -  MUL x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_r1, uut.EX_r2);
                7'b0100000:$display("Instruçao EX  %b  -  SUB x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_r1, uut.EX_r2);
              endcase
            end
          7'b0100011:begin
            $display("Instruçao EX  %b  -  SW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[24:20], uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instruçao EX  %b  -  LW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[11:7], uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.EX_funct3)
              3'b001: $display("Instruçao EX  %b  -  SLLI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_instr[24:20]);
              3'b101: $display("Instruçao EX  %b  -  SRLI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_instr[24:20]);
              3'b000: $display("Instruçao EX  %b  -  ADDI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_imm);
            endcase
          end
          7'b1100111: begin
            $display("Instruçao EX  %b  -  JALR x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[11:7],  uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b1100011:
            case (uut.EX_instr[14:12])
              3'b101: begin
                $display("Instruçao EX  %b  -  BGE x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              end
              3'b100: begin
                $display("Instruçao EX  %b  -  BLT x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              end
              3'b001:
                $display("Instruçao EX  %b  -  BNE x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              3'b000:
                $display("Instruçao EX  %b  -  BEQ x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
            endcase
          7'b1101111: begin
                $display("Instruçao EX  %b  -  JAL x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_imm);
          end
          7'b0110111: $display("Instruçao EX  %b  -  LUI x%0d, %0d", uut.EX_instr, uut.EX_rd, uut.EX_imm);
          7'b0010111: $display("Instruçao EX  %b  -  AUIPC x%0d, %0d", uut.EX_instr, uut.EX_rd, uut.EX_imm);
          default: $display("Instruçao EX  %b", uut.EX_instr);
        endcase

        case(uut.MEM_opcode)
          
          7'b0110011: begin // R-Type
              case (uut.MEM_instr[31:25])
                7'b0000000:$display("Instruçao MEM  %b  -  ADD x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_r1, MEM_r2);
                7'b0000001:$display("Instruçao MEM  %b  -  MUL x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_r1, MEM_r2);
                7'b0100000:$display("Instruçao MEM  %b  -  SUB x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_r1, MEM_r2);
              endcase
            end
          7'b0100011:begin
            $display("Instruçao MEM  %b  -  SW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[24:20], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instruçao MEM  %b  -  LW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.MEM_instr[14:12])
              3'b001: $display("Instruçao MEM  %b  -  SLLI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], uut.EX_instr[24:20]);
              3'b101: $display("Instruçao MEM  %b  -  SRLI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], uut.EX_instr[24:20]);
              3'b000: $display("Instruçao MEM  %b  -  ADDI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], MEM_imm);
            endcase
          end
          7'b1100111: begin
            $display("Instruçao MEM  %b  -  JALR x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b1100011:
            case (uut.MEM_instr[14:12])
              3'b101: begin
                $display("Instruçao MEM  %b  -  BGE x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
              end
              3'b100: begin
                $display("Instruçao MEM  %b  -  BLT x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
              end
              3'b001:
                $display("Instruçao MEM  %b  -  BNE x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
              3'b000:
                $display("Instruçao MEM  %b  -  BEQ x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
            endcase
          7'b1101111: begin
            $display("Instruçao MEM  %b  -  JAL x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm);
          end
          7'b0110111: $display("Instruçao MEM  %b  -  LUI x%0d, %0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_data);
          7'b0010111: $display("Instruçao MEM  %b  -  AUIPC x%0d, %0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_data);
          default: $display("Instruçao MEM  %b", uut.MEM_instr);
        endcase

        case(uut.WB_instr[6:0])
          7'b0110011: begin // R-Type
            case (uut.WB_instr[31:25])
              7'b0000000:$display("Instruçao WB  %b  -  ADD x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, WB_r1, WB_r2);
              7'b0000001:$display("Instruçao WB  %b  -  MUL x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, WB_r1, WB_r2);
              7'b0100000:$display("Instruçao WB  %b  -  SUB x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, WB_r1, WB_r2);
            endcase
          end
          7'b0100011:begin
            $display("Instruçao WB  %b  -  SW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[24:20], WB_imm, uut.WB_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instruçao WB  %b  -  LW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[11:7], WB_imm, uut.WB_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.WB_instr[14:12])
              3'b001: $display("Instruçao WB  %b  -  SLLI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], uut.EX_instr[24:20]);
              3'b101: $display("Instruçao WB  %b  -  SRLI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], uut.EX_instr[24:20]);
              3'b000: $display("Instruçao WB  %b  -  ADDI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], WB_imm);
            endcase
          end
          7'b1100111: begin
            $display("Instruçao WB  %b  -  JALR x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[11:7], WB_imm, uut.WB_instr[19:15]);
          end
          7'b1100011:
            case (uut.WB_instr[14:12])
              3'b101: begin
                $display("Instruçao WB  %b  -  BGE x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              end
              3'b100: begin
                $display("Instruçao WB  %b  -  BLT x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              end
              3'b001:
                $display("Instruçao WB  %b  -  BNE x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              3'b001:
                $display("Instruçao WB  %b  -  BEQ x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
            endcase
          7'b1101111: begin
            $display("Instruçao WB  %b  -  JAL x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], WB_imm);
          end
          7'b0110111: $display("Instruçao WB  %b  -  LUI x%0d, %0d", uut.WB_instr, uut.WB_rd, uut.WB_data);
          7'b0010111: $display("Instruçao WB  %b  -  AUIPC x%0d, %0d", uut.WB_instr, uut.WB_rd, uut.WB_data);
          default: $display("Instruçao WB  %b", uut.WB_instr);
        endcase
      //PRINTS DAS OPERAÇOES
        /*case(uut.IF_instr[6:0])
          7'b0100011:begin//sw
            //$display("SW - ETAPA ID: ID_r2 = banco_regs[%0d] = %0d", uut.IF_instr[24:20], uut.banco_regs[uut.IF_instr[24:20]]);
            //$display("Destino de escrita na mem: %0d", uut.banco_regs[uut.IF_instr[19:15]]);
          end
          7'b1100011: //blt/bge
          //$display("BLT - Etapa ID: id_r1: banco_regs[%0d] = %0d  ||  id_r2: banco_regs[%0d] = %0d",uut.IF_instr[19:15], uut.banco_regs[uut.IF_instr[19:15]], uut.IF_instr[24:20], uut.banco_regs[uut.IF_instr[24:20]]);
        endcase*/

        case (uut.ID_opcode)
          7'b0000011:begin  // LW
            //$display("Destino3: %0d", $signed(uut.EX_alu_result));
          end

          7'b0100011:begin  // SW
            //$display("Estagio ID (SW): FWDEX = %0d  ||  ID_INDICE1: %0d  ||  EX_rd: %0d  ->  ID_R2: %0d", uut.fwdEX_r2, uut.ID_indiceR2, uut.EX_rd, uut.ID_r2);
          end

          7'b1101111: begin //JAL
          //$display("flag_jump: %0d", uut.flag_jump);
          //$display("Salto -> endereço: PC %0d + %0d = %0d", uut.ID_PC, uut.ID_imm, uut.ID_imm + uut.ID_PC);
          end
        endcase

        /*case (uut.EX_opcode)
          7'b0100011:begin  // SW
            //$display("SW - ETAPA MEM: Mem_data[%0d] = %0d", uut.EX_alu_result >> 2, uut.EX_r2);
            //$display("Valor de MEM_alu_result: %0d || fwd_sw: %0d", uut.MEM_alu_result, uut.fwd_sw);
          end
          7'b0000011:  // LW
            //$display("LW - ETAPA MEM: Mem_data[%0d] = %0d", (uut.EX_alu_result >> 2), uut.MEM_data);
        endcase*/
        case(uut.MEM_opcode)
          7'b0100011:begin  // SW
            //$display("SW - ETAPA WB: Mem_data[%0d] = %0d  ||  destino: %0d", uut.MEM_alu_result >> 2, MEM_r2, uut.MEM_r1);
            //$display("Valor de MEM_alu_result: %0d || fwd_sw: %0d", uut.MEM_alu_result, uut.fwd_sw);
          end
        endcase

        //$display("Valor de ID_r1: %0d  || EX_r1: %0d", uut.ID_r1, uut.EX_r1);
        pc_anterior = uut.PC;
        $display("--------------------------------------------------------------------------------");
        $display("Reg[0]: %0d  || Reg[1]: %0d  || Reg[2]: %0d  || Reg[3]: %0d", uut.banco_regs[0], uut.banco_regs[1], uut.banco_regs[2], uut.banco_regs[3]);
        $display("Reg[4]: %0d  || Reg[5]: %0d  || Reg[6]: %0d  || Reg[7]: %0d", uut.banco_regs[4], uut.banco_regs[5], uut.banco_regs[6], uut.banco_regs[7]);
        $display("Reg[8]: %0d  || Reg[9]: %0d  || Reg[10]: %0d || Reg[11]: %0d", uut.banco_regs[8], uut.banco_regs[9], uut.banco_regs[10], uut.banco_regs[11]);
        $display("Reg[12]: %0d || Reg[13]: %0d || Reg[14]: %0d || Reg[15]: %0d", uut.banco_regs[12], uut.banco_regs[13], uut.banco_regs[14], uut.banco_regs[15]);
        $display("\ndata_mem[0] = %0d || data_mem[4] = %0d || data_mem[8]  = %0d", uut.data_mem[0], uut.data_mem[4], uut.data_mem[8]);
        $display("data_mem[1] = %0d || data_mem[5] = %0d || data_mem[9]  = %0d", uut.data_mem[1], uut.data_mem[5], uut.data_mem[9]);
        $display("data_mem[2] = %0d || data_mem[6] = %0d || data_mem[10] = %0d", uut.data_mem[2], uut.data_mem[6], uut.data_mem[10]);
        $display("data_mem[3] = %0d || data_mem[7] = %0d || data_mem[11] = %0d", uut.data_mem[3], uut.data_mem[7], uut.data_mem[11]);
        $display("--------------------------------------------------------------------------------");
        if (uut.ID_instr[6:0] == 7'b1100011) begin
          $display("=====================================================");
          $display("Comparando ID_r1: %d  ||  ID_r2: %d", uut.alu_in1, uut.alu_in2);
          $display("Resultado da comparaçao: %s", uut.branch_taken ? "TOMADO" : "NAO TOMADO");
          $display("PC alvo: %d", uut.branch_target);
          $display("====================================================");
        end
      end
    end
  end

  // 4) Espera o mergesort rodar e imprime o resultado
  initial begin
    wait (reset == 0);
    #200000;  // tempo suficiente para ordenar

    $display("\n--- Vetor ordenado em data_mem ---");
    for (i = 0; i < 32; i = i + 1)
      $display("data_mem[%0d] = %0d", i, uut.data_mem[i]);

    $finish;
  end


endmodule
