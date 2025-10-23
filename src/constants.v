/* Define the constants used in code */

`ifndef CONSTANTS_V
`define CONSTANTS_V

// Startup address
parameter BOOT_ADDR = 32'h0;

// Instructions
parameter INSTR_TYPE_R = 3'h0;
parameter INSTR_TYPE_I = 3'h1;
parameter INSTR_TYPE_S = 3'h2;
parameter INSTR_TYPE_B = 3'h3;
parameter INSTR_TYPE_U = 3'h4;
parameter INSTR_TYPE_J = 3'h5;
parameter INSTR_TYPE_NONE = 3'h7;

parameter INSTR_OP_ADD = 6'h0;
parameter INSTR_OP_SUB = 6'h1;
parameter INSTR_OP_AND = 6'h2;
parameter INSTR_OP_OR = 6'h3;
parameter INSTR_OP_XOR = 6'h4;
parameter INSTR_OP_LOGIC_SHIFT_L = 6'h5;
parameter INSTR_OP_LOGIC_SHIFT_R = 6'h6;
parameter INSTR_OP_ARITH_SHIFT_R = 6'h7;
parameter INSTR_OP_CMP_LESS = 6'h8;
parameter INSTR_OP_CMP_LESS_UNSIGN = 6'h9;
parameter INSTR_OP_LOAD_WORD = 6'ha;
parameter INSTR_OP_LOAD_HALF = 6'hb;
parameter INSTR_OP_LOAD_HALF_UNSIGN = 6'hc;
parameter INSTR_OP_LOAD_BYTE = 6'hd;
parameter INSTR_OP_LOAD_BYTE_UNSIGN = 6'he;
parameter INSTR_OP_STORE_WORD = 6'hf;
parameter INSTR_OP_STORE_HALF = 6'h10;
parameter INSTR_OP_STORE_BYTE = 6'h11;
parameter INSTR_OP_BR_EQ = 6'h12;
parameter INSTR_OP_BR_N_EQ = 6'h13;
parameter INSTR_OP_BR_LESS = 6'h14;
parameter INSTR_OP_BR_GREATER = 6'h15;
parameter INSTR_OP_BR_LESS_UNSIGN = 6'h16;
parameter INSTR_OP_BR_GREATER_UNSIGN = 6'h17;
parameter INSTR_OP_JMP_LINK = 6'h18;
parameter INSTR_OP_JMP_REG_LINK = 6'h19;
parameter INSTR_OP_LUI = 6'h1a;
parameter INSTR_OP_AUIPC = 6'h1b;
parameter INSTR_OP_ECALL = 6'h1c;
parameter INSTR_OP_EBREAK = 6'h1d;
parameter INSTR_OP_FENCE = 6'h1f;
parameter INSTR_OP_NONE = 6'h3f;

parameter INSTR_ALU_ADD = 4'h0;
parameter INSTR_ALU_SUB = 4'h1;
parameter INSTR_ALU_AND = 4'h2;
parameter INSTR_ALU_OR = 4'h3;
parameter INSTR_ALU_XOR = 4'h4;
parameter INSTR_ALU_LOG_SFT_L = 4'h5;
parameter INSTR_ALU_LOG_SHF_R = 4'h6;
parameter INSTR_ALU_ARI_SHF_R = 4'h7;
parameter INSTR_ALU_CMP_LESS = 4'h8;
parameter INSTR_ALU_CMP_LESS_UNSIGN = 4'h9;
parameter INSTR_ALU_PC_ADD = 4'ha;
parameter INSTR_ALU_NONE = 4'hf;

// Exceptions
parameter EXCEPTION_LEN = 6;

parameter EXCEP_OK = 6'h0;
parameter EXCEP_ILLEGAL_INSTR = 6'h1;
parameter EXCEP_INVALID_MEM_READ = 6'h2;
parameter EXCEP_INVALID_MEM_WRITE = 6'h3;
parameter EXCEP_MISALIGNED_INSTR = 6'h4;
parameter EXCEP_ENV_CALL = 6'h5;
parameter EXCEP_ENV_BREAK = 6'h6;

// Memory access
parameter MEM_WIDTH_NONE = 2'h0;
parameter MEM_WIDTH_WORD = 2'h1;
parameter MEM_WIDTH_HALF = 2'h2;
parameter MEM_WIDTH_BYTE = 2'h3;

`endif