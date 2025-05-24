module Cache #(
  parameter ADDR_WIDTH = 16,
  parameter DATA_WIDTH = 32,
  parameter NUM_LINES  = 64
) (
    input clock,
    input reset,
    
    // Interface com o processador
    input write_enable_req,
    input endereço_req,
    input  [DATA_WIDTH-1:0] wdata_req,
    output                  hit,
    output [DATA_WIDTH-1:0] rdata_resp,

    // Interface com a memória principal
    output                  mem_read,
    output [ADDR_WIDTH-1:0] mem_addr,
    input  [DATA_WIDTH-1:0] mem_rdata
);
    


always @(posedge clock) begin
        
end


endmodule