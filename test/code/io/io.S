/* Test the functionality of MMIO */
.text

.global main
main:
    li s0, 0xc0000000           # Load IO base address
    li t1, 0x000000ff           # Data to write, only low 8-bits valid

    li t0, 0x6
    io_loop:                    # for (i = 6; i != 0; --i)
        sw t1, 0(s0)
        addi t1, t1, -1         # Sub 1 to IO Data

        addi t0, t0, -1
        bne t0, zero, io_loop

    ret