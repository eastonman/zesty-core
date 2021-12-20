//! Interrupt related function
const reg = @import("../arch/riscv64/reg.zig");
const std = @import("std");

// TODO: move entry outside of subdirectory

const SSTATUS_SIE = 1;

/// Enable Interrupt
pub fn enable() void {
    reg.set_sstatus(1 << SSTATUS_SIE);
}

// disable interrupt
pub fn disable() void {
    reg.clr_sstatus(1 << SSTATUS_SIE);
}
