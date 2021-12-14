//! Clock interrupt handler
const std = @import("std");
const clock = @import("../clock.zig");
const sbi = @import("../arch/riscv64/opensbi.zig");
const arch = @import("../arch/riscv64/riscv.zig");
const reg = @import("../arch/riscv64/reg.zig");

pub fn handle() void {
    sbi.set_timer(arch.get_time() + (arch.FREQ / arch.HZ));
    clock.TICK += 1;
    if (clock.TICK % 100 == 0) {
        std.log.info("1s has been submitted to '长者' at tick {}", .{clock.TICK});
    }
}
