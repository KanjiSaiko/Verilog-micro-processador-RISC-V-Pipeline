module RegFile(
  input  wire         clk,
  input  wire         reset,
  input  wire         regwrite,    // de WB stage
  input  wire [4:0]   rd,          // endereço de destino
  input  wire [31:0]  write_data,  // dado a ser escrito
  input  wire [4:0]   rs1,         // endereço de leitura 1
  input  wire [4:0]   rs2,         // endereço de leitura 2
  output wire [31:0]  rs1_data,    // valor de rs1
  output wire [31:0]  rs2_data     // valor de rs2
);

  reg [31:0] banco_regs[0:31];
  integer i;

  // zero nos registros em reset
  initial for (i=0; i<32; i=i+1) banco_regs[i] = 32'b0;

  // escrita no fim do ciclo de clock
  always @(posedge clk) begin
    if (regwrite && rd != 0)
      banco_regs[rd] <= write_data;
  end

  // leitura combinacional
  assign rs1_data = banco_regs[rs1];
  assign rs2_data = banco_regs[rs2];

endmodule
