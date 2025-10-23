/* Mock a Random-Access memory for data */

// clang-format off
// Only low 29 bits of addr are valid, width follows the def in `constants.v`
// Only `width` bits of input data is valid
// The valid bits of return value is decided by `width`
import "DPI-C" function int ram_read(input int addr, input byte width);
import "DPI-C" function void ram_write(input int addr, input byte width, input int data);

// Size: 512MiB
module DataRAM
    (input wire clk,
     input wire rst,

     input wire [28 : 0] addr_In,
     input wire [31 : 0] data_In,
     input wire [1 : 0] dataWidth_In,
     input wire isRead_In,
     input wire inputValid_In,

     output reg [31 : 0] data_Out,
     output reg operationOK_Out);

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
        else if (inputValid_In && isRead_In)
            data_Out <= ram_read({3'b0, addr_In}, {6'b0, dataWidth_In});
        else if (inputValid_In && !isRead_In)
            ram_write({3'b0, addr_In}, {6'b0, dataWidth_In}, data_In);
    end
endmodule