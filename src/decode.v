`include "constants.v"

`define INSTR_TYPE_R 3'h0
`define INSTR_TYPE_I 3'h1
`define INSTR_TYPE_S 3'h2
`define INSTR_TYPE_B 3'h3
`define INSTR_TYPE_U 3'h4
`define INSTR_TYPE_J 3'h5
`define INSTR_TYPE_NONE 3'h7

module InstructionDecode
    (
        /* `Decoder` is pure combinational logic */

        /* Instruction input from frontend */
        input wire [31 : 0] instr_In,

        /* RS1 read interface */
        output reg [4 : 0] rs1Addr_Out,
        input wire [31 : 0] rs1_In,
        output reg rs1Enable_Out,

        /* RS2 read interface */
        output reg [4 : 0] rs2Addr_Out,
        input wire [31 : 0] rs2_In,
        output reg rs2Enable_Out,

        /* Opcode/Operand output */
        output reg [5 : 0] opCode_Out,
        output reg [4 : 0] rdAddr_Out,
        output reg [31 : 0] resource1_Out,
        output reg [31 : 0] resource2_Out,
        output reg [31 : 0] offset_Out,

        /* Module exception out */
        output wire [`EXCEPTION_LEN - 1 : 0] exception_Out);

    /* Extract instruction fields */
    wire [6 : 0] opcode = instr_In[6 : 0];
    wire [4 : 0] rd_addr = instr_In[11 : 7];
    wire [2 : 0] funct3 = instr_In[14 : 12];
    wire [4 : 0] rs1_addr = instr_In[19 : 15];
    wire [4 : 0] rs2_addr = instr_In[24 : 20];
    wire [6 : 0] funct7 = instr_In[31 : 25];

    /* Get instruction type */
    reg [2 : 0] instr_type;
    reg [`EXCEPTION_LEN - 1 : 0] type_exception;
    always @(*)
    begin
        type_exception = `EXCEP_OK;

        casez (opcode)
            7'b0110011:
                instr_type = `INSTR_TYPE_R; // R-R operations
            7'b00?0011, 7'b1100111:
                instr_type = `INSTR_TYPE_I; // LOAD / I-R operations / JALR
            7'b0?10111:
                instr_type = `INSTR_TYPE_U; // AUIPC / LUI
            7'b1100011:
                instr_type = `INSTR_TYPE_B; // Branch
            7'b1101111:
                instr_type = `INSTR_TYPE_J; // JAL
            7'b0100011:
                instr_type = `INSTR_TYPE_S; // STORE
            7'b1110011, 7'b0001111:
                instr_type = `INSTR_TYPE_NONE; // ECALL / EBREAK / FENCE
            default: begin
                instr_type = `INSTR_TYPE_NONE;
                type_exception = `EXCEP_ILLEGAL_INSTR;
            end
        endcase
    end

    /* Generate immediate number and output oprand */
    wire [31 : 0] imm;
    ImmediateGen imm_gen(.instr_In(instr_In),
                         .instrType_In(instr_type),
                         .imm_Out(imm));
    always @(*)
    begin
        case (instr_type)
            `INSTR_TYPE_R: begin
                rdAddr_Out = rd_addr;

                rs1Enable_Out = 1;
                rs2Enable_Out = 1;
                rs1Addr_Out = rs1_addr;
                rs2Addr_Out = rs2_addr;
                resource1_Out = rs1_In;
                resource2_Out = rs2_In;

                offset_Out = 0;
            end

            `INSTR_TYPE_I: begin
                rdAddr_Out = rd_addr;

                rs1Enable_Out = 1;
                rs1Addr_Out = rs1_addr;
                resource1_Out = rs1_In;

                rs2Enable_Out = 0;
                rs2Addr_Out = 0;
                resource2_Out = imm;
                // Note: LOAD/JALR are I-type instructions, their `offset` is in rs2

                offset_Out = 0;
            end

            `INSTR_TYPE_S, `INSTR_TYPE_B: begin
                rdAddr_Out = 0;

                rs1Enable_Out = 1;
                rs2Enable_Out = 1;
                rs1Addr_Out = rs1_addr;
                rs2Addr_Out = rs2_addr;
                resource1_Out = rs1_In;
                resource2_Out = rs2_In;

                offset_Out = imm;
            end

            `INSTR_TYPE_U: begin
                rdAddr_Out = rd_addr;

                rs1Enable_Out = 0;
                rs1Addr_Out = 0;
                resource1_Out = imm;

                rs2Enable_Out = 0;
                rs2Addr_Out = 0;
                resource2_Out = 0;

                offset_Out = 0;
            end

            `INSTR_TYPE_J: begin
                rdAddr_Out = rd_addr;

                rs1Enable_Out = 0;
                rs1Addr_Out = 0;
                resource1_Out = 0;

                rs2Enable_Out = 0;
                rs2Addr_Out = 0;
                resource2_Out = 0;

                offset_Out = imm;
            end

            default: begin
                rdAddr_Out = 0;

                rs1Enable_Out = 0;
                rs1Addr_Out = 0;
                resource1_Out = 0;

                rs2Enable_Out = 0;
                rs2Addr_Out = 0;
                resource2_Out = 0;

                offset_Out = 0;
            end
        endcase
    end

    /* Generate the opCode */
    reg [`EXCEPTION_LEN - 1 : 0] opcode_exception;
    always @(*)
    begin
        opCode_Out = `INSTR_OP_NONE;
        opcode_exception = `EXCEP_OK;

        case (instr_type)
            `INSTR_TYPE_R:
                if (~|funct7)
                    case (funct3)
                        3'b000:
                            opCode_Out = `INSTR_OP_ADD;
                        3'b001:
                            opCode_Out = `INSTR_OP_LOGIC_SHIFT_L;
                        3'b010:
                            opCode_Out = `INSTR_OP_CMP_LESS;
                        3'b011:
                            opCode_Out = `INSTR_OP_CMP_LESS_UNSIGN;
                        3'b100:
                            opCode_Out = `INSTR_OP_XOR;
                        3'b101:
                            opCode_Out = `INSTR_OP_LOGIC_SHIFT_R;
                        3'b110:
                            opCode_Out = `INSTR_OP_OR;
                        3'b111:
                            opCode_Out = `INSTR_OP_AND;
                        default:
                            opcode_exception = `EXCEP_ILLEGAL_INSTR;
                    endcase
                else if (funct7 == 7'b0100000)
                    case (funct3)
                        3'b000:
                            opCode_Out = `INSTR_OP_SUB;
                        3'b101:
                            opCode_Out = `INSTR_OP_ARITH_SHIFT_R;
                        default:
                            opcode_exception = `EXCEP_ILLEGAL_INSTR;
                    endcase
                else
                    opcode_exception = `EXCEP_ILLEGAL_INSTR;

            `INSTR_TYPE_I:
                if (opcode == 7'b0010011) // R-R Operation
                    case (funct3)
                        3'b000:
                            opCode_Out = `INSTR_OP_ADD;
                        3'b001:
                            if (~|funct7)
                                opCode_Out = `INSTR_OP_LOGIC_SHIFT_L;
                            else
                            begin
                                opCode_Out = `INSTR_OP_NONE;
                                opcode_exception = `EXCEP_ILLEGAL_INSTR;
                            end
                        3'b010:
                            opCode_Out = `INSTR_OP_CMP_LESS;
                        3'b011:
                            opCode_Out = `INSTR_OP_CMP_LESS_UNSIGN;
                        3'b100:
                            opCode_Out = `INSTR_OP_XOR;
                        3'b101:
                            case (funct7)
                                7'b0000000:
                                    opCode_Out = `INSTR_OP_LOGIC_SHIFT_R;
                                7'b0100000:
                                    opCode_Out = `INSTR_OP_ARITH_SHIFT_R;
                                default: begin
                                    opCode_Out = `INSTR_OP_NONE;
                                    opcode_exception = `EXCEP_ILLEGAL_INSTR;
                                end
                            endcase
                        3'b110:
                            opCode_Out = `INSTR_OP_OR;
                        3'b111:
                            opCode_Out = `INSTR_OP_AND;
                        default:
                            opcode_exception = `EXCEP_ILLEGAL_INSTR;
                    endcase
                else if (opcode == 7'b0000011) // LOAD
                    case (funct3)
                        3'b000:
                            opCode_Out = `INSTR_OP_LOAD_BYTE;
                        3'b001:
                            opCode_Out = `INSTR_OP_LOAD_HALF;
                        3'b010:
                            opCode_Out = `INSTR_OP_LOAD_WORD;
                        3'b100:
                            opCode_Out = `INSTR_OP_LOAD_BYTE_UNSIGN;
                        3'b101:
                            opCode_Out = `INSTR_OP_LOAD_HALF_UNSIGN;
                        default:
                            opcode_exception = `EXCEP_ILLEGAL_INSTR;
                    endcase
                else // JALR
                    if (~|funct3)
                        opCode_Out = `INSTR_OP_JMP_REG_LINK;
                    else
                        opcode_exception = `EXCEP_ILLEGAL_INSTR;

            `INSTR_TYPE_S:
                case (funct3)
                    3'b000:
                        opCode_Out = `INSTR_OP_STORE_BYTE;
                    3'b001:
                        opCode_Out = `INSTR_OP_STORE_HALF;
                    3'b010:
                        opCode_Out = `INSTR_OP_STORE_WORD;
                    default:
                        opcode_exception = `EXCEP_ILLEGAL_INSTR;
                endcase

            `INSTR_TYPE_B:
                case (funct3)
                    3'b000:
                        opCode_Out = `INSTR_OP_BR_EQ;
                    3'b001:
                        opCode_Out = `INSTR_OP_BR_N_EQ;
                    3'b100:
                        opCode_Out = `INSTR_OP_BR_LESS;
                    3'b101:
                        opCode_Out = `INSTR_OP_BR_GREATER;
                    3'b110:
                        opCode_Out = `INSTR_OP_BR_LESS_UNSIGN;
                    3'b111:
                        opCode_Out = `INSTR_OP_BR_GREATER_UNSIGN;
                    default:
                        opcode_exception = `EXCEP_ILLEGAL_INSTR;
                endcase

            `INSTR_TYPE_U:
                if (instr_In[5])
                    opCode_Out = `INSTR_OP_LUI;
                else
                    opCode_Out = `INSTR_OP_AUIPC;

            `INSTR_TYPE_J:
                opCode_Out = `INSTR_OP_JMP_LINK;

            `INSTR_TYPE_NONE:
                case (opcode)
                    7'b1110011:
                        if (~|instr_In[31 : 7])
                            opCode_Out = `INSTR_OP_ECALL;
                        else if (~|instr_In[31 : 21] && instr_In[20] && ~|instr_In[19 : 7])
                            opCode_Out = `INSTR_OP_EBREAK;
                        else
                            opcode_exception = `EXCEP_ILLEGAL_INSTR;
                    7'b0001111:
                        if (~|funct3)
                            opCode_Out = `INSTR_OP_FENCE;
                        else
                            opcode_exception = `EXCEP_ILLEGAL_INSTR;
                    default:
                        opcode_exception = `EXCEP_ILLEGAL_INSTR;
                endcase

            default:
                opcode_exception = `EXCEP_ILLEGAL_INSTR;
        endcase
    end

    /* Merge and generate module exception output */
    assign exception_Out = (opcode_exception == `EXCEP_OK) ? type_exception : opcode_exception;
endmodule

module ImmediateGen
    (input wire [31 : 0] instr_In,
     input wire [2 : 0] instrType_In,

     output reg [31 : 0] imm_Out);

    always @(*)
    begin
        case (instrType_In)
            `INSTR_TYPE_I:
                imm_Out = {{21{instr_In[31]}}, instr_In[30 : 25], instr_In[24 : 21], instr_In[20]};
            `INSTR_TYPE_S:
                imm_Out = {{21{instr_In[31]}}, instr_In[30 : 25], instr_In[11 : 8], instr_In[7]};
            `INSTR_TYPE_B:
                imm_Out = {{20{instr_In[31]}}, instr_In[7], instr_In[30 : 25], instr_In[11 : 8], 1'b0};
            `INSTR_TYPE_U:
                imm_Out = {instr_In[31], instr_In[30 : 20], instr_In[19 : 12], 12'b0};
            `INSTR_TYPE_J:
                imm_Out = {{12{instr_In[31]}}, instr_In[19 : 12], instr_In[20],
                           instr_In[30 : 25],  instr_In[24 : 21], 1'b0};
            default:
                imm_Out = 0;
        endcase
    end
endmodule