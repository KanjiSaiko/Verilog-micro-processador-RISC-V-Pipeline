`timescale 1ns/1ps

module WB_Stage (
  input  wire         clk,
  input  wire         reset,
  input  wire         MEM_regwrite,  // do estágio MEM
  input  wire [4:0]   MEM_rd,        // destino da escrita
  input  wire [31:0]  MEM_data,      // dado a ser escrito
  input  wire [31:0]  MEM_instr,
  input reg  [4:0]   MEM_indiceR1,
  input reg  [4:0]   MEM_indiceR2,
  // sinais para o RegFile
  output reg          wb_regwrite,   // vai para RegFile.regwrite
  output reg  [4:0]   wb_rd,         // vai para RegFile.rd
  output reg  [31:0]  wb_write_data, // vai para RegFile.write_data
  output reg  [4:0]   WB_indiceR1,
  output reg  [4:0]   WB_indiceR2,
  // para acompanhar sempre o valor de x1
  output reg  [31:0]  register_address,
  output reg  [31:0]  WB_instr
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      wb_regwrite     <= 1'b0;
      wb_rd           <= 5'b0;
      wb_write_data   <= 32'b0;
      register_address<= 32'b0;
      WB_instr        <= 32'b0;
      WB_indiceR1     <= 4'b0;
      WB_indiceR2     <= 4'b0;
      
    end else begin
      // propaga sinais para o RegFile
      WB_instr      <= MEM_instr;
      wb_regwrite   <= MEM_regwrite;  
      wb_rd         <= MEM_rd;
      wb_write_data <= MEM_data;
      WB_indiceR1   <= MEM_indiceR1;
      WB_indiceR2   <= MEM_indiceR2;


      if (MEM_regwrite && (MEM_rd != 5'b0)) begin
        register_address <= MEM_data;
      end
    end
  end

endmodule
