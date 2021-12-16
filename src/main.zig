// Zesty-Core
// Copyright (C) 2021 EastonMan

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//! Main entry of kernel
//! Also the root of project

const uart = @import("uart.zig");
const arch = @import("arch/riscv64/riscv.zig");
const sbi = @import("arch/riscv64/opensbi.zig");
const debug = @import("debug.zig");
const irq_handler = @import("interrupt/handler.zig");
const irq = @import("interrupt/interrupt.zig");
const clock = @import("clock.zig");
const hwinfo = @import("hwinfo.zig");
const std = @import("std");
const builtin = std.builtin;

const log_scope = enum {
    init,
};

export fn zig_main(boot_hart_id: usize, flattened_device_tree: usize) noreturn {

    // No interrupt during initialization
    irq.disable();

    // Initialize logger
    const logger = std.log.scoped(.init);

    // Inital UART0
    uart.uart = uart.Uart.new(arch.memory_layout.UART0);
    uart.uart.init();

    // Boot message
    uart.write("\n============= Booting Zesty-Core... ===============\n\n");

    // Boot CPU ID
    logger.info("Boot HART ID: {}", .{boot_hart_id});

    // Initial interrupt handling
    logger.info("Initializing IRQ...", .{});
    irq_handler.init(); // Interrupt Vector

    clock.enable_clock_interrupt(); // Accept timer interrupt
    logger.info("Clock IRQ initialized with {} Hz", .{arch.HZ});

    // Done initializing interrupt
    logger.info("Initialized IRQ.", .{});
    sbi.set_timer(1); // Set next timer to something other than 0 to activate timer
    irq.enable();
    logger.info("IRQ enabled.", .{});

    // Parse Device Tree
    hwinfo.init(flattened_device_tree);
    logger.info("Configured with memory size: {} MiB", .{hwinfo.info.memory_size / 1024 / 1024});

    asm volatile ("ebreak");

    while (true) {}

    sbi.shutdown(); // No return for shutdown
}

/// Implement root.log to override the std implementation
/// See https://github.com/ziglang/zig/blob/0.8.x/lib/std/log.zig#L31-L54
/// And https://github.com/ziglang/zig/blob/master/lib/std/log.zig#L166 for not checking log_level
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // No need to check log level
    const scope_prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

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
