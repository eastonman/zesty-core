//! main entry of kernel

const uart = @import("uart.zig");
const arch = @import("arch/riscv64/riscv.zig");
const sbi = @import("arch/riscv64/opensbi.zig");
const debug = @import("debug.zig");
const irq = @import("interrupt/handler.zig");
const std = @import("std");
const builtin = std.builtin;

export fn zig_main() noreturn {

    // Inital UART0
    uart.uart = uart.Uart.new(arch.memory_layout.UART0);
    uart.uart.init();
    uart.write("\nBooting Zesty-Core...\n\n");

    std.log.info("Hello, World!", .{});
    std.log.info("Enabling IRQ...", .{});
    irq.init();
    std.log.info("Enabled IRQ.", .{});

    asm volatile ("ebreak");

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
