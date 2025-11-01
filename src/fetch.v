/* Fetch instruction from instruction ROM */

`include "constants.v"

module InstructionFetch
    (input wire clk,
     input wire rst,

     output wire [31 : 0] pc_Out,
     output wire [31 : 0] instr_Out,
     input wire instrIsConsumed_In,

     input wire [31 : 0] pcWrite_In,
     input wire pcFlush_In,

     output wire canWriteBack_Out,

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

    reg [31 : 0] next_ir;
    reg [31 : 0] ir;
    reg [31 : 0] pc;
    reg mem_read_enable;
    reg new_instr_available;

    assign instr_Out = ir;
    assign pc_Out = pc;

    // Memory access
    assign memAddr_Out = pc;
    assign memData_Out = 0;
    assign memDataWidth_Out = `MEM_WIDTH_WORD;
    assign memIsRead_Out = 1'b1;
    assign memAccess_Out = mem_read_enable && !pcFlush_In;

    assign exception_Out = memException_In;

    // Logic
    wire [31 : 0] instr_NOP = {25'b0, 7'b0010011};
    wire should_ir_update = instrIsConsumed_In && (pcFlush_In || new_instr_available);
    wire mem_access_complete = mem_read_enable && memAccessOK_In;
    assign canWriteBack_Out = should_ir_update;

    always @(posedge clk)
    begin
        if (rst)
            pc <= `BOOT_ADDR;
        else if (should_ir_update)
            pc <= pcWrite_In;
    end

    always @(posedge clk)
    begin
        if (rst)
            mem_read_enable <= 1;
        else if (should_ir_update) // PC updated, fetch new instruction
            mem_read_enable <= 1;
        else if (mem_access_complete)
            mem_read_enable <= 0;
    end

    always @(posedge clk)
    begin
        if (rst)
            next_ir <= instr_NOP;
        else if (mem_access_complete) // Store to temp reg, prevent dead lock
            next_ir <= memData_In;
    end

    always @(posedge clk)
    begin
        if (rst)
            new_instr_available <= 0;
        else if (mem_access_complete)
            new_instr_available <= 1;
        else if (should_ir_update)
            new_instr_available <= 0;
    end

    always @(posedge clk)
    begin
        if (rst)
            ir <= instr_NOP;
        else if (should_ir_update)
            ir <= pcFlush_In ? instr_NOP : next_ir;
    end
endmodule