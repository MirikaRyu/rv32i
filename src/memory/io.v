/* Mock a simple GPIO module */

// clang-format off
import "DPI-C" function int get_io_state();
import "DPI-C" function void set_io_state(input int mask, input int value);

// Use exactly 1 cycle to write to device
// Use devValue_In & devMask_In to decide which device to write
// devState_Out is always the newest state of devices
module IO
    (input wire clk,
     input wire rst,

     input wire [31 : 0] devMask_In,
     input wire [31 : 0] devValue_In,

     output reg [31 : 0] devState_Out);

    always @(posedge clk)
    begin
        if (rst)
            set_io_state(32'b1, 32'b0);
        else
            set_io_state(devMask_In, devValue_In);
    end

    always @(*)
    begin
        devState_Out = get_io_state();
    end
endmodule