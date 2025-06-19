module ForwardingUnit(
    input  wire        EX_regwrite,
    input  wire        MEM_regwrite,
    input  wire [4:0]  EX_rd,
    input  wire [4:0]  MEM_rd,
    input  wire [4:0]  Indice_rs1,
    input  wire [4:0]  Indice_rs2,

    output wire        fwdEX_r1,
    output wire        fwdWB_r1,
    output wire        fwdEX_r2,
    output wire        fwdWB_r2
);

  assign fwdEX_r1 = EX_regwrite  && (EX_rd != 0) && (EX_rd == Indice_rs1);
  assign fwdWB_r1 = MEM_regwrite && (MEM_rd != 0) && !fwdEX_r1 && (MEM_rd == Indice_rs1);
  assign fwdEX_r2 = EX_regwrite  && (EX_rd != 0) && (EX_rd == Indice_rs2);
  assign fwdWB_r2 = MEM_regwrite && (MEM_rd != 0) && !fwdEX_r2 && (MEM_rd == Indice_rs2);

endmodule
