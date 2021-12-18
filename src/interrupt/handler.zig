//! Zig level of IRQ handler

const std = @import("std");
const Context = @import("../context.zig").Context;
const clock = @import("clock.zig");
const irq = @import("interrupt.zig");

const IRQ_BREAKPOINT: u64 = 3;
const IRQ_S_TIMER: u64 = (0b1 << 63) + 5;

export fn zig_handler(context: *Context, scause: usize, stval: usize) void {

    // disable interrupts
    // TODO: allow some interrupts when available
    irq.disable();

    // Handler dispatch
    switch (scause) {
        IRQ_BREAKPOINT => {
            std.log.debug("Break point", .{});
            context.sepc += 2; // magic number to bypass ebreak itself, see https://rcore-os.github.io/rCore-Tutorial-deploy/docs/lab-1/guide/part-6.html
        },
        IRQ_S_TIMER => clock.handle(),
        else => {
            std.log.err("Interrupt scause: {x}", .{scause});
            @panic("Unknown interrupt");
        },
    }

    // Re-enable interrupts
    irq.enable();
}

extern fn register_asm_handler() void;
/// Setup 
pub fn init() void {
    register_asm_handler();
}
