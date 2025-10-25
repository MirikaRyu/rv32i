/* Execute opCode generated from decoder */

`include "constants.v"

module Executor
    (input wire clk,
     input wire rst,

     output reg [4 : 0] rdAddr_Out,
     output reg [31 : 0] rdWrite_Out,
     output reg rdEnable_Out,

     output reg [31 : 0] pcWrite_Out,
     output reg pcFlush_Out,

     input wire [5 : 0] opCode_In,
     input wire [4 : 0] rdAddr_In,
     input wire [31 : 0] resource1_In,
     input wire [31 : 0] resource2_In,
     input wire [31 : 0] offset_In,
     input wire [31 : 0] pc_In,

     input wire execLockRead_In,
     output reg execLockSet_Out,

     output reg [`EXCEPTION_LEN - 1 : 0] exception_Out);

    reg [31 : 0] mem_addr;
    reg [31 : 0] mem_data;
    reg [1 : 0] mem_width;
    reg is_mem_read;
    reg try_access_mem;
    wire [`EXCEPTION_LEN - 1 : 0] mem_exception;
    wire [31 : 0] mem_data_out;
    wire mem_ready;
    wire access_mem = try_access_mem && !mem_ready;
    RAMAccess data_mem(.clk(clk),
                       .rst(rst),

                       .addr_In(mem_addr),
                       .data_In(mem_data),
                       .dataWidth_In(mem_width),
                       .isRead_In(is_mem_read),
                       .inputValid_In(access_mem),

                       .exception_Out(mem_exception),
                       .data_Out(mem_data_out),
                       .operationOK_Out(mem_ready));

    reg [31 : 0] alu_inputA;
    reg [31 : 0] alu_inputB;
    reg [3 : 0] alu_op;
    wire [31 : 0] alu_result;
    ALU alu(.inputA_In(alu_inputA),
            .inputB_In(alu_inputB),
            .funct_In(alu_op),

            .result_Out(alu_result));

    reg [31 : 0] pc_alu_input;
    reg pc_alu_add_offset;
    wire [31 : 0] pc_alu_result;
    PCALU pc_alu(.pc_In(pc_In),
                 .offset_In(pc_alu_input),
                 .plusOffset_In(pc_alu_add_offset),

                 .pc_Out(pc_alu_result));

    always @(*)
    begin
        rdAddr_Out = rdAddr_In;
        rdWrite_Out = alu_result;
        rdEnable_Out = ~execLockRead_In;

        alu_op = `INSTR_ALU_NONE;
        alu_inputA = resource1_In;
        alu_inputB = resource2_In;

        pcWrite_Out = pc_alu_result;
        pc_alu_add_offset = 0;
        pc_alu_input = offset_In;
        pcFlush_Out = 0;

        mem_addr = alu_result;
        mem_data = 0;
        mem_width = `MEM_WIDTH_NONE;
        is_mem_read = 1;
        try_access_mem = 0;

        execLockSet_Out = access_mem;
        exception_Out = mem_exception;

        case (opCode_In)
            // Arithmetic instructions
            `INSTR_OP_ADD:
                alu_op = `INSTR_ALU_ADD;
            `INSTR_OP_SUB:
                alu_op = `INSTR_ALU_SUB;
            `INSTR_OP_AND:
                alu_op = `INSTR_ALU_AND;
            `INSTR_OP_OR:
                alu_op = `INSTR_ALU_OR;
            `INSTR_OP_XOR:
                alu_op = `INSTR_ALU_XOR;
            `INSTR_OP_LOGIC_SHIFT_L:
                alu_op = `INSTR_ALU_LOG_SFT_L;
            `INSTR_OP_LOGIC_SHIFT_R:
                alu_op = `INSTR_ALU_LOG_SHF_R;
            `INSTR_OP_ARITH_SHIFT_R:
                alu_op = `INSTR_ALU_ARI_SHF_R;
            `INSTR_OP_CMP_LESS:
                alu_op = `INSTR_ALU_CMP_LESS;
            `INSTR_OP_CMP_LESS_UNSIGN:
                alu_op = `INSTR_ALU_CMP_LESS_UNSIGN;

            // LUI and AUIPC
            `INSTR_OP_LUI:
                rdWrite_Out = resource1_In;

            `INSTR_OP_AUIPC: begin
                alu_op = `INSTR_ALU_PC_ADD;
                alu_inputB = pc_In;
            end

            // Load and store
            `INSTR_OP_LOAD_WORD: begin
                alu_op = `INSTR_ALU_ADD;

                mem_width = `MEM_WIDTH_WORD;
                rdWrite_Out = mem_data_out;
                try_access_mem = 1;
            end

            `INSTR_OP_LOAD_HALF, `INSTR_OP_LOAD_HALF_UNSIGN: begin
                alu_op = `INSTR_ALU_ADD;

                mem_width = `MEM_WIDTH_HALF;
                if (opCode_In == `INSTR_OP_LOAD_HALF)
                    rdWrite_Out = {{16{mem_data_out[15]}}, mem_data_out[15 : 0]};
                else
                    rdWrite_Out = {16'b0, mem_data_out[15 : 0]};
                try_access_mem = 1;
            end

            `INSTR_OP_LOAD_BYTE, `INSTR_OP_LOAD_BYTE_UNSIGN: begin
                alu_op = `INSTR_ALU_ADD;

                mem_width = `MEM_WIDTH_BYTE;
                if (opCode_In == `INSTR_OP_LOAD_BYTE)
                    rdWrite_Out = {{24{mem_data_out[7]}}, mem_data_out[7 : 0]};
                else
                    rdWrite_Out = {24'b0, mem_data_out[7 : 0]};
                try_access_mem = 1;
            end

            `INSTR_OP_STORE_WORD, `INSTR_OP_STORE_HALF, `INSTR_OP_STORE_BYTE: begin
                alu_inputB = offset_In;
                alu_op = `INSTR_ALU_ADD;
                rdEnable_Out = 0;

                case (opCode_In)
                    `INSTR_OP_STORE_WORD:
                        mem_width = `MEM_WIDTH_WORD;
                    `INSTR_OP_STORE_HALF:
                        mem_width = `MEM_WIDTH_HALF;
                    `INSTR_OP_STORE_BYTE:
                        mem_width = `MEM_WIDTH_BYTE;
                    default:
                        mem_width = `MEM_WIDTH_NONE;
                endcase
                mem_data = resource2_In;
                is_mem_read = 0;
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
                    alu_op = `INSTR_ALU_CMP_LESS;
                else
                    alu_op = `INSTR_ALU_CMP_LESS_UNSIGN;

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

                alu_op = `INSTR_ALU_ADD;

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
                rdWrite_Out = 0;

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
     input wire [3 : 0] funct_In,

     output reg [31 : 0] result_Out);

    wire [31 : 0] sub_result;
    assign sub_result = inputA_In - inputB_In;

    always @(*)
    begin
        case (funct_In)
            `INSTR_ALU_ADD:
                result_Out = inputA_In + inputB_In;
            `INSTR_ALU_SUB:
                result_Out = sub_result;
            `INSTR_ALU_AND:
                result_Out = inputA_In & inputB_In;
            `INSTR_ALU_OR:
                result_Out = inputA_In | inputB_In;
            `INSTR_ALU_XOR:
                result_Out = inputA_In ^ inputB_In;
            `INSTR_ALU_LOG_SFT_L:
                result_Out = inputA_In << inputB_In[4 : 0];
            `INSTR_ALU_LOG_SHF_R:
                result_Out = inputA_In >> inputB_In[4 : 0];
            `INSTR_ALU_ARI_SHF_R:
                result_Out = $signed(inputA_In) >>> inputB_In[4 : 0];
            `INSTR_ALU_CMP_LESS:
                if (inputA_In[31] == inputB_In[31])
                    result_Out = sub_result[31] ? 32'b1 : 0;
                else
                    result_Out = inputA_In[31] ? 32'b1 : 0;
            `INSTR_ALU_CMP_LESS_UNSIGN:
                result_Out = (inputA_In < inputB_In) ? 32'b1 : 0;
            `INSTR_ALU_PC_ADD:
                result_Out = inputA_In + inputB_In - 4;
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