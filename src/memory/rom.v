/* Mock a Read-Only memory for instructions */

// clang-format off
import "DPI-C" function int rom_access(input shortint addr);

// Size: 64KiB
module InstrROM
    (input wire clk,
     input wire rst,

     input wire [15 : 0] addr_In,
     input wire addrValid_In,
     output reg [31 : 0] instr_Out,
     output reg instrValid_Out);

    always @(posedge clk)
    begin
        if (rst)
            instrValid_Out <= 0;
        else
            instrValid_Out <= addrValid_In;
    end

    always @(posedge clk)
    begin
        if (rst)
            instr_Out <= 0;
        else if (addrValid_In)
            instr_Out <= rom_access(addr_In);
    end
endmodule