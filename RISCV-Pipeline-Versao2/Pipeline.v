`timescale 1ns/1ps

module RISCV_Pipeline (
  input  wire        clock,
  input  wire        reset
);

  integer i;


  //=======================================
  // 1) Program Counter
  //=======================================
  wire [31:0] PC;
  reg [31:0] register_address;

  //=======================================
  // 3) Sinais de saída do IF_Stage (IF/ID)
  //=======================================
  wire [31:0] IF_PC;
  wire [31:0] IF_instr;

  //=======================================
  // 4) Fios de interconexão restantes
  //=======================================
  // ID
  wire [31:0] ID_PC,   ID_instr,   ID_r1,    ID_r2,    ID_imm, EX_imm;
  wire [31:0] imm_sext, imm_shift;
  wire        flag_jump, ID_regwrite;
  wire [4:0]  ID_indiceR1, ID_indiceR2, ID_rd;
  wire [6:0]  ID_opcode;
  wire [2:0]  ID_funct3;
  wire [6:0]  ID_funct7;
  // Forwarding
  wire        fwdEX_r1, fwdWB_r1, fwdEX_r2, fwdWB_r2;
  // ALU / Branch
  wire [31:0] alu_result, branch_target;
  wire        branch_taken;
  // EX
  wire [31:0] EX_instr, EX_alu_result, EX_r2;
  wire [4:0]  EX_rd;
  wire [6:0]  EX_opcode;
  wire        EX_regwrite;
  // MEM
  wire [31:0] MEM_instr, MEM_data;
  wire [4:0]  MEM_rd;
  wire [6:0]  MEM_opcode;
  wire        MEM_regwrite;

  // wires para ler o regfile
  wire [31:0] reg_r1, reg_r2;

  wire [31:0] pc_anterior, link;


  // instancia RegFile
  RegFile regfile_u (
    .clk        (clock),
    .reset      (reset),
    .regwrite   (MEM_regwrite),
    .rd         (MEM_rd),
    .write_data (MEM_data),
    .rs1        (ID_indiceR1),
    .rs2        (ID_indiceR2),
    .rs1_data   (reg_r1),
    .rs2_data   (reg_r2)
  );

  //=========================================
  // 6) PC_Update
  //=========================================
  PC_Update pc_u (
    .clk          (clock),
    .reset        (reset),
    .pc_anterior  (PC),  
    .branch_taken (branch_taken),
    .flag_jump    (flag_jump),
    .branch_target(branch_target),
    .ID_PC        (ID_PC),
    .ID_imm       (ID_imm),
    .PC           (PC),     // receba em PC_next
    .link         (link)
  );

  //=======================================
  // 7) IF_Stage
  //=======================================
  IF_Stage if_s (
    .clk               (clock),
    .reset             (reset),
    .PC                (PC),
    .IF_PC             (IF_PC),
    .IF_instr          (IF_instr)
  );

  //=======================================
  // 8) ID_Stage
  //=======================================
  ID_Stage id_s (
    .clk         (clock),
    .reset       (reset),
    .IF_PC       (IF_PC),
    .IF_instr    (IF_instr),
    .branch_taken(branch_taken),
    .rs1_data   (reg_r1),
    .rs2_data   (reg_r2),
    .ID_PC       (ID_PC),
    .ID_instr    (ID_instr),
    .ID_r1       (ID_r1),
    .ID_r2       (ID_r2),
    .ID_imm      (ID_imm),
    .imm_sext    (imm_sext),
    .imm_shift   (imm_shift),
    .flag_jump   (flag_jump),
    .ID_regwrite (ID_regwrite),
    .ID_indiceR1 (ID_indiceR1),
    .ID_indiceR2 (ID_indiceR2),
    .ID_rd       (ID_rd),
    .ID_opcode   (ID_opcode),
    .ID_funct3   (ID_funct3),
    .ID_funct7   (ID_funct7)
  );

  //=======================================
  // 9) ForwardingUnit
  //=======================================
  ForwardingUnit fwd_u (
    .EX_regwrite  (EX_regwrite),
    .MEM_regwrite (MEM_regwrite),
    .EX_rd        (EX_rd),
    .MEM_rd       (MEM_rd),
    .ID_rs1       (ID_indiceR1),
    .ID_rs2       (ID_indiceR2),
    .fwdEX_r1     (fwdEX_r1),
    .fwdWB_r1     (fwdWB_r1),
    .fwdEX_r2     (fwdEX_r2),
    .fwdWB_r2     (fwdWB_r2)
  );

  //=======================================
  // 10) ALU_Unit (inclui branch)
  //=======================================
  ALU_Unit alu_u (
    .ID_r1         (ID_r1),
    .ID_r2         (ID_r2),
    .ID_imm        (ID_imm),
    .ID_PC         (ID_PC),
    .imm_shift     (imm_shift),
    .ID_opcode     (ID_opcode),
    .ID_funct3     (ID_funct3),
    .ID_funct7     (ID_funct7),
    .EX_alu_result (EX_alu_result),
    .MEM_data      (MEM_data),
    .fwdEX_r1      (fwdEX_r1),
    .fwdWB_r1      (fwdWB_r1),
    .fwdEX_r2      (fwdEX_r2),
    .fwdWB_r2      (fwdWB_r2),
    .alu_result    (alu_result),
    .branch_taken  (branch_taken),
    .branch_target (branch_target)
  );

  //=======================================
  // 11) EX_Stage
  //=======================================
  EX_Stage ex_s (
    .clk           (clock),
    .reset         (reset),
    .ID_instr      (ID_instr),
    .ID_rd         (ID_rd),
    .ID_opcode     (ID_opcode),
    .ID_regwrite   (ID_regwrite),
    .ID_imm        (ID_imm),
    .ID_r2         (ID_r2),
    .alu_result    (alu_result),
    .EX_instr      (EX_instr),
    .EX_rd         (EX_rd),
    .EX_opcode     (EX_opcode),
    .EX_regwrite   (EX_regwrite),
    .EX_imm        (EX_imm),
    .EX_r2         (EX_r2),
    .EX_alu_result (EX_alu_result)
  );


  wire [1:0]  data_cache_index    = EX_alu_result[3:2];
  wire [27:0] data_cache_tag_addr = EX_alu_result[31:4];
  //=======================================
  // 12) MEM_Stage
  //=======================================
  MEM_Stage mem_s (
    .clk                 (clock),
    .reset               (reset),
    .EX_instr            (EX_instr),
    .EX_rd               (EX_rd),
    .EX_opcode           (EX_opcode),
    .EX_regwrite         (EX_regwrite),
    .EX_alu_result       (EX_alu_result),
    .EX_r2               (EX_r2),
    .data_cache_index    (data_cache_index), 
    .data_cache_tag_addr (data_cache_tag_addr),
    .MEM_instr           (MEM_instr),
    .MEM_rd              (MEM_rd),
    .MEM_opcode          (MEM_opcode),
    .MEM_regwrite        (MEM_regwrite),
    .MEM_data            (MEM_data)
  );

  wire        regfile_we;
  wire [4:0]  regfile_rd;
  wire [31:0] regfile_wdata;
  wire [31:0] wb_link;
  //=======================================
  // 13) WB_Stage
  //=======================================
  WB_Stage wb_s (
    .clk             (clock),
    .reset           (reset),
    .MEM_regwrite    (MEM_regwrite),
    .MEM_rd          (MEM_rd),
    .MEM_data        (MEM_data),
    .wb_regwrite     (regfile_we),
    .wb_rd           (regfile_rd),
    .wb_write_data   (regfile_wdata),
    .register_address(wb_link)
  );

endmodule
