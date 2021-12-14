/// Risc-V architecture related code

// Builtin is available
const builtin = @import("builtin");

// Page size 4k
pub const PAGE_SIZE: usize = 4096;

// HZ value
pub const HZ: usize = 100;

// MAGIC number indicates the cpu freq
pub const FREQ: usize = 1e7;

/// Memory layout
///
/// qemu -machine virt is set up like this,
/// based on qemu's hw/riscv/virt.c:
///
/// 00001000 -- boot ROM, provided by qemu
/// 02000000 -- CLINT
/// 0C000000 -- PLIC
/// 10000000 -- uart0
/// 10001000 -- virtio disk
/// 80000000 -- boot ROM jumps here in machine mode
///             -kernel loads the kernel here
/// unused RAM after 80000000.
///
/// the kernel uses physical memory thus:
/// 80200000 -- entry.S, then kernel text and data
/// end -- start of kernel page allocation area
/// PHYSTOP -- end RAM used by the kernel
const Memory_layout = struct {
    UART0: usize = 0x1000_0000,
};
pub const memory_layout = Memory_layout{};

pub inline fn __sync_synchronize() void {
    asm volatile ("fence");
}

// Atomic test&set
pub inline fn __sync_lock_test_and_set(a: *usize, b: usize) usize {
    return @atomicRmw(usize, a, .Xchg, b, .Acquire);
}

// Lock release, set *a to 0
pub inline fn __sync_lock_release(a: *usize) void {
    asm volatile ("amoswap.w zero, zero, (%[arg])"
        :
        : [arg] "r" (a)
    );
}

pub fn hart_id() usize {
    return asm volatile ("mv %[result], tp"
        : [result] "=r" (-> usize)
    );
}

pub fn get_time() usize {
    return asm volatile ("rdtime %[result]"
        : [result] "=r" (-> usize)
    );
}

pub fn get_cycle() usize {
    return asm volatile ("rdcycle %[result]"
        : [result] "=r" (-> usize)
    );
}
