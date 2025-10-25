/* RV32I Processor Minimal Comprehensive Test */

# Memory Address Definitions
.equ RAM_BASE, 0x40000000  # RAM Base Address (1 GiB)
.equ IO_ADDR,  0x60000000   # IO Region Address (1.5 GiB)
.equ MAGIC_NUMBER_PASS, 0xF00DCAFE
.equ MAGIC_NUMBER_FAIL, 0xDEADBEEF

.global main
main:
    # ----------------------------------------------------
    # 0. Setup: x1, x2: ALU, x5: Memory, x30: Final Result
    # ----------------------------------------------------
    addi x0, x0, 0              # Verify x0 is 0
    li x1, 0x0000000F           # Source A: 15
    li x2, 0xFFFFFFF1           # Source B: -15 (Signed) / Large (Unsigned)
    li x5, RAM_BASE             # Memory Base Address

    # ----------------------------------------------------
    # 1. U-type Instructions (LUI, AUIPC)
    # ----------------------------------------------------
    # LUI: Test LUI and check the result by ANDI
    lui x10, 0x1A000            # x10 = 0x1A000000

    # AUIPC: Use for PC-relative test (value is only used to affect x30 later)
    auipc x11, 0x00100      # x11 = PC + 0x100000. Not checked immediately.

    # ----------------------------------------------------
    # 2. R-type ALU Instructions (Accumulation in x30)
    # ----------------------------------------------------
    # ADD, SUB, OR
    add x30, x30, x1        # x30 = 1 + 15 = 16 (0x10)
    sub x30, x30, x1        # x30 = 16 - 15 = 1
    or x30, x30, x2         # x30 = 1 | 0xFFFFFFF1 = 0xFFFFFFF1
    
    # SLL, SRL (Shift by x1=15)
    sll x30, x30, x1        # x30 << 15. The low 15 bits are 0x7FFF
    srl x30, x30, x1        # x30 >> 15 (Logical Right Shift)
                            # x30 is now 0x0001FFFF
    
    # SLTU, SLT (Unsigned/Signed Compare)
    sltu x12, x2, x1        # x12 = 0 (Unsigned: -15 > 15)
    slt x13, x2, x1         # x13 = 1 (Signed: -15 < 15)
    
    # XOR, AND, SRA (Accumulate results into x30)
    xor x30, x30, x12       # x30 = x30 ^ 0 = 0x0001FFFF
    and x30, x30, x13       # x30 = 0x0001FFFF & 1 = 1
    sra x30, x30, x1        # x30 = 1 >> 15 (Arithmetic Right Shift) = 0
    
    addi x30, x30, 0x2      # x30 is now 2 (Ready for next block)
    
    # ----------------------------------------------------
    # 3. I-type ALU Instructions
    # ----------------------------------------------------
    # ADDI, SLLI, SRLI, SRAI
    addi x30, x30, 10       # x30 = 12
    slli x30, x30, 4        # x30 = 12 << 4 = 0xC0 (192)
    srli x30, x30, 2        # x30 = 0xC0 >> 2 = 0x30 (48)
    srai x30, x30, 3        # x30 = 48 >> 3 = 6
    
    # SLTI, SLTIU, XORI, ORI, ANDI
    slti x14, x2, 0         # x14 = 1 (Signed: -15 < 0)
    sltiu x15, x2, 10       # x15 = 0 (Unsigned: Large > 10)
    xor x30, x30, x14       # x30 = 6 ^ 1 = 7
    li x14, 0x1007          # x14 = 0x1007
    or x30, x30, x14        # x30 = 7 | 0x1007 = 0x1007
    li x14, 0xFFFF          # x14 = 0xFFFF
    and x30, x30, x14       # x30 = 0x1007
    
    # ----------------------------------------------------
    # 4. S/L-type Instructions (Memory Access)
    # ----------------------------------------------------
    li x16, 0xAABBCCDD      # Write Data
    
    # Store: SW, SH, SB
    sw x16, 0(x5)           # Store 0xAABBCCDD at RAM_BASE + 0
    sh x1, 4(x5)            # Store 0x000F at RAM_BASE + 4
    sb x2, 6(x5)            # Store 0xF1 (-15) at RAM_BASE + 6
    
    # Load: LW, LH, LB, LHU, LBU (Accumulate into x30)
    lw x17, 0(x5)           # x17 = 0xAABBCCDD
    xor x30, x30, x17       # x30 ^= 0xAABBCCDD
    
    lbu x18, 6(x5)          # x18 = 0x000000F1 (Zero-extended byte)
    or x30, x30, x18        # x30 |= 0x000000F1
    
    lh x19, 4(x5)           # x19 = 0x0000000F (Sign-extended half-word)
    and x30, x30, x19       # x30 &= 0xF
    
    lb x20, 6(x5)           # x20 = 0xFFFFFFF1 (Sign-extended byte)
    sltu x30, x30, x20      # x30 = 1 (0xF < 0xFFFFFFF1 unsigned)
    
    lhu x21, 4(x5)          # x21 = 0x0000000F (Zero-extended half-word)
    add x30, x30, x21       # x30 = 1 + 0xF = 16 (0x10)
    
    # ----------------------------------------------------
    # 5. J-type and I-type (JAL, JALR)
    # ----------------------------------------------------
    # JAL: Store return address to x1 and jump to jump_target
    jal x0, jump_target_1 
    
    addi x30, x30, 0x1       # Should NOT execute (failure check)
    
jump_target_1:
    addi x30, x30, 0x100     # x30 = 0x10 + 0x100 = 0x110
    
    jal x0, jump_return      # JALR: Jump to jump_return

    addi x30, x30, 0x1       # Should NOT execute (failure check)
    
jump_return:
    li x14, 0x1000
    add x30, x30, x14     # x30 = 0x110 + 0x1000 = 0x1110 (Jump test passed)

    # ----------------------------------------------------
    # 6. B-type Instructions (Guaranteed Branching)
    # ----------------------------------------------------
    li x1, 1              # x1 = 1
    li x2, 2              # x2 = 2
    li x3, 1              # x3 = 1
    
    # BEQ (Equal) - Guaranteed branch
    beq x1, x3, branch_pass_1
    addi x30, x30, 0x1       # Fail: Should not execute
branch_pass_1:

    # BNE (Not Equal) - Guaranteed branch
    bne x1, x2, branch_pass_2
    addi x30, x30, 0x1       # Fail: Should not execute
branch_pass_2:

    # BLT (Less Than Signed) - Guaranteed branch
    blt x1, x2, branch_pass_3
    addi x30, x30, 0x1       # Fail: Should not execute
branch_pass_3:

    # BGE (Greater Than or Equal Signed) - Guaranteed branch
    bge x2, x1, branch_pass_4
    addi x30, x30, 0x1       # Fail: Should not execute
branch_pass_4:

    # BLTU (Less Than Unsigned) - Guaranteed branch
    bltu x1, x2, branch_pass_5
    addi x30, x30, 0x1       # Fail: Should not execute
branch_pass_5:

    # BGEU (Greater Than or Equal Unsigned) - Guaranteed branch
    bgeu x2, x1, branch_final
    addi x30, x30, 0x1       # Fail: Should not execute
branch_final:

    # ----------------------------------------------------
    # 7. FENCE Instructions
    # ----------------------------------------------------
    fence rw, rw
    fence r, r

    # ----------------------------------------------------
    # 8. Final Verification
    # ----------------------------------------------------
    # Expected x30 value based on all accumulation: 0x1110 (from Jump test)
    li x1, 0x1110            # Expected final value
    # If x30 does not match the expected value, jump to fail
    bne x30, x1, write_fail
    
    # Test passed, load PASS magic number
    li x30, MAGIC_NUMBER_PASS
    jal x0, final_store

write_fail:
    # Test failed, load FAIL magic number
    li x30, MAGIC_NUMBER_FAIL
    
final_store:
    # Write final result to IO region
    li x5, IO_ADDR
    sw x30, 0(x5)

    # ----------------------------------------------------
    # 9. ECALL And EBREAK
    # ----------------------------------------------------    
    ebreak                   # Processor will stall on this command
    ecall                    # This command is only for decode and fetch test