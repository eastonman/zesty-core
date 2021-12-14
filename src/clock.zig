//! Clock related 

const reg = @import("arch/riscv64/reg.zig");

pub var TICK: u64 = 0;

const SIE_STIE = 5;

pub fn enable_clock_interrupt() void {
    var sie = reg.r_sie();
    sie = sie | (1 << SIE_STIE);
    reg.w_sie(sie);
}
