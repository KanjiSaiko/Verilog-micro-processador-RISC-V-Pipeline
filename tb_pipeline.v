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
  // 1) Geracao de clock
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
      uut.data_mem[0] = 32'd167;
      uut.data_mem[1] = 32'd165;
      uut.data_mem[2] = 32'd186;
      uut.data_mem[3] = 32'd172;
      uut.data_mem[4] = 32'd94;
      uut.data_mem[5] = 32'd165;
      uut.data_mem[6] = 32'd60;
      uut.data_mem[7] = 32'd130;
      uut.data_mem[8] = 32'd13;
      uut.data_mem[9] = 32'd121;
      uut.data_mem[10] = 32'd79;
      uut.data_mem[11] = 32'd170;
      uut.data_mem[12] = 32'd106;
      uut.data_mem[13] = 32'd59;
      uut.data_mem[14] = 32'd190;
      uut.data_mem[15] = 32'd136;
      uut.data_mem[16] = 32'd196;
      uut.data_mem[17] = 32'd159;
      uut.data_mem[18] = 32'd59;
      uut.data_mem[19] = 32'd137;
      uut.data_mem[20] = 32'd49;
      uut.data_mem[21] = 32'd142;
      uut.data_mem[22] = 32'd86;
      uut.data_mem[23] = 32'd123;
      uut.data_mem[24] = 32'd102;
      uut.data_mem[25] = 32'd11;
      uut.data_mem[26] = 32'd8;
      uut.data_mem[27] = 32'd25;
      uut.data_mem[28] = 32'd71;
      uut.data_mem[29] = 32'd199;
      uut.data_mem[30] = 32'd40;
      uut.data_mem[31] = 32'd146;
      uut.data_mem[32] = 32'd138;
      uut.data_mem[33] = 32'd195;
      uut.data_mem[34] = 32'd19;
      uut.data_mem[35] = 32'd14;
      uut.data_mem[36] = 32'd170;
      uut.data_mem[37] = 32'd138;
      uut.data_mem[38] = 32'd88;
      uut.data_mem[39] = 32'd15;
      uut.data_mem[40] = 32'd104;
      uut.data_mem[41] = 32'd52;
      uut.data_mem[42] = 32'd156;
      uut.data_mem[43] = 32'd105;
      uut.data_mem[44] = 32'd54;
      uut.data_mem[45] = 32'd99;
      uut.data_mem[46] = 32'd65;
      uut.data_mem[47] = 32'd151;
      uut.data_mem[48] = 32'd6;
      uut.data_mem[49] = 32'd73;
      // Algoritmo Mergesort para 4 elementos
      // Formato: uut.instr_mem[index] = 32'b...;
      // --- Código de Máquina ---
      // --- Dados Iniciais (Exemplo) ---
// main
uut.instr_mem[0] = 32'h03200a13; // addi	s4,zero,50
uut.instr_mem[1] = 32'h00100293; // addi	t0,zero,1
// width_loop
uut.instr_mem[2] = 32'h1142d863; // bge	t0,s4,118 <done>
uut.instr_mem[3] = 32'h00000313; // addi	t1,zero,0
// i_loop
uut.instr_mem[4] = 32'h11435063; // bge	t1,s4,110 <after_i_loop>
uut.instr_mem[5] = 32'h005303b3; // add	t2,t1,t0
uut.instr_mem[6] = 32'h0143d463; // bge	t2,s4,20 <mid_eq_N>
uut.instr_mem[7] = 32'h0080006f; // jal	zero,24 <cont1>
// mid_eq_N
uut.instr_mem[8] = 32'h000a03b3; // add	t2,s4,zero
// cont1
uut.instr_mem[9] = 32'h00129893; // slli	a7,t0,0x1
uut.instr_mem[10] = 32'h01130433; // add	s0,t1,a7
uut.instr_mem[11] = 32'h01445463; // bge	s0,s4,34 <end_eq_N>
uut.instr_mem[12] = 32'h0080006f; // jal	zero,38 <cont2>
// end_eq_N
uut.instr_mem[13] = 32'h000a0433; // add	s0,s4,zero
// cont2
uut.instr_mem[14] = 32'h0c83d863; // bge	t2,s0,108 <after_merge>
uut.instr_mem[15] = 32'h000304b3; // add	s1,t1,zero
uut.instr_mem[16] = 32'h00038533; // add	a0,t2,zero
uut.instr_mem[17] = 32'h000305b3; // add	a1,t1,zero
// merge_loop
uut.instr_mem[18] = 32'h0474da63; // bge	s1,t2,9c <merge_left_loop>
uut.instr_mem[19] = 32'h04855863; // bge	a0,s0,9c <merge_left_loop>
uut.instr_mem[20] = 32'h00249913; // slli	s2,s1,0x2
uut.instr_mem[21] = 32'h00092603; // lw	a2,0(s2)
uut.instr_mem[24] = 32'h00251993; // slli	s3,a0,0x2
uut.instr_mem[25] = 32'h0009a683; // lw	a3,0(s3)
uut.instr_mem[26] = 32'h00d64e63; // blt	a2,a3,84 <left_smaller>
// right_smaller
uut.instr_mem[27] = 32'h01458ab3; // add	s5,a1,s4
uut.instr_mem[28] = 32'h002a9b13; // slli	s6,s5,0x2
uut.instr_mem[29] = 32'h00db2023; // sw	a3,0(s6)
uut.instr_mem[30] = 32'h00158593; // addi	a1,a1,1
uut.instr_mem[31] = 32'h00150513; // addi	a0,a0,1
uut.instr_mem[32] = 32'hfc9ff06f; // jal	zero,48 <merge_loop>
// left_smaller
uut.instr_mem[33] = 32'h01458ab3; // add	s5,a1,s4
uut.instr_mem[34] = 32'h002a9b13; // slli	s6,s5,0x2
uut.instr_mem[35] = 32'h00cb2023; // sw	a2,0(s6)
uut.instr_mem[36] = 32'h00158593; // addi	a1,a1,1
uut.instr_mem[37] = 32'h00148493; // addi	s1,s1,1
uut.instr_mem[38] = 32'hfb1ff06f; // jal	zero,48 <merge_loop>
// merge_left_loop
uut.instr_mem[39] = 32'h0274d263; // bge	s1,t2,c0 <copy_right_remaining>
uut.instr_mem[40] = 32'h00249913; // slli	s2,s1,0x2
uut.instr_mem[41] = 32'h00092603; // lw	a2,0(s2)
uut.instr_mem[42] = 32'h01458ab3; // add	s5,a1,s4
uut.instr_mem[43] = 32'h002a9b13; // slli	s6,s5,0x2
uut.instr_mem[44] = 32'h00cb2023; // sw	a2,0(s6)
uut.instr_mem[45] = 32'h00158593; // addi	a1,a1,1
uut.instr_mem[46] = 32'h00148493; // addi	s1,s1,1
uut.instr_mem[47] = 32'hfe1ff06f; // jal	zero,9c <merge_left_loop>
// copy_right_remaining
uut.instr_mem[48] = 32'h02855263; // bge	a0,s0,e4 <copy_back>
uut.instr_mem[49] = 32'h00251993; // slli	s3,a0,0x2
uut.instr_mem[50] = 32'h0009a683; // lw	a3,0(s3)
uut.instr_mem[51] = 32'h01458ab3; // add	s5,a1,s4
uut.instr_mem[52] = 32'h002a9b13; // slli	s6,s5,0x2
uut.instr_mem[53] = 32'h00db2023; // sw	a3,0(s6)
uut.instr_mem[54] = 32'h00158593; // addi	a1,a1,1
uut.instr_mem[55] = 32'h00150513; // addi	a0,a0,1
uut.instr_mem[56] = 32'hfe1ff06f; // jal	zero,c0 <copy_right_remaining>
// copy_back
uut.instr_mem[57] = 32'h00030bb3; // add	s7,t1,zero
// copy_back_loop
uut.instr_mem[58] = 32'h028bd063; // bge	s7,s0,108 <after_merge>
uut.instr_mem[59] = 32'h014b8ab3; // add	s5,s7,s4
uut.instr_mem[60] = 32'h002a9b13; // slli	s6,s5,0x2
uut.instr_mem[61] = 32'h000b2c03; // lw	s8,0(s6)
uut.instr_mem[62] = 32'h002b9c93; // slli	s9,s7,0x2
uut.instr_mem[63] = 32'h018ca023; // sw	s8,0(s9)
uut.instr_mem[64] = 32'h001b8b93; // addi	s7,s7,1
uut.instr_mem[65] = 32'hfe5ff06f; // jal	zero,e8 <copy_back_loop>
// after_merge
uut.instr_mem[66] = 32'h01130333; // add	t1,t1,a7
uut.instr_mem[67] = 32'hf05ff06f; // jal	zero,10 <i_loop>
// after_i_loop
uut.instr_mem[68] = 32'h00129293; // slli	t0,t0,0x1
uut.instr_mem[69] = 32'hef5ff06f; // jal	zero,8 <width_loop>
// done
uut.instr_mem[70] = 32'h000000ef; // jal	ra,118 <done>
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
      $display("\n\nPC: %d", pc_anterior);
      case (uut.IF_instr[6:0])
          7'b0110011: begin // R-Type
              case (uut.IF_instr[31:25])
                7'b0000000: $display("Instrucao IF  %b  -  ADD x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
                7'b0000001: $display("Instrucao IF  %b  -  MUL x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
                7'b0100000: $display("Instrucao IF  %b  -  SUB x%0d, x%0d, x%0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
              endcase
            end
          7'b0100011:begin
            $display("Instrucao IF  %b  -  SW x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[24:20], {uut.IF_instr[31:25], uut.IF_instr[11:7]}, uut.IF_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrucao IF  %b  -  LW x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[11:7], extended_I_TYPE, uut.IF_instr[19:15]);
          end
          7'b1100111:begin
            $display("Instrucao IF  %b  -  JALR x%0d, %0d(x%0d)", uut.IF_instr, uut.IF_instr[11:7], extended_I_TYPE, uut.IF_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.IF_instr[14:12])
              3'b000: $display("Instrucao IF  %b  -  ADDI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], extended_I_TYPE);
              3'b001: $display("Instrucao IF  %b  -  SLLI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
              3'b101: $display("Instrucao IF  %b  -  SRLI x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], uut.IF_instr[19:15], uut.IF_instr[24:20]);
            endcase
            
          end
          7'b1100011:begin //saltos
            case (uut.IF_instr[14:12])
              3'b101: begin
                $display("Instrucao IF  %b  -  BGE x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              end
              3'b100: begin
                $display("Instrucao IF  %b  -  BLT x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              end
              3'b001:
                $display("Instrucao IF  %b  -  BNE x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
              3'b000:
                $display("Instrucao IF  %b  -  BEQ x%0d, x%0d, %0d", uut.IF_instr, uut.IF_instr[19:15], uut.IF_instr[24:20], extended_B_TYPE);
            endcase
          end
          7'b1101111: begin
            $display("Instrucao IF  %b  -  JAL x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], extended_J_TYPE);
          end
          7'b0110111: $display("Instrucao IF  %b  -  LUI x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], {uut.IF_instr[31:12], 12'b0});
          7'b0010111: $display("Instrucao IF  %b  -  AUIPC x%0d, %0d", uut.IF_instr, uut.IF_instr[11:7], {uut.IF_instr[31:12], 12'b0});

          default: $display("Instrucao IF  %b", uut.IF_instr);
      endcase

      case(uut.ID_opcode)
          7'b0110011: begin // R-Type
              case (uut.ID_funct7)
                7'b0000000:$display("Instrucao ID  %b  -  ADD x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_indiceR1, uut.ID_indiceR2);
                7'b0000001:$display("Instrucao ID  %b  -  MUL x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_indiceR1, uut.ID_indiceR2);
                7'b0100000:$display("Instrucao ID  %b  -  SUB x%0d, x%0d, x%0d", uut.ID_instr, uut.ID_rd, uut.ID_indiceR1, uut.ID_indiceR2);
              endcase
            end
          7'b0100011:begin
            $display("Instrucao ID  %b  -  SW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[24:20], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrucao ID  %b  -  LW x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.ID_funct3)
              3'b000: $display("Instrucao ID  %b  -  ADDI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_imm);
              3'b001: $display("Instrucao ID  %b  -  SLLI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_instr[24:20]);
              3'b101: $display("Instrucao ID  %b  -  SRLI x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_instr[19:15], uut.ID_instr[24:20]);
            endcase
          end
          7'b1100111: begin
            $display("Instrucao ID  %b  -  JALR x%0d, %0d(x%0d)", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm, uut.ID_instr[19:15]);
          end
          7'b1100011:
            case (uut.ID_funct3)
              3'b101: begin
                $display("Instrucao ID  %b  -  BGE x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              end
              3'b100: begin
                $display("Instrucao ID  %b  -  BLT x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              end
              3'b001:
                $display("Instrucao ID  %b  -  BNE x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
              3'b000:
                $display("Instrucao ID  %b  -  BEQ x%0d, x%0d, %0d", uut.ID_instr, uut.ID_instr[19:15], uut.ID_instr[24:20], uut.ID_imm);
            endcase
          7'b1101111: begin
            $display("Instrucao ID  %b  -  JAL x%0d, %0d", uut.ID_instr, uut.ID_instr[11:7], uut.ID_imm);
          end

          7'b0110111: $display("Instrucao ID  %b  -  LUI x%0d, %0d", uut.ID_instr, uut.ID_rd, uut.ID_imm);
          7'b0010111: $display("Instrucao ID  %b  -  AUIPC x%0d, %0d", uut.ID_instr, uut.ID_rd, uut.ID_imm);
          default: $display("Instrucao ID  %b", uut.ID_instr);
      endcase

      case(uut.EX_opcode)
          7'b0110011: begin // R-Type
              case (uut.EX_instr[31:25])
                7'b0000000:$display("Instrucao EX  %b  -  ADD x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_instr[19:15], uut.EX_instr[24:20]);
                7'b0000001:$display("Instrucao EX  %b  -  MUL x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_instr[19:15], uut.EX_instr[24:20]);
                7'b0100000:$display("Instrucao EX  %b  -  SUB x%0d, x%0d, x%0d", uut.EX_instr, uut.EX_rd, uut.EX_instr[19:15], uut.EX_instr[24:20]);
              endcase
            end
          7'b0100011:begin
            $display("Instrucao EX  %b  -  SW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[24:20], uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrucao EX  %b  -  LW x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[11:7], uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.EX_funct3)
              3'b001: $display("Instrucao EX  %b  -  SLLI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_instr[24:20]);
              3'b101: $display("Instrucao EX  %b  -  SRLI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_instr[24:20]);
              3'b000: $display("Instrucao EX  %b  -  ADDI x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_instr[19:15], uut.EX_imm);
            endcase
          end
          7'b1100111: begin
            $display("Instrucao EX  %b  -  JALR x%0d, %0d(x%0d)", uut.EX_instr, uut.EX_instr[11:7],  uut.EX_imm, uut.EX_instr[19:15]);
          end
          7'b1100011:
            case (uut.EX_instr[14:12])
              3'b101: begin
                $display("Instrucao EX  %b  -  BGE x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              end
              3'b100: begin
                $display("Instrucao EX  %b  -  BLT x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              end
              3'b001:
                $display("Instrucao EX  %b  -  BNE x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
              3'b000:
                $display("Instrucao EX  %b  -  BEQ x%0d, x%0d, %0d", uut.EX_instr, uut.EX_instr[19:15], uut.EX_instr[24:20], uut.EX_imm);
            endcase
          7'b1101111: begin
                $display("Instrucao EX  %b  -  JAL x%0d, %0d", uut.EX_instr, uut.EX_instr[11:7], uut.EX_imm);
          end
          7'b0110111: $display("Instrucao EX  %b  -  LUI x%0d, %0d", uut.EX_instr, uut.EX_rd, uut.EX_imm);
          7'b0010111: $display("Instrucao EX  %b  -  AUIPC x%0d, %0d", uut.EX_instr, uut.EX_rd, uut.EX_imm);
          default: $display("Instrucao EX  %b", uut.EX_instr);
      endcase

      case(uut.MEM_opcode)
          
          7'b0110011: begin // R-Type
              case (uut.MEM_instr[31:25])
                7'b0000000:$display("Instrucao MEM  %b  -  ADD x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_instr[19:15], uut.MEM_instr[24:20]);
                7'b0000001:$display("Instrucao MEM  %b  -  MUL x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_instr[19:15], uut.MEM_instr[24:20]);
                7'b0100000:$display("Instrucao MEM  %b  -  SUB x%0d, x%0d, x%0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_instr[19:15], uut.MEM_instr[24:20]);
              endcase
            end
          7'b0100011:begin
            $display("Instrucao MEM  %b  -  SW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[24:20], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrucao MEM  %b  -  LW x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.MEM_instr[14:12])
              3'b001: $display("Instrucao MEM  %b  -  SLLI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], uut.MEM_instr[24:20]);
              3'b101: $display("Instrucao MEM  %b  -  SRLI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], uut.MEM_instr[24:20]);
              3'b000: $display("Instrucao MEM  %b  -  ADDI x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], uut.MEM_instr[19:15], MEM_imm);
            endcase
          end
          7'b1100111: begin
            $display("Instrucao MEM  %b  -  JALR x%0d, %0d(x%0d)", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm, uut.MEM_instr[19:15]);
          end
          7'b1100011:
            case (uut.MEM_instr[14:12])
              3'b101: begin
                $display("Instrucao MEM  %b  -  BGE x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
              end
              3'b100: begin
                $display("Instrucao MEM  %b  -  BLT x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
              end
              3'b001:
                $display("Instrucao MEM  %b  -  BNE x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
              3'b000:
                $display("Instrucao MEM  %b  -  BEQ x%0d, x%0d, %0d", uut.MEM_instr, uut.MEM_instr[19:15], uut.MEM_instr[24:20], MEM_imm);
            endcase
          7'b1101111: begin
            $display("Instrucao MEM  %b  -  JAL x%0d, %0d", uut.MEM_instr, uut.MEM_instr[11:7], MEM_imm);
          end
          7'b0110111: $display("Instrucao MEM  %b  -  LUI x%0d, %0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_data);
          7'b0010111: $display("Instrucao MEM  %b  -  AUIPC x%0d, %0d", uut.MEM_instr, uut.MEM_rd, uut.MEM_data);
          default: $display("Instrucao MEM  %b", uut.MEM_instr);
      endcase

      case(uut.WB_instr[6:0])
          7'b0110011: begin // R-Type
            case (uut.WB_instr[31:25])
              7'b0000000:$display("Instrucao WB  %b  -  ADD x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, uut.WB_instr[19:15], uut.WB_instr[24:20]);
              7'b0000001:$display("Instrucao WB  %b  -  MUL x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, uut.WB_instr[19:15], uut.WB_instr[24:20]);
              7'b0100000:$display("Instrucao WB  %b  -  SUB x%0d, x%0d, x%0d", uut.WB_instr, uut.WB_rd, uut.WB_instr[19:15], uut.WB_instr[24:20]);
            endcase
          end
          7'b0100011:begin
            $display("Instrucao WB  %b  -  SW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[24:20], WB_imm, uut.WB_instr[19:15]);
          end
          7'b0000011: begin
            $display("Instrucao WB  %b  -  LW x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[11:7], WB_imm, uut.WB_instr[19:15]);
          end
          7'b0010011: begin
            case(uut.WB_instr[14:12])
              3'b001: $display("Instrucao WB  %b  -  SLLI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], uut.WB_instr[24:20]);
              3'b101: $display("Instrucao WB  %b  -  SRLI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], uut.WB_instr[24:20]);
              3'b000: $display("Instrucao WB  %b  -  ADDI x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], uut.WB_instr[19:15], WB_imm);
            endcase
          end
          7'b1100111: begin
            $display("Instrucao WB  %b  -  JALR x%0d, %0d(x%0d)", uut.WB_instr, uut.WB_instr[11:7], WB_imm, uut.WB_instr[19:15]);
          end
          7'b1100011:
            case (uut.WB_instr[14:12])
              3'b101: begin
                $display("Instrucao WB  %b  -  BGE x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              end
              3'b100: begin
                $display("Instrucao WB  %b  -  BLT x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              end
              3'b001:
                $display("Instrucao WB  %b  -  BNE x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
              3'b001:
                $display("Instrucao WB  %b  -  BEQ x%0d, x%0d, %0d", uut.WB_instr, uut.WB_instr[19:15], uut.WB_instr[24:20], WB_imm);
            endcase
          7'b1101111: begin
            $display("Instrucao WB  %b  -  JAL x%0d, %0d", uut.WB_instr, uut.WB_instr[11:7], WB_imm);
          end
          7'b0110111: $display("Instrucao WB  %b  -  LUI x%0d, %0d", uut.WB_instr, uut.WB_rd, uut.WB_data);
          7'b0010111: $display("Instrucao WB  %b  -  AUIPC x%0d, %0d", uut.WB_instr, uut.WB_rd, uut.WB_data);
          default: $display("Instrucao WB  %b", uut.WB_instr);
      endcase
      //PRINTS DAS OPERAcOES
      /*case(uut.IF_instr[6:0])
          7'b0110011: begin // R-Type
              case (uut.IF_instr[31:25])
                7'b0000000:begin
                  $display("Instrucao ADD  - %0d + %0d = %0d", uut.banco_regs[uut.IF_instr[19:15]], uut.banco_regs[uut.IF_instr[24:20]], uut.banco_regs[uut.IF_instr[19:15]]+uut.banco_regs[uut.IF_instr[24:20]]);
                end
                //7'b0000001:$display("", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2);
                //7'b0100000:$display("", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2);
              endcase
          end
          7'b0100011:begin//sw
            $display("Estagio IF (SW): Indice_R2: %0d", uut.fwd_WB_to_EX_for_StoreData, uut.IF_instr[24:20]);
            //$display("Destino de escrita na mem: %0d", uut.banco_regs[uut.IF_instr[19:15]]);
          end
          //7'b1100011: //blt/bge
          //$display("BLT - Etapa ID: id_r1: banco_regs[%0d] = %0d  ||  id_r2: banco_regs[%0d] = %0d",uut.IF_instr[19:15], uut.banco_regs[uut.IF_instr[19:15]], uut.IF_instr[24:20], uut.banco_regs[uut.IF_instr[24:20]]);
      endcase*/

      /*case (uut.ID_opcode)
          7'b0110011: begin // R-Type
              case (uut.ID_funct7)
                7'b0000000:begin
                  //$display("Instrucao ADD  - %0d + %0d = %0d", uut.ID_r1, uut.ID_r2, uut.ID_r2 + uut.ID_r1);
                end
                //7'b0000001:$display("", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2);
                //7'b0100000:$display("", uut.ID_instr, uut.ID_rd, uut.ID_r1, uut.ID_r2);
              endcase
          end
          7'b0000011:begin  // LW
            //$display("Destino3: %0d", $signed(uut.EX_alu_result));
          end

          7'b0100011:begin  // SW
            
          end

          7'b1101111: begin //JAL
          //$display("flag_jump: %0d", uut.flag_jump);
          //$display("Salto -> endereco: PC %0d + %0d = %0d", uut.ID_PC, uut.ID_imm, uut.ID_imm + uut.ID_PC);
          end
          7'b1100011:begin
            $display("Valor dos regs estagio ID: %b ||  ID_r1: %0d", uut.ID_instr,  uut.ID_r1);
            $display("fwd_EX: %0d || fwd_MEM: %0d || fwd_WB: %0d || aluin1: %0d  aluin2: %0d", uut.fwdEX_r1, uut.fwdMEM_r1, uut.fwdWB_r1, uut.alu_in1, uut.alu_in2);
          end
      endcase*/

        /*case (uut.EX_opcode)
          7'b0100011:begin  // SW
            //$display("SW - ETAPA MEM: Mem_data[%0d] = %0d", uut.EX_alu_result >> 2, uut.EX_r2);
            //$display("Valor de MEM_alu_result: %0d || fwd_sw: %0d", uut.MEM_alu_result, uut.fwd_sw);
          end
          7'b0000011:  // LW
            //$display("LW - ETAPA MEM: Mem_data[%0d] = %0d", (uut.EX_alu_result >> 2), uut.MEM_data);
        endcase*/
        /*case(uut.MEM_opcode)
          7'b0100011:begin  // SW
            //$display("SW - ETAPA WB: Mem_data[%0d] = %0d  ||  destino: %0d", uut.MEM_alu_result >> 2, MEM_r2, uut.MEM_r1);
            //$display("Valor de MEM_alu_result: %0d || fwd_sw: %0d", uut.MEM_alu_result, uut.fwd_sw);
          end
        endcase*/

        //$display("Valor de ID_r1: %0d  || EX_r1: %0d", uut.ID_r1, uut.EX_r1);
      pc_anterior = uut.PC;
      $display("--------------------------------------------------------------------------------");
      $display("Reg[0]: %0d   || Reg[1]: %0d   || Reg[2]: %0d   || Reg[3]: %0d", uut.banco_regs[0], uut.banco_regs[1], uut.banco_regs[2], uut.banco_regs[3]);
      $display("Reg[4]: %0d   || Reg[5]: %0d   || Reg[6]: %0d   || Reg[7]: %0d", uut.banco_regs[4], uut.banco_regs[5], uut.banco_regs[6], uut.banco_regs[7]);
      $display("Reg[8]: %0d   || Reg[9]: %0d   || Reg[10]: %0d  || Reg[11]: %0d", uut.banco_regs[8], uut.banco_regs[9], uut.banco_regs[10], uut.banco_regs[11]);
      $display("Reg[12]: %0d  || Reg[13]: %0d  || Reg[14]: %0d  || Reg[15]: %0d", uut.banco_regs[12], uut.banco_regs[13], uut.banco_regs[14], uut.banco_regs[15]);
      $display("Reg[16]: %0d  || Reg[17]: %0d  || Reg[18]: %0d  || Reg[19]: %0d", uut.banco_regs[16], uut.banco_regs[17], uut.banco_regs[18], uut.banco_regs[19]);
      $display("Reg[20]: %0d  || Reg[21]: %0d  || Reg[22]: %0d  || Reg[23]: %0d", uut.banco_regs[20], uut.banco_regs[21], uut.banco_regs[22], uut.banco_regs[23]);
      $display("Reg[24]: %0d  || Reg[25]: %0d  || Reg[26]: %0d  || Reg[27]: %0d", uut.banco_regs[24], uut.banco_regs[25], uut.banco_regs[26], uut.banco_regs[27]);
      $display("Reg[28]: %0d  || Reg[29]: %0d  || Reg[30]: %0d  || Reg[31]: %0d\n", uut.banco_regs[28], uut.banco_regs[29], uut.banco_regs[30], uut.banco_regs[31]);
      $display("data_mem[0] = %0d   || data_mem[1] = %0d    || data_mem[2]  = %0d    || data_mem[3] = %0d", uut.data_mem[0], uut.data_mem[1], uut.data_mem[2], uut.data_mem[3]);
      $display("data_mem[4] = %0d     || data_mem[5] = %0d    || data_mem[6]  = %0d    || data_mem[7] = %0d", uut.data_mem[4], uut.data_mem[5], uut.data_mem[6], uut.data_mem[7]);
      $display("data_mem[8] = %0d     || data_mem[9] = %0d    || data_mem[10]  = %0d   || data_mem[11] = %0d", uut.data_mem[8], uut.data_mem[9], uut.data_mem[10], uut.data_mem[11]);
      $display("data_mem[12] = %0d    || data_mem[13] = %0d   || data_mem[14]  = %0d   || data_mem[15] = %0d", uut.data_mem[12], uut.data_mem[13], uut.data_mem[14], uut.data_mem[15]);
      $display("data_mem[16] = %0d     || data_mem[17] = %0d    || data_mem[18]  = %0d   || data_mem[19] = %0d", uut.data_mem[16], uut.data_mem[17], uut.data_mem[18], uut.data_mem[19]);
      $display("data_mem[20] = %0d    || data_mem[21] = %0d   || data_mem[22]  = %0d   || data_mem[23] = %0d", uut.data_mem[20], uut.data_mem[21], uut.data_mem[22], uut.data_mem[23]);
      $display("--------------------------------------------------------------------------------");
      if(uut.stall)
        $display("STALL");
      
      else if (uut.ID_instr[6:0] == 7'b1100011) begin
        $display("=====================================================");
        $display("Comparando ID_r1: %d  ||  ID_r2: %d", uut.alu_in1, uut.alu_in2);
        $display("PC será atualizado para: %d", uut.branch_target);
        $display("Resultado da comparacao: %s", uut.branch_taken ? "TOMADO" : "NAO TOMADO");
        $display("====================================================");
      end
    end
  end
end

  // 4) Espera o mergesort rodar e imprime o resultado
  initial begin
    wait (reset == 0);
    #100000;  // tempo suficiente para ordenar

    $display("\n--- Vetor ordenado em data_mem ---");
    for (i = 0; i < 32; i = i + 1)
      $display("data_mem[%0d] = %0d", i, uut.data_mem[i]);

    $finish;
  end


endmodule
