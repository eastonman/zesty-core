//
// interrupts and exceptions while in supervisor
// mode come here.
//
// push all registers, call kerneltrap(), restore, return.
//
.globl asm_kernel_trap
.globl asm_kernel_irq_vec
.align 4
asm_kernel_irq_vec:

    // Store all register values on the stack
    addi sp, sp, -8 * 32
    sd x1, 0(sp)
    sd x2, 1 * 8(sp)
    sd x3, 2 * 8(sp)
    sd x4, 3 * 8(sp)
    sd x5, 4 * 8(sp)
    sd x6, 5 * 8(sp)
    sd x7, 6 * 8(sp)
    sd x10, 9 * 8(sp)
    sd x11, 10 * 8(sp)
    sd x12, 11 * 8(sp)
    sd x13, 12 * 8(sp)
    sd x14, 13 * 8(sp)
    sd x15, 14 * 8(sp)
    sd x16, 15 * 8(sp)
    sd x17, 16 * 8(sp)
    sd x28, 27 * 8(sp)
    sd x29, 28 * 8(sp)
    sd x30, 29 * 8(sp)
    sd x31, 30 * 8(sp)

    // call higher level handler
    call zig_handler

    // Load all register values from the stack and return
    ld x1, 0(sp)
    ld x2, 1 * 8(sp)
    ld x3, 2 * 8(sp)
    // ld x4, 3 * 8(sp)
    ld x5, 4 * 8(sp)
    ld x6, 5 * 8(sp)
    ld x7, 6 * 8(sp)
    ld x10, 9 * 8(sp)
    ld x11, 10 * 8(sp)
    ld x12, 11 * 8(sp)
    ld x13, 12 * 8(sp)
    ld x14, 13 * 8(sp)
    ld x15, 14 * 8(sp)
    ld x16, 15 * 8(sp)
    ld x17, 16 * 8(sp)
    ld x28, 27 * 8(sp)
    ld x29, 28 * 8(sp)
    ld x30, 29 * 8(sp)
    ld x31, 30 * 8(sp)
    addi sp, sp, 8 * 32

    // return to whatever we were doing in the kernel.
    sret
.globl register_asm_handler
.align 4
register_asm_handler:
    la t0, asm_kernel_irq_vec
    csrw stvec, t0
    ret

    // Enable machine external interrupts
    li t1, 0x800 // t1 = 0x800
    csrw mie, t1 

    // Enable machine mode interrupts
    li t1, 0x8
    csrw mstatus, t1

    ret
     
    
