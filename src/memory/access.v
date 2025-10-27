/* Access the unified memory space */

`include "src/constants.v"

`define ACCESS_TYPE_ROM 2'b01
`define ACCESS_TYPE_RAM 2'b10
`define ACCESS_TYPE_IO 2'b11

// Find out which hardware the port will use
`define GET_ACCESS_TYPE(port)                                                                                          \
    reg [1 : 0] port``_access_type;                                                                                    \
    always @(*)                                                                                                        \
    begin                                                                                                              \
                                                                                                                       \
        if (~|port``_addr_In[31 : 30])                                                                                 \
            port``_access_type = `ACCESS_TYPE_ROM;                                                                     \
        else if (^port``_addr_In[31 : 30])                                                                             \
            port``_access_type = `ACCESS_TYPE_RAM;                                                                     \
        else                                                                                                           \
            port``_access_type = `ACCESS_TYPE_IO;                                                                      \
    end

// Connect a port to a specific part
`define CONNECT_PORT(port)                                                                                             \
    case (port``_access_type)                                                                                          \
        `ACCESS_TYPE_ROM: begin                                                                                        \
            addrROM_Out = {2'b0, port``_addr_In[29 : 0]};                                                              \
            dataWidthROM_Out = port``_dataWidth_In;                                                                    \
            selectROM_Out = port``_inputValid_In;                                                                      \
                                                                                                                       \
            port``_operation_OK = ROMFinish_In;                                                                        \
            port``_data = ROMData_In;                                                                                  \
        end                                                                                                            \
        `ACCESS_TYPE_RAM: begin                                                                                        \
            if (port``_addr_In[31 : 30] == 2'b01)                                                                      \
                addrRAM_Out = {2'b0, port``_addr_In[29 : 0]};                                                          \
            else                                                                                                       \
                addrRAM_Out = {2'b01, port``_addr_In[29 : 0]};                                                         \
            dataRAM_Out = port``_data_In;                                                                              \
            dataWidthRAM_Out = port``_dataWidth_In;                                                                    \
            isReadRAM_Out = port``_isRead_In;                                                                          \
            selectRAM_Out = port``_inputValid_In;                                                                      \
                                                                                                                       \
            port``_operation_OK = RAMFinish_In;                                                                        \
            port``_data = RAMData_In;                                                                                  \
        end                                                                                                            \
        `ACCESS_TYPE_IO: begin                                                                                         \
            addrIO_Out = {2'b0, port``_addr_In[29 : 0]};                                                               \
            dataIO_Out = port``_data_In;                                                                               \
            dataWidthIO_Out = port``_dataWidth_In;                                                                     \
            isReadIO_Out = port``_isRead_In;                                                                           \
            selectIO_Out = port``_inputValid_In;                                                                       \
                                                                                                                       \
            port``_operation_OK = IOFinish_In;                                                                         \
            port``_data = IOData_In;                                                                                   \
        end                                                                                                            \
        default:                                                                                                       \
            ;                                                                                                          \
    endcase

// Handle exceptions
`define GEN_EXCEPTION(port)                                                                                            \
    always @(*)                                                                                                        \
    begin                                                                                                              \
        port``_exception_Out = port``_isRead_In ? `EXCEP_INVALID_MEM_READ : `EXCEP_INVALID_MEM_WRITE;                  \
                                                                                                                       \
        if (!port``_inputValid_In)                                                                                     \
            port``_exception_Out = `EXCEP_OK;                                                                          \
        else                                                                                                           \
        begin                                                                                                          \
            if (port``_dataWidth_In == `MEM_WIDTH_BYTE)                                                                \
                port``_exception_Out = `EXCEP_OK;                                                                      \
            else if (port``_dataWidth_In == `MEM_WIDTH_HALF && ~port``_addr_In[0])                                     \
                port``_exception_Out = `EXCEP_OK;                                                                      \
            else if (port``_dataWidth_In == `MEM_WIDTH_WORD && ~|port``_addr_In[1 : 0])                                \
                port``_exception_Out = `EXCEP_OK;                                                                      \
                                                                                                                       \
            case (port``_access_type)                                                                                  \
                `ACCESS_TYPE_ROM:                                                                                      \
                    port``_exception_Out = ROMException_In;                                                            \
                `ACCESS_TYPE_RAM:                                                                                      \
                    port``_exception_Out = RAMException_In;                                                            \
                `ACCESS_TYPE_IO:                                                                                       \
                    port``_exception_Out = IOException_In;                                                             \
                default:                                                                                               \
                    port``_exception_Out = port``_isRead_In ? `EXCEP_INVALID_MEM_READ : `EXCEP_INVALID_MEM_WRITE;      \
            endcase                                                                                                    \
        end                                                                                                            \
    end

module Access
    (input wire clk,
     input wire rst,

     // Interface for reading/writing memory
     input wire [31 : 0] a_addr_In,
     input wire [31 : 0] a_data_In,
     input wire [1 : 0] a_dataWidth_In,
     input wire a_isRead_In,
     input wire a_inputValid_In,
     output reg a_operationOK_Out,
     output reg [31 : 0] a_data_Out,
     output reg [`EXCEPTION_LEN - 1 : 0] a_exception_Out,

     input wire [31 : 0] b_addr_In,
     input wire [31 : 0] b_data_In,
     input wire [1 : 0] b_dataWidth_In,
     input wire b_isRead_In,
     input wire b_inputValid_In,
     output reg b_operationOK_Out,
     output reg [31 : 0] b_data_Out,
     output reg [`EXCEPTION_LEN - 1 : 0] b_exception_Out,

     // Interface for ROM
     output reg [31 : 0] addrROM_Out,
     output reg [1 : 0] dataWidthROM_Out,
     output reg selectROM_Out,

     input wire ROMFinish_In,
     input wire [31 : 0] ROMData_In,
     input wire [`EXCEPTION_LEN - 1 : 0] ROMException_In,

     // Interface for RAM
     output reg [31 : 0] addrRAM_Out,
     output reg [31 : 0] dataRAM_Out,
     output reg [1 : 0] dataWidthRAM_Out,
     output reg isReadRAM_Out,
     output reg selectRAM_Out,

     input wire RAMFinish_In,
     input wire [31 : 0] RAMData_In,
     input wire [`EXCEPTION_LEN - 1 : 0] RAMException_In,

     // Interface for IO
     output reg [31 : 0] addrIO_Out,
     output reg [31 : 0] dataIO_Out,
     output reg [1 : 0] dataWidthIO_Out,
     output reg isReadIO_Out,
     output reg selectIO_Out,

     input wire IOFinish_In,
     input wire [31 : 0] IOData_In,
     input wire [`EXCEPTION_LEN - 1 : 0] IOException_In);

    `GET_ACCESS_TYPE(a)
    `GET_ACCESS_TYPE(b)

    `GEN_EXCEPTION(a)
    `GEN_EXCEPTION(b)

    // Dispatch memory access requests
    reg a_operation_OK;
    reg [31 : 0] a_data;
    reg b_operation_OK;
    reg [31 : 0] b_data;
    always @(*)
    begin
        addrROM_Out = (addrRAM_Out = (addrIO_Out = 0));
        dataRAM_Out = (dataIO_Out = 0);
        dataWidthROM_Out = (dataWidthRAM_Out = (dataWidthIO_Out = 0));
        isReadRAM_Out = (isReadIO_Out = 0);
        selectROM_Out = (selectRAM_Out = (selectIO_Out = 0));

        a_operation_OK = (b_operation_OK = 0);
        a_data = (b_data = 0);

        if ((a_inputValid_In ^ b_inputValid_In) |
            (a_inputValid_In & b_inputValid_In & (a_access_type != b_access_type)))
        begin
            if (a_inputValid_In)
                `CONNECT_PORT(a)
            if (b_inputValid_In)
                `CONNECT_PORT(b)
        end
        else if (a_inputValid_In & b_inputValid_In)
            `CONNECT_PORT(b)
    end

    always @(posedge clk)
    begin
        if (rst)
        begin
            a_operationOK_Out <= 0;
            a_data_Out <= 0;
        end
        else
        begin
            a_operationOK_Out <= a_operation_OK;
            a_data_Out <= a_data;
        end
    end

    always @(posedge clk)
    begin
        if (rst)
        begin
            b_operationOK_Out <= 0;
            b_data_Out <= 0;
        end
        else
        begin
            b_operationOK_Out <= b_operation_OK;
            b_data_Out <= b_data;
        end
    end
endmodule