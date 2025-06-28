# Verilog-micro-processador-RISC-V-Pipeline
Este projeto implementa um processador RISC-V em Verilog com arquitetura pipeline de 5 estágios, capaz de executar um algoritmo de ordenação Mergesort armazenado na memória de dados.  

## 🔧 Pré-requisitos
Verilog Simulator: ModelSim, Icarus Verilog ou outro de sua preferência  

## 🚀 Como Usar
### 1° Clone o repositório: 
git clone https://github.com/KanjiSaiko/Verilog-micro-processador-RISC-V-Pipeline 

### 2° Compile o design e o testbench

### 3° Execute a simulação:
ModelSim:  
  
  vlog rtl/*.v tb/tb_pipeline.v  
  vsim -c tb_pipeline -do "run -all; quit"  

### 4° Verifique a saída no console ou abra o waveform gerado para analisar sinais.

## 🧪 Testbench e Dados de Entrada
O arquivo tb_pipeline.v carrega valores iniciais na memória de dados usando o módulo test_data.v  
Exemplo:  
  uut.data_mem[0] = 32'd49;  
  uut.data_mem[1] = 32'd17;  
  uut.data_mem[2] = 32'd93;  
  uut.data_mem[3] = 32'd58;  
  //... até N elementos  
  O código do Mergesort está carregado em instr_mem a partir do endereço 0.

## 📝 Detalhes da Implementação
### 🔄 Pipeline de 5 estágios  
  IF (Instruction Fetch): busca instruções e incrementa o PC  
  ID (Instruction Decode): decodifica instruções e lê registradores  
  EX (Execute): ALU e cálculo de branches/endereço  
  MEM (Memory Access): acesso à memória de dados (LW/SW)  
  WB (Write Back): grava resultado no banco de registradores  
  
### 📜 Instruções Suportadas
  U-Type: LUI, AUIPC  
  J-Type: JAL  
  I-Type: JALR, ADDI, SRLI, SLLI, LW  
  S-Type: SW  
  B-Type: BEQ, BNE, BLT, BGE  
  R-Type: ADD, SUB, MUL  

### 🔀 Mergesort
O algoritmo de Mergesort foi implementado de forma recursiva, adaptado para chamadas de função (JAL/JALR). O vetor é dividido pela metade, e as duas metades são fundidas ordenadamente.
