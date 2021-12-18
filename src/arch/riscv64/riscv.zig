/// Risc-V architecture related code

// Builtin is available
const builtin = @import("builtin");

/// Page size 4K
pub const PAGE_SIZE: usize = 4096;

/// VM releated defines
/// bits offset within a page
pub const PAGE_SHIFT: usize = 12;

/// Page table entry masks
pub const PTE_VALID: usize = (1 << 0); // valid
pub const PTE_READ: usize = (1 << 1); // read permission
pub const PTE_WRITE: usize = (1 << 2); // write permission
pub const PTE_EXEC: usize = (1 << 3); // execute permission
pub const PTE_USER: usize = (1 << 4); // belongs to U mode

pub inline fn PAGE_INDEX_SHIFT(level: usize) u6 {
    return @intCast(u6, PAGE_SHIFT + 9 * level);
}

pub const PAGE_INDEX_MASK: usize = 0x1FF; // 9 bits
pub const PTE_FLAG_MASK: usize = 0x3FF; // 10 bits

pub inline fn PTE_FLAGS(pte: usize) usize {
    return pte & PTE_FLAG_MASK;
}

pub inline fn PAGE_INDEX(level: usize, virtual_address: usize) usize {
    return (virtual_address >> PAGE_INDEX_SHIFT(level)) & PAGE_INDEX_MASK;
}

pub inline fn PTE_TO_PA(pte: usize) usize {
    return (pte >> 10) << 12;
}

pub inline fn PA_TO_PTE(pa: usize) usize {
    return (pa >> 12) << 10;
}

// SATP related
const SATP_SV39: usize = (8 << 60);
pub inline fn MAKE_SATP(pagetable: usize) usize {
    return (SATP_SV39 | (pagetable >> 12));
}

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
    PLIC: usize = 0x0C00_0000,
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

pub inline fn flush_tlb() void {
    asm volatile ("sfence.vma zero, zero");
}
