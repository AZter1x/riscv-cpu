# prog/crt0.s
    .section .text.start
    .global _start

_start:
    # Stack pointer set by linker script to top of DMEM
    lui  sp, %hi(_stack_top)
    addi sp, sp, %lo(_stack_top)

    # Zero BSS section
    lui  t0, %hi(_bss_start)
    addi t0, t0, %lo(_bss_start)
    lui  t1, %hi(_bss_end)
    addi t1, t1, %lo(_bss_end)

bss_loop:
    beq  t0, t1, bss_done
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    bss_loop

bss_done:
    call main

hang:
    j hang
    