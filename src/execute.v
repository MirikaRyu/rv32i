`include "constants.v"

module Executor
    (
        /* `Exeuctor` is pure combinational logic */

        /* PC update */
        output reg [31 : 0] pcWrite_Out,
        output reg pcFlush_Out,

        /* Writeback to rd */
        output reg [4 : 0] rdAddr_Out,
        output reg [31 : 0] rdWrite_Out,
        output reg rdEnable_Out,

        /* Opcode/Operand input */
        input wire [5 : 0] opCode_In,
        input wire [4 : 0] rdAddr_In,
        input wire [31 : 0] resource1_In,
        input wire [31 : 0] resource2_In,
        input wire [31 : 0] offset_In,
        input wire [31 : 0] pc_In,

        /* Memory access interface */
        output reg [31 : 0] memAddr_Out,
        output reg [31 : 0] memData_Out,
        output reg [1 : 0] memDataWidth_Out,
        output reg memIsRead_Out,
        output wire memAccess_Out,
        input wire memAccessOK_In,
        input wire [31 : 0] memData_In,
        input wire [`EXCEPTION_LEN - 1 : 0] memException_In,

        /* Synchronization with frontend */
        input wire canWriteBack_In,
        output wire instrIsConsumed_Out,

        /* Module exception out */
        output reg [`EXCEPTION_LEN - 1 : 0] exception_Out);

    reg try_access_mem;
    assign memAccess_Out = !canWriteBack_In && try_access_mem;           // Keep data valid until writeback
    assign instrIsConsumed_Out = try_access_mem ? memAccessOK_In : 1'b1; // Finish in 1 cycle when don't access memory

    reg [31 : 0] alu_inputA;
    reg [31 : 0] alu_inputB;
    reg [5 : 0] alu_op;
    wire [31 : 0] alu_result;
    ALU alu(.inputA_In(alu_inputA),
            .inputB_In(alu_inputB),
            .opCode_In(alu_op),

            .result_Out(alu_result));

    reg [31 : 0] pc_alu_input;
    reg pc_alu_add_offset;
    wire [31 : 0] pc_alu_result;
    PCALU pc_alu(.pc_In(pc_In),
                 .offset_In(pc_alu_input),
                 .plusOffset_In(pc_alu_add_offset),

                 .pc_Out(pc_alu_result));

    /* Dispatch opCode */
    always @(*)
    begin
        /* Set the default signal connection, override when needed */
        alu_op = opCode_In;
        alu_inputA = resource1_In;
        alu_inputB = resource2_In;

        pc_alu_input = offset_In;
        pc_alu_add_offset = 0;

        rdAddr_Out = rdAddr_In;
        rdWrite_Out = alu_result;
        rdEnable_Out = canWriteBack_In;

        pcWrite_Out = pc_alu_result;
        pcFlush_Out = 0;

        memAddr_Out = alu_result;
        memData_Out = 0;
        memDataWidth_Out = `MEM_WIDTH_NONE;
        memIsRead_Out = 1;
        try_access_mem = 0;

        exception_Out = memException_In;

        case (opCode_In)
            // Arithmetic instructions
            `INSTR_OP_ADD, `INSTR_OP_SUB:
                ;
            `INSTR_OP_AND, `INSTR_OP_OR, `INSTR_OP_XOR:
                ;
            `INSTR_OP_LOGIC_SHIFT_L, `INSTR_OP_LOGIC_SHIFT_R, `INSTR_OP_ARITH_SHIFT_R:
                ;
            `INSTR_OP_CMP_LESS, `INSTR_OP_CMP_LESS_UNSIGN:
                ;

            // LUI and AUIPC
            `INSTR_OP_LUI:
                rdWrite_Out = resource1_In;

            `INSTR_OP_AUIPC: begin
                alu_op = `INSTR_OP_ADD;
                alu_inputA = pc_In;
                alu_inputB = 32'd4;
                pcWrite_Out = alu_result;

                pc_alu_input = 0;
                pc_alu_add_offset = 1;
                rdWrite_Out = pc_alu_result;
            end

            // Load and store
            `INSTR_OP_LOAD_WORD: begin
                alu_op = `INSTR_OP_ADD;

                memDataWidth_Out = `MEM_WIDTH_WORD;
                rdWrite_Out = memData_In;
                try_access_mem = 1;
            end

            `INSTR_OP_LOAD_HALF, `INSTR_OP_LOAD_HALF_UNSIGN: begin
                alu_op = `INSTR_OP_ADD;

                memDataWidth_Out = `MEM_WIDTH_HALF;
                if (opCode_In == `INSTR_OP_LOAD_HALF)
                    rdWrite_Out = {{16{memData_In[15]}}, memData_In[15 : 0]};
                else
                    rdWrite_Out = {16'b0, memData_In[15 : 0]};
                try_access_mem = 1;
            end

            `INSTR_OP_LOAD_BYTE, `INSTR_OP_LOAD_BYTE_UNSIGN: begin
                alu_op = `INSTR_OP_ADD;

                memDataWidth_Out = `MEM_WIDTH_BYTE;
                if (opCode_In == `INSTR_OP_LOAD_BYTE)
                    rdWrite_Out = {{24{memData_In[7]}}, memData_In[7 : 0]};
                else
                    rdWrite_Out = {24'b0, memData_In[7 : 0]};
                try_access_mem = 1;
            end

            `INSTR_OP_STORE_WORD, `INSTR_OP_STORE_HALF, `INSTR_OP_STORE_BYTE: begin
                alu_inputB = offset_In;
                alu_op = `INSTR_OP_ADD;
                rdEnable_Out = 0;

                case (opCode_In)
                    `INSTR_OP_STORE_WORD:
                        memDataWidth_Out = `MEM_WIDTH_WORD;
                    `INSTR_OP_STORE_HALF:
                        memDataWidth_Out = `MEM_WIDTH_HALF;
                    `INSTR_OP_STORE_BYTE:
                        memDataWidth_Out = `MEM_WIDTH_BYTE;
                    default:
                        memDataWidth_Out = `MEM_WIDTH_NONE;
                endcase
                memData_Out = resource2_In;
                memIsRead_Out = 0;
                try_access_mem = 1;
            end

            // Branch and jump
            `INSTR_OP_BR_EQ, `INSTR_OP_BR_N_EQ: begin
                rdEnable_Out = 0;

                if ((resource1_In != resource2_In) ^ (opCode_In == `INSTR_OP_BR_EQ))
                begin
                    pc_alu_add_offset = 1;
                    pcFlush_Out = 1;
                end
            end

            `INSTR_OP_BR_LESS, `INSTR_OP_BR_LESS_UNSIGN, `INSTR_OP_BR_GREATER, `INSTR_OP_BR_GREATER_UNSIGN: begin
                rdEnable_Out = 0;

                if (opCode_In == `INSTR_OP_BR_LESS || opCode_In == `INSTR_OP_BR_GREATER)
                    alu_op = `INSTR_OP_CMP_LESS;
                else
                    alu_op = `INSTR_OP_CMP_LESS_UNSIGN;

                if ((|alu_result ^ (opCode_In == `INSTR_OP_BR_GREATER || opCode_In == `INSTR_OP_BR_GREATER_UNSIGN)) ||
                    (~|alu_result ^ (opCode_In == `INSTR_OP_BR_LESS || opCode_In == `INSTR_OP_BR_LESS_UNSIGN)))
                begin
                    pc_alu_add_offset = 1;
                    pcFlush_Out = 1;
                end
            end

            `INSTR_OP_JMP_LINK: begin
                rdWrite_Out = pc_In;

                pc_alu_add_offset = 1;
                pcFlush_Out = 1;

                if (|pcWrite_Out[1 : 0])
                    exception_Out = `EXCEP_MISALIGNED_INSTR;
            end

            `INSTR_OP_JMP_REG_LINK: begin
                rdWrite_Out = pc_In;

                alu_op = `INSTR_OP_ADD;

                pcWrite_Out = alu_result & ~32'b1;
                pcFlush_Out = 1;

                if (|pcWrite_Out[1 : 0])
                    exception_Out = `EXCEP_MISALIGNED_INSTR;
            end

            // ECALL and EBREAK
            `INSTR_OP_ECALL: begin
                rdWrite_Out = 0;
                exception_Out = `EXCEP_ENV_CALL;
            end

            `INSTR_OP_EBREAK: begin
                rdWrite_Out = 0;
                exception_Out = `EXCEP_ENV_BREAK;
            end

            // FENCE
            `INSTR_OP_FENCE:
                rdWrite_Out = 0; // No need to implement

            default: begin
                rdWrite_Out = 0;
                exception_Out = `EXCEP_ILLEGAL_INSTR;
            end
        endcase
    end
endmodule

module ALU
    (input wire [31 : 0] inputA_In,
     input wire [31 : 0] inputB_In,
     input wire [5 : 0] opCode_In,

     output reg [31 : 0] result_Out);

    wire [31 : 0] sub_result = inputA_In - inputB_In;

    always @(*)
    begin
        case (opCode_In)
            `INSTR_OP_ADD:
                result_Out = inputA_In + inputB_In;
            `INSTR_OP_SUB:
                result_Out = sub_result;
            `INSTR_OP_AND:
                result_Out = inputA_In & inputB_In;
            `INSTR_OP_OR:
                result_Out = inputA_In | inputB_In;
            `INSTR_OP_XOR:
                result_Out = inputA_In ^ inputB_In;
            `INSTR_OP_LOGIC_SHIFT_L:
                result_Out = inputA_In << inputB_In[4 : 0];
            `INSTR_OP_LOGIC_SHIFT_R:
                result_Out = inputA_In >> inputB_In[4 : 0];
            `INSTR_OP_ARITH_SHIFT_R:
                result_Out = $signed(inputA_In) >>> inputB_In[4 : 0];
            `INSTR_OP_CMP_LESS:
                if (inputA_In[31] == inputB_In[31])
                    result_Out = sub_result[31] ? 32'b1 : 0;
                else
                    result_Out = inputA_In[31] ? 32'b1 : 0;
            `INSTR_OP_CMP_LESS_UNSIGN:
                result_Out = (inputA_In < inputB_In) ? 32'b1 : 0;
            default:
                result_Out = 0;
        endcase
    end
endmodule

module PCALU
    (input wire [31 : 0] pc_In,
     input wire [31 : 0] offset_In,
     input wire plusOffset_In,

     output wire [31 : 0] pc_Out);

    assign pc_Out = plusOffset_In ? (pc_In + offset_In) - 4 : pc_In + 4;
endmodule