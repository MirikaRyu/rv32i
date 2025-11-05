`include "src/constants.v"

/* Memory Region =============== */
/* ROM: [0   , 1GiB), 1GiB Total */
/* RAM: [1GiB, 3GiB), 2GiB Total */
/* IO:  [3GiB, 4GiB), 1GiB Total */

/* Define a port with its buffer regs */
/* Note: Negative edge trigger is used here to save cycles */
`define PORT(port)                                                                                                     \
    reg port``_operation_OK;                                                                                           \
    reg [31 : 0] port``_data;                                                                                          \
    always @(negedge clk)                                                                                              \
    begin                                                                                                              \
        if (rst)                                                                                                       \
        begin                                                                                                          \
            port``_operationOK_Out <= 0;                                                                               \
            port``_data_Out <= 0;                                                                                      \
        end                                                                                                            \
        else                                                                                                           \
        begin                                                                                                          \
            port``_operationOK_Out <= port``_operation_OK;                                                             \
            port``_data_Out <= port``_data;                                                                            \
        end                                                                                                            \
    end

/* Find out which component the port will use */
`define ACCESS_TYPE_ROM 2'b01
`define ACCESS_TYPE_RAM 2'b10
`define ACCESS_TYPE_IO 2'b11
`define GET_ACCESS_TYPE(port)                                                                                          \
    reg [1 : 0] port``_access_type;                                                                                    \
    always @(*)                                                                                                        \
    begin                                                                                                              \
        if (~|port``_addr_In[31 : 30])                                                                                 \
            port``_access_type = `ACCESS_TYPE_ROM;                                                                     \
        else if (^port``_addr_In[31 : 30])                                                                             \
            port``_access_type = `ACCESS_TYPE_RAM;                                                                     \
        else                                                                                                           \
            port``_access_type = `ACCESS_TYPE_IO;                                                                      \
    end

/* Generate exceptions */
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

/* Connect a port to component */
`define CONNECT(port)                                                                                                  \
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

/* Memory access state machine definition */
`define STATE_IDLE 2'b00
`define STATE_A 2'b01
`define STATE_B 2'b10
`define STATE_AB 2'b11

module Access
    (input wire clk,
     input wire rst,

     /* Memory Access Port A */
     /* Note: Port A has a higher priority than port B */
     /* Note: Output will keep valid for 1 cycle exactly after input is invalidated */
     input wire [31 : 0] a_addr_In,
     input wire [31 : 0] a_data_In,
     input wire [1 : 0] a_dataWidth_In,
     input wire a_isRead_In,
     input wire a_inputValid_In,
     output reg a_operationOK_Out,
     output reg [31 : 0] a_data_Out,
     output reg [`EXCEPTION_LEN - 1 : 0] a_exception_Out,

     /* Memory Access Port B */
     input wire [31 : 0] b_addr_In,
     input wire [31 : 0] b_data_In,
     input wire [1 : 0] b_dataWidth_In,
     input wire b_isRead_In,
     input wire b_inputValid_In,
     output reg b_operationOK_Out,
     output reg [31 : 0] b_data_Out,
     output reg [`EXCEPTION_LEN - 1 : 0] b_exception_Out,

     /* ROM Interface */
     output reg [31 : 0] addrROM_Out,
     output reg [1 : 0] dataWidthROM_Out,
     output reg selectROM_Out,
     input wire ROMFinish_In,
     input wire [31 : 0] ROMData_In,
     input wire [`EXCEPTION_LEN - 1 : 0] ROMException_In,

     /* RAM Interface */
     output reg [31 : 0] addrRAM_Out,
     output reg [31 : 0] dataRAM_Out,
     output reg [1 : 0] dataWidthRAM_Out,
     output reg isReadRAM_Out,
     output reg selectRAM_Out,
     input wire RAMFinish_In,
     input wire [31 : 0] RAMData_In,
     input wire [`EXCEPTION_LEN - 1 : 0] RAMException_In,

     /* IO Interface */
     output reg [31 : 0] addrIO_Out,
     output reg [31 : 0] dataIO_Out,
     output reg [1 : 0] dataWidthIO_Out,
     output reg isReadIO_Out,
     output reg selectIO_Out,
     input wire IOFinish_In,
     input wire [31 : 0] IOData_In,
     input wire [`EXCEPTION_LEN - 1 : 0] IOException_In);

    `PORT(a)
    `PORT(b)

    `GET_ACCESS_TYPE(a)
    `GET_ACCESS_TYPE(b)

    `GEN_EXCEPTION(a)
    `GEN_EXCEPTION(b)

    /* State transfers */
    reg [1 : 0] state;
    reg [1 : 0] next_state;
    always @(posedge clk)
    begin
        if (rst)
            state <= `STATE_IDLE;
        else
            state <= next_state;
    end

    always @(*)
    begin
        case (state)
            `STATE_IDLE:
                if (a_inputValid_In && b_inputValid_In && a_access_type != b_access_type)
                    next_state = `STATE_AB;
                else if (a_inputValid_In)
                    next_state = `STATE_A;
                else if (b_inputValid_In)
                    next_state = `STATE_B;
                else
                    next_state = `STATE_IDLE;
            `STATE_A:
                if (b_inputValid_In && a_access_type != b_access_type)
                    next_state = a_inputValid_In ? `STATE_AB : `STATE_B;
                else
                    next_state = a_inputValid_In ? `STATE_A : `STATE_IDLE;
            `STATE_B:
                if (a_inputValid_In && a_access_type != b_access_type)
                    next_state = b_inputValid_In ? `STATE_AB : `STATE_A;
                else
                    next_state = b_inputValid_In ? `STATE_B : `STATE_IDLE;
            `STATE_AB:
                if (a_inputValid_In && b_inputValid_In)
                    next_state = `STATE_AB;
                else if (a_inputValid_In)
                    next_state = `STATE_A;
                else if (b_inputValid_In)
                    next_state = `STATE_B;
                else
                    next_state = `STATE_IDLE;
        endcase
    end

    always @(*)
    begin
        /* Set default connections for IDLE state */
        addrROM_Out = (addrRAM_Out = (addrIO_Out = 0));
        dataRAM_Out = (dataIO_Out = 0);
        dataWidthROM_Out = (dataWidthRAM_Out = (dataWidthIO_Out = 0));
        isReadRAM_Out = (isReadIO_Out = 0);
        selectROM_Out = (selectRAM_Out = (selectIO_Out = 0));

        a_operation_OK = (b_operation_OK = 0);
        a_data = (b_data = 0);

        /* Actions on specific state */
        case (state)
            `STATE_IDLE:
                if (next_state == `STATE_AB)
                begin
                    `CONNECT(a)
                    `CONNECT(b)
                end
                else if (next_state == `STATE_A)
                    `CONNECT(a)
                else if (next_state == `STATE_B)
                    `CONNECT(b)
            `STATE_A:
                if (next_state == `STATE_AB || next_state == `STATE_B)
                    `CONNECT(b)
                else
                    `CONNECT(a)
            `STATE_B:
                if (next_state == `STATE_AB || next_state == `STATE_A)
                    `CONNECT(a)
                else
                    `CONNECT(b)
            `STATE_AB: begin
                `CONNECT(a)
                `CONNECT(b)
            end
        endcase
    end
endmodule