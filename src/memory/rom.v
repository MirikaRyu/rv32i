/* Mock a Read-Only memory for instructions */

// clang-format off
import "DPI-C" function int rom_read(input shortint addr, input byte width);

`include "src/constants.v"

// Size: 64KiB
module ROM
    (input wire clk,
     input wire rst,

     input wire [31 : 0] addr_In,
     input wire [1 : 0] dataWidth_In,
     input wire inputValid_In,

     output reg [31 : 0] data_Out,
     output reg operationOK_Out,

     output wire [`EXCEPTION_LEN - 1 : 0] exception_Out);

    assign exception_Out = (inputValid_In && (|addr_In[31 : 16] || dataWidth_In == `MEM_WIDTH_NONE))
                               ? `EXCEP_INVALID_MEM_READ
                               : `EXCEP_OK;

    always @(posedge clk)
    begin
        if (rst)
            operationOK_Out <= 0;
        else
            operationOK_Out <= inputValid_In;
    end

    always @(posedge clk)
    begin
        if (rst)
            data_Out <= 0;
        else if (inputValid_In)
            data_Out <= rom_read(addr_In[15 : 0], {6'b0, dataWidth_In});
    end
endmodule