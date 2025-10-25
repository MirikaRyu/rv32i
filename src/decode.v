/* Decode instructions from IR */

`include "constants.v"

// Pure Combinational Logic
module InstructionDecode
    (input wire [31 : 0] instr_In,

     output reg [4 : 0] rs1Addr_Out,
     input wire [31 : 0] rs1_In,
     output reg rs1Enable_Out,

     output reg [4 : 0] rs2Addr_Out,
     input wire [31 : 0] rs2_In,
     output reg rs2Enable_Out,

     output reg [5 : 0] opCode_Out,
     output reg [4 : 0] rdAddr_Out,
     output reg [31 : 0] resource1_Out,
     output reg [31 : 0] resource2_Out,
     output reg [31 : 0] offset_Out,

     output wire [`EXCEPTION_LEN - 1 : 0] exception_Out);

    // Get the instruction type
    reg [2 : 0] instr_type;
    reg [`EXCEPTION_LEN - 1 : 0] type_exception;
    always @(*)
    begin
        type_exception = `EXCEP_OK;

        casez (instr_In[6 : 0])
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

    // Generate immediate number and fill input data
    wire [31 : 0] imm;
    ImmediateGen imm_gen(.instr_In(instr_In),
                         .instrType_In(instr_type),
                         .imm_Out(imm));
    always @(*)
    begin
        case (instr_type)
            `INSTR_TYPE_R: begin
                rdAddr_Out = instr_In[11 : 7];

                rs1Enable_Out = 1;
                rs2Enable_Out = 1;
                rs1Addr_Out = instr_In[19 : 15];
                rs2Addr_Out = instr_In[24 : 20];
                resource1_Out = rs1_In;
                resource2_Out = rs2_In;

                offset_Out = 0;
            end

            `INSTR_TYPE_I: begin
                rdAddr_Out = instr_In[11 : 7];

                rs1Enable_Out = 1;
                rs1Addr_Out = instr_In[19 : 15];
                resource1_Out = rs1_In;

                rs2Enable_Out = 0;
                rs2Addr_Out = 0;
                resource2_Out = imm;

                offset_Out = 0;
            end

            `INSTR_TYPE_S, `INSTR_TYPE_B: begin
                rdAddr_Out = 0;

                rs1Enable_Out = 1;
                rs2Enable_Out = 1;
                rs1Addr_Out = instr_In[19 : 15];
                rs2Addr_Out = instr_In[24 : 20];
                resource1_Out = rs1_In;
                resource2_Out = rs2_In;

                offset_Out = imm;
            end

            `INSTR_TYPE_U: begin
                rdAddr_Out = instr_In[11 : 7];

                rs1Enable_Out = 0;
                rs1Addr_Out = 0;
                resource1_Out = imm;

                rs2Enable_Out = 0;
                rs2Addr_Out = 0;
                resource2_Out = 0;

                offset_Out = 0;
            end

            `INSTR_TYPE_J: begin
                rdAddr_Out = instr_In[11 : 7];

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

    // Get the opcode
    reg [`EXCEPTION_LEN - 1 : 0] opcode_exception;
    always @(*)
    begin
        opCode_Out = `INSTR_OP_NONE;
        opcode_exception = `EXCEP_OK;

        case (instr_type)
            `INSTR_TYPE_R:
                if (~|instr_In[31 : 25])     // funct7
                    case (instr_In[14 : 12]) // funct3
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
                else if (instr_In[31 : 25] == 7'b0100000)
                    case (instr_In[14 : 12])
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
                if (instr_In[6 : 0] == 7'b0010011) // OP
                    case (instr_In[14 : 12])       // funct3
                        3'b000:
                            opCode_Out = `INSTR_OP_ADD;
                        3'b001:
                            if (~|instr_In[31 : 25]) // imm
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
                            case (instr_In[31 : 25]) // imm
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
                else if (instr_In[6 : 0] == 7'b0000011) // LOAD
                    case (instr_In[14 : 12])            // funct3 / width
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
                else                         // JALR
                    if (~|instr_In[14 : 12]) // funct3
                        opCode_Out = `INSTR_OP_JMP_REG_LINK;
                    else
                        opcode_exception = `EXCEP_ILLEGAL_INSTR;

            `INSTR_TYPE_S:
                case (instr_In[14 : 12]) // funct3
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
                case (instr_In[14 : 12]) // funct3
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
                case (instr_In[5])
                    1'b0:
                        opCode_Out = `INSTR_OP_AUIPC;
                    1'b1:
                        opCode_Out = `INSTR_OP_LUI;
                    default:
                        opcode_exception = `EXCEP_ILLEGAL_INSTR;
                endcase

            `INSTR_TYPE_J:
                opCode_Out = `INSTR_OP_JMP_LINK;

            `INSTR_TYPE_NONE:
                case (instr_In[6 : 0])
                    7'b1110011:
                        if (~|instr_In[31 : 7])
                            opCode_Out = `INSTR_OP_ECALL;
                        else if (~|instr_In[31 : 21] && instr_In[20] && ~|instr_In[19 : 7])
                            opCode_Out = `INSTR_OP_EBREAK;
                        else
                            opcode_exception = `EXCEP_ILLEGAL_INSTR;
                    7'b0001111:
                        if (instr_In[14 : 12] == 3'b0)
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

    // Generate exception_out signal
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