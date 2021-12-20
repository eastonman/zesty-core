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
const vm = @import("vm/vm.zig");
const std = @import("std");
const builtin = std.builtin;

const log_scope = enum {
    init,
};

extern const kernel_end: usize;
extern const kernel_start: usize;

export fn zig_main(boot_hart_id: usize, flattened_device_tree: usize) noreturn {
    if (arch.hart_id() == boot_hart_id) {
        // Yes I am the god chosen boot cpu

        // TODO: panic if HZ value is unreasonable
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
        logger.debug("Boot HART ID: {}", .{boot_hart_id});
        logger.debug("Init HART ID: {x}", .{arch.hart_id()});

        // Initial interrupt handling
        logger.debug("Initializing IRQ...", .{});
        irq_handler.init(); // Interrupt Vector

        clock.enable_clock_interrupt(); // Accept timer interrupt
        logger.debug("Clock IRQ initialized with {} Hz", .{arch.HZ});

        // Done initializing interrupt
        logger.debug("Initialized IRQ.", .{});
        sbi.set_timer(1); // Set next timer to something other than 0 to activate timer
        irq.enable();
        logger.info("IRQ enabled.", .{});

        // Parse Device Tree
        hwinfo.init(flattened_device_tree);
        logger.debug("Kernel binary size: {} KiB", .{(@ptrToInt(&kernel_end) - @ptrToInt(&kernel_start)) / 1024});
        logger.debug("Device tree location:\t 0x{x:0>16}", .{flattened_device_tree});
        logger.info("Configured with memory size: {d} MiB", .{@intToFloat(f64, hwinfo.info.memory_size) / 1024 / 1024});

        // Prepare for paging
        vm.init(); // Physical memory
        vm.kernel_vm_init(); // Build kernel pagetable

        // Enable paging
        vm.enablePaging();
        logger.info("Memory paging enabled", .{});

        asm volatile ("ebreak");

        while (true) {}
        std.log.info("Shutting down", .{});
        sbi.shutdown(); // No return for shutdown
    } else {
        // Oops, I have to wait for the boot cpu to finish
        while (true) {}
    }
}

/// Define root.log_level to override the default
pub const log_level: std.log.Level = switch (std.builtin.mode) {
    .Debug => .debug,
    .ReleaseSafe => .debug,
    .ReleaseFast, .ReleaseSmall => .info,
};

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

    var time: [20]u8 = undefined; // 20 should be enough for 64 bit system
    const buffer = time[0..];
    const time_str = std.fmt.bufPrint(buffer, "{d:>6}", .{@intToFloat(f64, clock.TICK) / @intToFloat(f64, arch.HZ)}) catch @panic("Unexpected format error in root.log");
    const prefix = "[" ++ @tagName(level) ++ "] " ++ scope_prefix;

    // Print the message to UART0, ignore any errors
    // Timestamp
    uart.write("[");
    uart.write(time_str);
    uart.write("] ");
    // message
    uart.print(prefix ++ format ++ "\n", args);
}

var panicking: usize = 0;

// Hangs
fn hang() noreturn {
    irq.disable(); // Not allowed interrupt
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
