# prog/test_mext.s
# Tests RV32M multiply and divide instructions

.section .text
.global _start
_start:
    # Test 1: MUL -- 6 * 7 = 42
    addi x1, x0, 6
    addi x2, x0, 7
    mul  x3, x1, x2       # x3 = 42

    # Test 2: MUL negative -- -3 * 4 = -12
    addi x4, x0, -3
    addi x5, x0, 4
    mul  x6, x4, x5       # x6 = -12

    # Test 3: DIV -- 42 / 6 = 7
    addi x7, x0, 42
    addi x8, x0, 6
    div  x9, x7, x8       # x9 = 7

    # Test 4: REM -- 43 % 6 = 1
    addi x10, x0, 43
    addi x11, x0, 6
    rem  x12, x10, x11    # x12 = 1

    # Test 5: MULH -- upper 32 bits of large multiply
    addi x13, x0, -1      # x13 = 0xFFFFFFFF
    addi x14, x0, -1      # x14 = 0xFFFFFFFF
    mulh x15, x13, x14    # x15 = 0 (upper 32 of 1*1 signed)

    # PASS marker
    addi x28, x0, 99
    j done
fail:
    addi x28, x0, 1
done:
    nop