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
    addi sp, sp, -8 * 34
    sd x1, 0(sp)
    sd x2, 1 * 8(sp) // sp - 8 * 34 
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

    // CSRs
    csrr s1, sstatus
    csrr s2, sepc
    sd s1, 32 * 8(sp)
    sd s2, 33 * 8(sp)

    // IRQ args
    mv a0, sp
    csrr a1, scause
    csrr a2, stval

    // call higher level handler
    jal zig_handler

    // Restore CSRs
    ld s1, 32 * 8(sp)
    ld s2, 33 * 8(sp)
    csrw sstatus, s1
    csrw sepc, s2

    // Load all register values from the stack and return
    ld x1, 0(sp)
    ld x3, 2 * 8(sp)
    // ld x4, 3 * 8(sp) // do not load tp
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
    ld sp, 1 * 8(sp) // Load sp at last, which is x2
    addi sp, sp, 8 * 34

    // return to whatever we were doing in the kernel.
    sret

.globl register_asm_handler
.align 4
register_asm_handler:
    la t0, asm_kernel_irq_vec
    csrw stvec, t0

    // Enable S mode external interrupts
    # li t1, 0x800 
    # csrw sie, t1 

    # li t1, 0x2 // Enable Clock Interrupts
    # csrw sstatus, t1

    ret
     
    
