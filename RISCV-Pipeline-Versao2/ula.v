module ALU_Unit(
    input  wire [31:0] ID_r1,
    input  wire [31:0] ID_r2,
    input  wire [31:0] ID_imm,
    input  wire [31:0] ID_PC,
    input  wire [31:0] imm_shift,
    input  wire [6:0]  ID_opcode,
    input  wire [2:0]  ID_funct3,
    input  wire [6:0]  ID_funct7,

    // resultados vindos de EX e MEM para forwarding
    input  wire [31:0] EX_alu_result,
    input  wire [31:0] MEM_data,
    input  wire        fwdEX_r1,
    input  wire        fwdWB_r1,
    input  wire        fwdEX_r2,
    input  wire        fwdWB_r2,

    output reg  [31:0] alu_result,
    output reg         branch_taken,
    output reg  [31:0] branch_target
);

  // Seleção de operandos com forwarding
  wire [31:0] alu_in1 = fwdEX_r1 ? EX_alu_result :
                        fwdWB_r1 ? MEM_data :
                                   ID_r1;

  wire [31:0] alu_in2 = (ID_opcode==7'b0010011 ||
                        ID_opcode==7'b0000011 ||
                        ID_opcode==7'b0100011) ? ID_imm :
                        fwdEX_r2 ? EX_alu_result :
                        fwdWB_r2 ? MEM_data :
                                   ID_r2;

  // condições de desvio
  wire bge_cond = (ID_funct3 == 3'b101) && (alu_in1 >= alu_in2);
  wire blt_cond = (ID_funct3 == 3'b100) && (alu_in1 <  alu_in2);

  always @(*) begin
    // defaults
    alu_result    = 32'b0;
    branch_taken  = 1'b0;
    branch_target = 32'b0;

    case (ID_opcode)
      // R-Type
      7'b0110011: begin
        case (ID_funct7)
          7'b0000000: alu_result = alu_in1 + alu_in2;  // ADD
          7'b0000001: alu_result = alu_in1 * alu_in2;  // MUL
          7'b0100000: alu_result = alu_in1 - alu_in2;  // SUB
          default:    alu_result = 32'b0;
        endcase
      end

      // I-Type (ADDI), LW, SW
      7'b0010011, 
      7'b0000011,
      7'b0100011: begin
        alu_result = alu_in1 + ID_imm;
      end

      // AUIPC
      7'b0010111: begin
        alu_result = imm_shift + ID_PC;
      end

      // Branches
      7'b1100011: begin
        branch_taken  = bge_cond || blt_cond;
        branch_target = ID_PC + ID_imm;
      end

      default: begin
        // nada adicional
      end
    endcase
  end

endmodule
