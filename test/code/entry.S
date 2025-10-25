/* Entry point of all the programs */

.text
.global entry

.section .entry
entry:
    li sp, 0x60000000 # End of 512MiB
    call main
    ebreak