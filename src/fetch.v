`include "constants.v"

module InstructionFetch
    (input wire clk,
     input wire rst,

     /* PC Read/Write interface */
     /* Note: PC always points to the next instruction of which in IR */
     /* Note: PC Flush signal will prevent memory access of the current PC and emit a `nop` into IR */
     output reg [31 : 0] pc_Out,
     input wire [31 : 0] pcWrite_In,
     input wire pcFlush_In,

     /* Instruction output */
     output reg [31 : 0] instr_Out,

     /* Synchronization with backend */
     /* Note: `Instruction Consumed` enables the frontend to update IR */
     /* Note: `Can Writeback` signals the backend to writeback when instruction fetch from memory is done */
     input wire instrIsConsumed_In,
     output wire canWriteBack_Out,

     /* Memory access interface */
     output wire [31 : 0] memAddr_Out,
     output wire [31 : 0] memData_Out,
     output wire [1 : 0] memDataWidth_Out,
     output wire memIsRead_Out,
     output wire memAccess_Out,
     input wire memAccessOK_In,
     input wire [31 : 0] memData_In,
     input wire [`EXCEPTION_LEN - 1 : 0] memException_In,

     /* Module exception out */
     output wire [`EXCEPTION_LEN - 1 : 0] exception_Out);

    reg [31 : 0] next_ir; // Instruction cache, avoid deadlock with memory access in backend
    reg mem_access_enable;
    reg new_instr_available; // Signal when IR can update

    /* Access memory */
    assign memAddr_Out = pc_Out;
    assign memData_Out = 0;                                                     // Readonly
    assign memDataWidth_Out = `MEM_WIDTH_WORD;                                  // RV32I only have 4-bytes instructions
    assign memIsRead_Out = 1'b1;                                                // Readonly
    assign memAccess_Out = mem_access_enable && !memAccessOK_In && !pcFlush_In; // Invalid PC may cause read violation
    assign exception_Out = memException_In;                                     // Just propagate exception

    /* Core logic */
    wire can_ir_update = instrIsConsumed_In && (pcFlush_In || new_instr_available);
    assign canWriteBack_Out = can_ir_update;                         // Sync writeback with IR update
    wire is_mem_access_finish = mem_access_enable && memAccessOK_In; // Take the output only if the input is valid too

    always @(posedge clk)
    begin
        if (rst)
            pc_Out <= `BOOT_ADDR;
        else if (can_ir_update) // Sync with IR
            pc_Out <= pcWrite_In;
    end

    always @(posedge clk)
    begin
        if (rst)
            mem_access_enable <= 1; // `BOOT_ADDR` is valid so access memory immediately
        else if (can_ir_update)     // PC updated, fetch new instruction (restricted by `PC Flush`)
            mem_access_enable <= 1;
        else if (is_mem_access_finish) // Stop memory access so that we can access a new address next time
            mem_access_enable <= 0;
    end

    always @(posedge clk)
    begin
        if (rst)
            new_instr_available <= 0;
        else if (is_mem_access_finish)
            new_instr_available <= 1;
        else if (can_ir_update)
            new_instr_available <= 0; // Instruction will be moved to IR
    end

    wire [31 : 0] NOP = {25'b0, 7'b0010011}; // add x0, x0, x0

    always @(posedge clk)
    begin
        if (rst)
            next_ir <= NOP;
        else if (is_mem_access_finish)
            next_ir <= memData_In;
    end

    always @(posedge clk)
    begin
        if (rst)
            instr_Out <= NOP;
        else if (can_ir_update)
            instr_Out <= pcFlush_In ? NOP : next_ir;
    end
endmodule