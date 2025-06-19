module MEM_Stage (
  input  wire         clk,
  input  wire         reset,
  // vindo do EX
  input  wire [31:0]  EX_instr,
  input  wire [4:0]   EX_rd,
  input  wire [6:0]   EX_opcode,
  input  wire         EX_regwrite,
  input  wire [31:0]  EX_alu_result,
  input  wire [31:0]  EX_r2,
  input reg  [4:0]   EX_indiceR1,
  input reg  [4:0]   EX_indiceR2,
  // índice e tag para a cache de dados
  input  wire [1:0]   data_cache_index,
  input  wire [27:0]  data_cache_tag_addr,

  // saídas para WB
  output reg  [31:0]  MEM_instr,
  output reg  [4:0]   MEM_indiceR1,
  output reg  [4:0]   MEM_indiceR2,
  output reg  [4:0]   MEM_rd,
  output reg  [6:0]   MEM_opcode,
  output reg          MEM_regwrite,
  output reg  [31:0]  MEM_data
);

  // memória de dados: 16 bits por posição (endereço >> 1)
  reg [31:0] data_mem       [0:65535];
  // cache de dados 4 linhas
  reg [31:0] data_cache_data[0:3];
  reg [27:0] data_cache_tag [0:3];
  reg        data_cache_valid[0:3];

  integer i;
  initial begin
    // opcional: inicializa cache como inválida
    for (i = 0; i < 4; i = i + 1) begin
      data_cache_valid[i] = 1'b0;
      data_cache_tag  [i] = 28'b0;
      data_cache_data [i] = 16'b0;
    end
    // opcional: carregar memória de dados
    // $readmemh("data_mem.hex", data_mem);
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      MEM_instr    <= 32'b0;
      MEM_rd       <= 5'b0;
      MEM_opcode   <= 7'b0;
      MEM_regwrite <= 1'b0;
      MEM_data     <= 32'b0;
      MEM_indiceR1 <= 4'b0;
      MEM_indiceR2 <= 4'b0;
    end else begin
      // passar sinais do EX adiante
      MEM_instr    <= EX_instr;
      MEM_rd       <= EX_rd;
      MEM_opcode   <= EX_opcode;
      MEM_regwrite <= EX_regwrite;
      MEM_indiceR1 <= EX_indiceR1;
      MEM_indiceR2 <= EX_indiceR2;
      
      case (EX_opcode)
        // Load Word
        7'b0000011: begin
          if (data_cache_valid[data_cache_index] &&
              data_cache_tag[data_cache_index] == data_cache_tag_addr) begin
            // cache hit
            MEM_data <= {16'b0, data_cache_data[data_cache_index]};
          end else begin
            // cache miss: ler memória principal
            data_cache_data[data_cache_index]  <= data_mem[EX_alu_result >> 1];
            data_cache_tag[data_cache_index]   <= data_cache_tag_addr;
            data_cache_valid[data_cache_index] <= 1'b1;
            MEM_data <= data_mem[EX_alu_result >> 2];
          end
        end

        // Store Word
        7'b0100011: begin
          // grava na memória principal
          data_mem[EX_alu_result >> 1] <= EX_r2[15:0];
          // write-through + no write‐allocate: invalida linha
          data_cache_valid[data_cache_index] <= 1'b0;
          // não há dado pra passar a WB
          MEM_data <= 32'b0;
        end

        default: begin
          // para R-type, AUIPC, JAL, etc.: passa resultado da ALU
          MEM_data <= EX_alu_result;
        end
      endcase
    end
  end

endmodule
