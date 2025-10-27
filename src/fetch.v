/* Fetch instruction from instruction ROM */

`include "constants.v"

module InstructionFetch
    (input wire clk,
     input wire rst,

     output wire [31 : 0] instr_Out,
     output wire [31 : 0] pc_Out,

     input wire [31 : 0] pcWrite_In,
     input wire pcFlush_In,

     input wire execLockRead_In,
     output wire execLockSet_Out,

     // Memory access
     output reg [31 : 0] memAddr_Out,
     output reg [31 : 0] memData_Out,
     output reg [1 : 0] memDataWidth_Out,
     output reg memIsRead_Out,
     output wire memAccess_Out,

     input wire memAccessOK_In,
     input wire [31 : 0] memData_In,
     input wire [`EXCEPTION_LEN - 1 : 0] memException_In,

     output wire [`EXCEPTION_LEN - 1 : 0] exception_Out);

    reg [31 : 0] ir;
    reg [31 : 0] pc;
    reg rom_read_enable;

    wire [31 : 0] rom_instr;
    wire rom_output_valid;

    assign instr_Out = ir;
    assign pc_Out = pc;
    assign execLockSet_Out = !(rom_read_enable && rom_output_valid) && !pcFlush_In;

    // Memory access
    assign memAddr_Out = pc;
    assign memData_Out = 0;
    assign memDataWidth_Out = `MEM_WIDTH_WORD;
    assign memIsRead_Out = 1'b1;
    assign memAccess_Out = rom_read_enable;

    assign rom_output_valid = memAccessOK_In;
    assign rom_instr = memData_In;
    assign exception_Out = memException_In;

    wire should_flush = !execLockRead_In && pcFlush_In;
    wire should_step = !execLockRead_In && rom_output_valid && rom_read_enable;

    always @(posedge clk)
    begin
        if (rst)
            pc <= `BOOT_ADDR;
        else if (should_flush)
            pc <= pcWrite_In;
        else if (should_step) // Sync PC update with IR
            pc <= pcWrite_In;
    end

    always @(posedge clk)
    begin
        if (rst)
            ir <= {25'b0, 7'b0010011}; // NOP
        else if (should_flush)
            ir <= {25'b0, 7'b0010011}; // NOP
        else if (should_step)
            ir <= rom_instr;
    end

    always @(posedge clk)
    begin
        if (rst)
            rom_read_enable <= 1;
        else if (pcFlush_In)
            rom_read_enable <= 0;
        else if (rom_output_valid && rom_read_enable)
            rom_read_enable <= 0;
        else
            rom_read_enable <= 1;
    end
endmodule