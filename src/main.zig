//! main entry of kernel

const uart = @import("uart.zig");
const arch = @import("arch/riscv64/riscv.zig");
const sbi = @import("arch/riscv64/opensbi.zig");
const debug = @import("debug.zig");
const irq_handler = @import("interrupt/handler.zig");
const irq = @import("interrupt/interrupt.zig");
const clock = @import("clock.zig");
const std = @import("std");
const builtin = std.builtin;

export fn zig_main() noreturn {

    // No interrupt during initialization
    irq.disable();

    // Inital UART0
    uart.uart = uart.Uart.new(arch.memory_layout.UART0);
    uart.uart.init();

    // Boot message
    uart.write("\nBooting Zesty-Core...\n\n");

    // Initial interrupt handling
    std.log.info("Initializing IRQ...", .{});
    irq_handler.init(); // Interrupt Vector

    clock.enable_clock_interrupt(); // Accept timer interrupt
    std.log.info("Clock IRQ initialized with {} Hz", .{arch.HZ});

    // Done initializing interrupt
    std.log.info("Initialized IRQ.", .{});
    sbi.set_timer(1); // Set next timer to something other than 0 to activate timer
    irq.enable();
    std.log.info("IRQ enabled.", .{});

    asm volatile ("ebreak");

    while (true) {}

    sbi.shutdown(); // No return for shutdown
}

/// Implement root.log to override the std implementation
/// See https://github.com/ziglang/zig/blob/0.8.x/lib/std/log.zig#L31-L54
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // Ignore all non-error logging from sources other than
    // .my_project, .nice_library and .default
    const scope_prefix = "(" ++ switch (scope) {
        .my_project, .nice_library, .default => @tagName(scope),
        else => if (@enumToInt(level) <= @enumToInt(std.log.Level.err))
            @tagName(scope)
        else
            return,
    } ++ "): ";

    const prefix = "[" ++ @tagName(level) ++ "] " ++ scope_prefix;

    // Print the message to UART0, silently ignoring any errors
    uart.print(prefix ++ format ++ "\n", args);
}

var panicking: usize = 0;

// Hangs
fn hang() noreturn {
    while (true) {}
}

/// Implement root.panic to overide the std implementation
pub fn panic(message: []const u8, stack_trace: ?*builtin.StackTrace) noreturn {
    @setCold(true);

    // Very wrong
    if (panicking != 0) {
        uart.write("\npanicked during kernel panic!\n");
        hang();
    }

    // Panic
    _ = @atomicRmw(usize, &panicking, .Add, 1, .SeqCst); // Atomic
    std.log.emerg("KERNEL PANIC: {s}", .{message});

    uart.write("\n");
    uart.write("\n");
    uart.write("\n");
    hang();
}
