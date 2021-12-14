//! Interrupt related function
const reg = @import("../arch/riscv64/reg.zig");

const SSTATUS_SIE = 1;

/// Enable Interrupt
pub fn enable() void {
    var status = reg.r_sstatus();
    status = status | (1 << SSTATUS_SIE);
    _ = reg.w_sstatus(status);
}

// disable interrupt
pub fn disable() void {
    var status = reg.r_sstatus();
    var new_status = status - (1 << SSTATUS_SIE);
    _ = reg.w_sstatus(new_status);
}
