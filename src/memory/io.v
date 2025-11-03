`include "src/constants.v"

// clang-format off
import "DPI-C" function int io_read(input int addr, input byte width);
import "DPI-C" function void io_write(input int addr, input byte width, input int data);

module IO // Size: 4B
    (input wire clk,
     input wire rst,

     input wire [31 : 0] addr_In,
     input wire [31 : 0] data_In,
     input wire [1 : 0] dataWidth_In,
     input wire isRead_In,
     input wire inputValid_In,

     output reg [31 : 0] data_Out,
     output reg operationOK_Out,

     output reg [`EXCEPTION_LEN - 1 : 0] exception_Out);

    always @(*)
    begin
        exception_Out = `EXCEP_OK;

        if (inputValid_In && (|addr_In[31 : 2] || dataWidth_In == `MEM_WIDTH_NONE))
            if (isRead_In)
                exception_Out = `EXCEP_INVALID_MEM_READ;
            else
                exception_Out = `EXCEP_INVALID_MEM_WRITE;
    end

    always @(posedge clk)
    begin
        if (rst)
            operationOK_Out <= 0;
        else
            operationOK_Out <= inputValid_In; // Use exactly 1 cycle to do IO
    end

    always @(posedge clk)
    begin
        if (rst)
            io_write(32'b0, {6'b0, `MEM_WIDTH_WORD}, 32'b0);
        else if (inputValid_In && !isRead_In && exception_Out == `EXCEP_OK)
            io_write(addr_In, {6'b0, dataWidth_In}, data_In);
    end

    always @(posedge clk)
    begin
        if (rst)
            data_Out <= 0;
        else
            data_Out <= inputValid_In ? io_read(addr_In, {6'b0, dataWidth_In}) : 32'b0;
    end
endmodule