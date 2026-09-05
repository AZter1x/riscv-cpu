# prog/test_hazard.s
.section .text
.global _start
_start:
    # Test 1: back-to-back RAW hazard (forwarding)
    addi x1, x0, 3
    addi x2, x1, 1
    addi x3, x2, 1

    # Test 2: load-use hazard
    sw   x3, 0(x0)
    lw   x4, 0(x0)
    addi x4, x4, 10

    # Test 3: BNE branch
    addi x5, x0, 1
    addi x6, x0, 2
    bne  x5, x6, bne_pass
    addi x7, x0, 0xFF
bne_pass:
    addi x7, x0, 1

    # Test 4: BLT branch
    addi x8, x0, 5
    addi x9, x0, 10
    blt  x8, x9, blt_pass
    addi x10, x0, 0xFF
blt_pass:
    addi x10, x0, 2

    # Test 5: AUIPC
    auipc x11, 0

    # PASS marker
    addi x28, x0, 99
    j done
fail:
    addi x28, x0, 1
done:
    nop