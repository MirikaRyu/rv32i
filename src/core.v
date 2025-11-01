/* Top level module of the CPU */

`include "constants.v"

module Core
    (input wire clk,
     input wire rst);

    reg [`EXCEPTION_LEN - 1 : 0] exception;
    wire cpu_rst = rst || (exception != `EXCEP_ENV_BREAK && exception != `EXCEP_OK);
    wire cpu_clk = (exception == `EXCEP_ENV_BREAK) ? 1'b1 : clk;

    wire [31 : 0] instruction;
    wire [31 : 0] pc;
    wire instr_consumed;
    wire [31 : 0] pc_write;
    wire pc_flush;
    wire can_write_back;
    wire [31 : 0] if_mem_addr_out;
    wire [31 : 0] if_mem_data_out;
    wire [1 : 0] if_mem_data_width_out;
    wire if_mem_is_read_out;
    wire if_mem_access_out;
    wire if_mem_ok_in;
    wire [31 : 0] if_mem_data_in;
    wire [`EXCEPTION_LEN - 1 : 0] if_mem_exception_in;
    wire [`EXCEPTION_LEN - 1 : 0] if_exception;
    InstructionFetch instr_fetch(.clk(cpu_clk),
                                 .rst(cpu_rst),

                                 .instr_Out(instruction),
                                 .pc_Out(pc),
                                 .instrIsConsumed_In(instr_consumed),

                                 .pcWrite_In(pc_write),
                                 .pcFlush_In(pc_flush),
                                 .canWriteBack_Out(can_write_back),

                                 .memAddr_Out(if_mem_addr_out),
                                 .memData_Out(if_mem_data_out),
                                 .memDataWidth_Out(if_mem_data_width_out),
                                 .memIsRead_Out(if_mem_is_read_out),
                                 .memAccess_Out(if_mem_access_out),

                                 .memAccessOK_In(if_mem_ok_in),
                                 .memData_In(if_mem_data_in),
                                 .memException_In(if_mem_exception_in),

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
    wire [`EXCEPTION_LEN - 1 : 0] id_exception;
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
    wire [31 : 0] ex_mem_addr_out;
    wire [31 : 0] ex_mem_data_out;
    wire [1 : 0] ex_mem_data_width_out;
    wire ex_mem_is_read_out;
    wire ex_mem_access_out;
    wire ex_mem_ok_in;
    wire [31 : 0] ex_mem_data_in;
    wire [`EXCEPTION_LEN - 1 : 0] ex_mem_exception_in;
    wire [`EXCEPTION_LEN - 1 : 0] ex_exception;
    Executor executor(.rdAddr_Out(exec_rd_address),
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

                      .memAddr_Out(ex_mem_addr_out),
                      .memData_Out(ex_mem_data_out),
                      .memDataWidth_Out(ex_mem_data_width_out),
                      .memIsRead_Out(ex_mem_is_read_out),
                      .memAccess_Out(ex_mem_access_out),

                      .memAccessOK_In(ex_mem_ok_in),
                      .memData_In(ex_mem_data_in),
                      .memException_In(ex_mem_exception_in),

                      .canWriteBack_In(can_write_back),
                      .instrIsConsumed_Out(instr_consumed),

                      .exception_Out(ex_exception));

    RegisterFile reg_file(.clk(cpu_clk),
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

    // Memory access modules
    wire [31 : 0] rom_addr_in;
    wire [1 : 0] rom_data_width_in;
    wire rom_input_valid_in;
    wire [31 : 0] rom_data_out;
    wire rom_ok_out;
    wire [`EXCEPTION_LEN - 1 : 0] rom_exception;
    ROM rom(.clk(cpu_clk),
            .rst(cpu_rst),

            .addr_In(rom_addr_in),
            .dataWidth_In(rom_data_width_in),
            .inputValid_In(rom_input_valid_in),

            .data_Out(rom_data_out),
            .operationOK_Out(rom_ok_out),

            .exception_Out(rom_exception));

    wire [31 : 0] ram_addr_in;
    wire [31 : 0] ram_data_in;
    wire [1 : 0] ram_data_width_in;
    wire ram_is_read_in;
    wire ram_input_valid_in;
    wire [31 : 0] ram_data_out;
    wire ram_ok_out;
    wire [`EXCEPTION_LEN - 1 : 0] ram_exception;
    RAM ram(.clk(cpu_clk),
            .rst(cpu_rst),

            .addr_In(ram_addr_in),
            .data_In(ram_data_in),
            .dataWidth_In(ram_data_width_in),
            .isRead_In(ram_is_read_in),
            .inputValid_In(ram_input_valid_in),

            .data_Out(ram_data_out),
            .operationOK_Out(ram_ok_out),

            .exception_Out(ram_exception));

    wire [31 : 0] io_addr_in;
    wire [31 : 0] io_data_in;
    wire [1 : 0] io_data_width_in;
    wire io_is_read_in;
    wire io_input_valid_in;
    wire [31 : 0] io_data_out;
    wire io_ok_out;
    wire [`EXCEPTION_LEN - 1 : 0] io_exception;
    IO io(.clk(cpu_clk),
          .rst(cpu_rst),

          .addr_In(io_addr_in),
          .data_In(io_data_in),
          .dataWidth_In(io_data_width_in),
          .isRead_In(io_is_read_in),
          .inputValid_In(io_input_valid_in),

          .data_Out(io_data_out),
          .operationOK_Out(io_ok_out),

          .exception_Out(io_exception));

    Access access(.clk(cpu_clk),
                  .rst(cpu_rst),

                  .a_addr_In(if_mem_addr_out),
                  .a_data_In(if_mem_data_out),
                  .a_dataWidth_In(if_mem_data_width_out),
                  .a_isRead_In(if_mem_is_read_out),
                  .a_inputValid_In(if_mem_access_out),
                  .a_operationOK_Out(if_mem_ok_in),
                  .a_data_Out(if_mem_data_in),
                  .a_exception_Out(if_mem_exception_in),

                  .b_addr_In(ex_mem_addr_out),
                  .b_data_In(ex_mem_data_out),
                  .b_dataWidth_In(ex_mem_data_width_out),
                  .b_isRead_In(ex_mem_is_read_out),
                  .b_inputValid_In(ex_mem_access_out),
                  .b_operationOK_Out(ex_mem_ok_in),
                  .b_data_Out(ex_mem_data_in),
                  .b_exception_Out(ex_mem_exception_in),

                  // Interface for ROM
                  .addrROM_Out(rom_addr_in),
                  .dataWidthROM_Out(rom_data_width_in),
                  .selectROM_Out(rom_input_valid_in),

                  .ROMFinish_In(rom_ok_out),
                  .ROMData_In(rom_data_out),
                  .ROMException_In(rom_exception),

                  // Interface for RAM
                  .addrRAM_Out(ram_addr_in),
                  .dataRAM_Out(ram_data_in),
                  .dataWidthRAM_Out(ram_data_width_in),
                  .isReadRAM_Out(ram_is_read_in),
                  .selectRAM_Out(ram_input_valid_in),

                  .RAMFinish_In(ram_ok_out),
                  .RAMData_In(ram_data_out),
                  .RAMException_In(ram_exception),

                  // Interface for IO
                  .addrIO_Out(io_addr_in),
                  .dataIO_Out(io_data_in),
                  .dataWidthIO_Out(io_data_width_in),
                  .isReadIO_Out(io_is_read_in),
                  .selectIO_Out(io_input_valid_in),

                  .IOFinish_In(io_ok_out),
                  .IOData_In(io_data_out),
                  .IOException_In(io_exception));

    // Generate core exception
    always @(*)
    begin
        if (if_exception != `EXCEP_OK)
            exception = if_exception;
        else if (id_exception != `EXCEP_OK)
            exception = if_exception;
        else
            exception = ex_exception;
    end
endmodule