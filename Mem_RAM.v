module Mem_RAM (clock, write_enable, endereço, data_in, data_out);
    input clock;
    input write_enable;
    input [15:0] endereço;
    input [31:0] data_in;
    output [31:0] data_out;
    

reg[31:0] Memoria_RAM [0:65535];

always @(posedge clk) begin
        if (write_enable == 1)
            Memoria_RAM[endereço] <= data_in;   // escrita na borda de subida
        data_out <= Memoria_RAM[endereço];     // leitura também na borda de subida
end


endmodule