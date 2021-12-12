/// Risc-V architecture related code

// Page size 4k
pub const PAGE_SIZE: usize = 4096;

pub inline fn __sync_synchronize() void {
    asm volatile ("fence");
}

// Atomic test&set
pub inline fn __sync_lock_test_and_set(a: *u32, b: u32) u32 {
    asm volatile ("amoswap.w.aq %[arg1], %[arg2], (%[arg3])"
        : [ret] "=r" (-> usize)
        : [arg1] "r" (b),
          [arg2] "r" (b),
          [arg3] "r" (a)
    );
    return b;
}

// Lock release, set *a to 0
pub inline fn __sync_lock_release(a: *u32) void {
    asm volatile ("amoswap.w zero,zero, (%[arg])"
        :
        : [arg] "r" (a)
    );
}

pub fn hart_id() usize {
    return asm volatile ("mv %[result], tp"
        : [result] "=r" (-> usize)
    );
}
