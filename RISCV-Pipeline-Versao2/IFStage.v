module IF_Stage (
  input  wire        clk,
  input  wire        reset,
  input  wire [31:0] PC,
  output reg  [31:0] IF_PC,
  output reg  [31:0] IF_instr
);

  // ---------------------------------------------------
  // 1) Memória de instruções (interna)
  // ---------------------------------------------------
  reg [31:0] instr_mem [0:21];

  // ---------------------------------------------------
  // 2) Cache de instruções (4 linhas, direta)
  // ---------------------------------------------------
  reg [31:0] cache_data  [0:3];   // dados de 32 bits
  reg [27:0] cache_tag   [0:3];   // tag de 28 bits
  reg        cache_valid [0:3];   // bits de validade

  integer i;
  // cálculo de índice e tag a partir do PC
  wire [1:0]  idx    = PC[3:2];
  wire [27:0] tag_in = PC[31:4];

  // ---------------------------------------------------
  // 3) Inicialização da memória e da cache
  // ---------------------------------------------------
  initial begin
    // exemplo de programa
    instr_mem[0] = 32'b00000000101000000000000010010011;
    instr_mem[1] = 32'b00000001010000000000000100010011;
    instr_mem[2] = 32'b00000000001000001000000110110011;
    instr_mem[3] = 32'b01000000010100011000001000110011;
    instr_mem[4] = 32'b00000010001100100000001010110011;
    instr_mem[5] = 32'b00000000000000000100001110000011;
    instr_mem[6] = 32'b00000000010000000110010000000011;
    // zera/invalida a cache
    for (i = 0; i < 4; i = i + 1) begin
      cache_valid[i] = 1'b0;
      cache_tag  [i] = 28'b0;
      cache_data [i] = 32'b0;
    end
  end

  // ---------------------------------------------------
  // 4) Etapa IF + substituição de cache
  // ---------------------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      IF_PC    <= 32'b0;
      IF_instr <= 32'b0;
      // invalida cache de novo no reset
      for (i = 0; i < 4; i = i + 1) begin
        cache_valid[i] <= 1'b0;
        cache_tag  [i] <= 28'b0;
        cache_data [i] <= 32'b0;
      end
    end else begin
      // guarda o PC atual para a próxima etapa
      IF_PC <= PC;

      // *** ATENÇÃO: aqui você SÓ pode usar cache_valid[idx],
      // cache_tag[idx] e cache_data[idx], NUNCA cache_tag sem [idx] ***
      if (cache_valid[idx] && cache_tag[idx] == tag_in) begin
        // HIT na cache
        IF_instr <= cache_data[idx];
      end else begin
        // MISS: lê da memória de instruções
        IF_instr        <= instr_mem[PC >> 2];
        cache_data[idx] <= instr_mem[PC >> 2];
        cache_tag[idx]  <= tag_in;
        cache_valid[idx]<= 1'b1;
      end
    end
  end

endmodule
