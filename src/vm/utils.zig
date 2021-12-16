//! Utilities for memory management

const arch = @import("../arch/riscv64/riscv.zig");

pub inline fn PAGE_ROUND_UP(ptr: usize) usize {
    return (ptr / arch.PAGE_SIZE + 1) * PAGE_SIZE;
}

pub inline fn PAGE_ROUND_DOWN(ptr: usize) usize {
    return (ptr / arch.PAGE_SIZE) * PAGE_SIZE;
}
