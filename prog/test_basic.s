# prog/test_basic.s
.section .text
.global _start
_start:
    addi x1, x0, 10
    addi x2, x0, 5
    add  x3, x1, x2
    sw   x3, 0(x0)
    lw   x4, 0(x0)
    addi x4, x4, 1
    beq  x1, x2, fail
    addi x6, x0, 99
    j    done
fail:
    addi x6, x0, 1
done:
    nop