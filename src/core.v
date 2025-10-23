/* Top level module of the CPU */

`include "constants.v"

module Core
    (input wire clk,
     input wire rst);

    reg execution_lock;
    reg [EXCEPTION_LEN - 1 : 0] exception;
    wire cpu_rst = rst || (exception != EXCEP_ENV_BREAK && exception != EXCEP_OK);

    wire [31 : 0] instruction;
    wire [31 : 0] pc;
    wire [31 : 0] pc_write;
    wire pc_flush;
    wire if_exec_lock_set;
    wire [EXCEPTION_LEN - 1 : 0] if_exception;
    InstructionFetch instr_fetch(.clk(clk),
                                 .rst(cpu_rst),

                                 .instr_Out(instruction),
                                 .pc_Out(pc),

                                 .pcWrite_In(pc_write),
                                 .pcFlush_In(pc_flush),

                                 .execLockRead_In(execution_lock),
                                 .execLockSet_Out(if_exec_lock_set),

                                 .exception_Out(if_exception));

    wire [4 : 0] rs1_address;
    wire [4 : 0] rs2_address;
    wire [31 : 0] rs1_data;
    wire [31 : 0] rs2_data;
    wire rs1_enable;
    wire rs2_enable;
    wire [5 : 0] opcode;
    wire [4 : 0] rd_address;
    wire [31 : 0] resource1;
    wire [31 : 0] resource2;
    wire [31 : 0] offset;
    wire [EXCEPTION_LEN - 1 : 0] id_exception;
    InstructionDecode instr_decode(.instr_In(instruction),

                                   .rs1Addr_Out(rs1_address),
                                   .rs1_In(rs1_data),
                                   .rs1Enable_Out(rs1_enable),

                                   .rs2Addr_Out(rs2_address),
                                   .rs2_In(rs2_data),
                                   .rs2Enable_Out(rs2_enable),

                                   .opCode_Out(opcode),
                                   .rdAddr_Out(rd_address),
                                   .resource1_Out(resource1),
                                   .resource2_Out(resource2),
                                   .offset_Out(offset),

                                   .exception_Out(id_exception));

    wire [4 : 0] exec_rd_address;
    wire [31 : 0] rd_data;
    wire rd_enable;
    wire ex_exec_lock_set;
    wire [EXCEPTION_LEN - 1 : 0] ex_exception;
    Executor executor(.clk(clk),
                      .rst(cpu_rst),

                      .rdAddr_Out(exec_rd_address),
                      .rdWrite_Out(rd_data),
                      .rdEnable_Out(rd_enable),

                      .pcWrite_Out(pc_write),
                      .pcFlush_Out(pc_flush),

                      .opCode_In(opcode),
                      .rdAddr_In(rd_address),
                      .resource1_In(resource1),
                      .resource2_In(resource2),
                      .offset_In(offset),
                      .pc_In(pc),

                      .execLockRead_In(execution_lock),
                      .execLockSet_Out(ex_exec_lock_set),

                      .exception_Out(ex_exception));

    RegisterFile reg_file(.clk(clk),
                          .rst(cpu_rst),

                          .rs1Addr_In(rs1_address),
                          .rs1_Out(rs1_data),
                          .rs1Enable_In(rs1_enable),

                          .rs2Addr_In(rs2_address),
                          .rs2_Out(rs2_data),
                          .rs2Enable_In(rs2_enable),

                          .rdAddr_In(exec_rd_address),
                          .rd_In(rd_data),
                          .rdEnable_In(rd_enable));

    always @(*)
    begin
        if (if_exec_lock_set || ex_exec_lock_set)
            execution_lock = 1;
        else
            execution_lock = 0;

        if (exception == EXCEP_ENV_BREAK)
            execution_lock = 1;
    end

    always @(*)
    begin
        if (if_exception != EXCEP_OK)
            exception = if_exception;
        else if (id_exception != EXCEP_OK)
            exception = if_exception;
        else
            exception = ex_exception;
    end
endmodule