`ifndef CONSTANTS_V
`define CONSTANTS_V

/* Startup Address */
`define BOOT_ADDR 32'h0

/* Instructions */
`define INSTR_OP_ADD 6'h0
`define INSTR_OP_SUB 6'h1
`define INSTR_OP_AND 6'h2
`define INSTR_OP_OR 6'h3
`define INSTR_OP_XOR 6'h4
`define INSTR_OP_LOGIC_SHIFT_L 6'h5
`define INSTR_OP_LOGIC_SHIFT_R 6'h6
`define INSTR_OP_ARITH_SHIFT_R 6'h7
`define INSTR_OP_CMP_LESS 6'h8
`define INSTR_OP_CMP_LESS_UNSIGN 6'h9
`define INSTR_OP_LOAD_WORD 6'ha
`define INSTR_OP_LOAD_HALF 6'hb
`define INSTR_OP_LOAD_HALF_UNSIGN 6'hc
`define INSTR_OP_LOAD_BYTE 6'hd
`define INSTR_OP_LOAD_BYTE_UNSIGN 6'he
`define INSTR_OP_STORE_WORD 6'hf
`define INSTR_OP_STORE_HALF 6'h10
`define INSTR_OP_STORE_BYTE 6'h11
`define INSTR_OP_BR_EQ 6'h12
`define INSTR_OP_BR_N_EQ 6'h13
`define INSTR_OP_BR_LESS 6'h14
`define INSTR_OP_BR_GREATER 6'h15
`define INSTR_OP_BR_LESS_UNSIGN 6'h16
`define INSTR_OP_BR_GREATER_UNSIGN 6'h17
`define INSTR_OP_JMP_LINK 6'h18
`define INSTR_OP_JMP_REG_LINK 6'h19
`define INSTR_OP_LUI 6'h1a
`define INSTR_OP_AUIPC 6'h1b
`define INSTR_OP_ECALL 6'h1c
`define INSTR_OP_EBREAK 6'h1d
`define INSTR_OP_FENCE 6'h1f
`define INSTR_OP_NONE 6'h3f

/* Exceptions */
`define EXCEPTION_LEN 6

`define EXCEP_OK 6'h0
`define EXCEP_ILLEGAL_INSTR 6'h1
`define EXCEP_INVALID_MEM_READ 6'h2
`define EXCEP_INVALID_MEM_WRITE 6'h3
`define EXCEP_MISALIGNED_INSTR 6'h4
`define EXCEP_ENV_CALL 6'h5
`define EXCEP_ENV_BREAK 6'h6

/* Memory Access */
`define MEM_WIDTH_NONE 2'h0
`define MEM_WIDTH_WORD 2'h1
`define MEM_WIDTH_HALF 2'h2
`define MEM_WIDTH_BYTE 2'h3

`endif