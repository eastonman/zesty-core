//! Memory management entry point

const physical = @import("physical.zig");
const utils = @import("utils.zig");
const std = @import("std");
const hwinfo = @import("../hwinfo.zig");

extern const kernel_end: usize;
extern const kernel_start: usize;

const logger = std.log.scoped(.memory);

/// Init must be run after the device tree has been parsed.
pub fn init() void {

    // Security check
    if (hwinfo.info.memory_size <= 4096) { // some magic number, memory should be way more then 4096 bytes
        @panic("Abnormal memory size, maybe the device tree hasn't been parsed yet'");
    }
    if (hwinfo.info.memory_start == 0) { // memory start is not initialized
        @panic("Abnormal memory start, maybe the device tree hasn't been parsed yet'");
    }

    logger.debug("Start building memory data structure", .{});

    // Calculate the start and end of the usable memory
    const memory_start = utils.PAGE_ROUND_UP(@ptrToInt(&kernel_end));
    const memory_end = utils.PAGE_ROUND_DOWN(hwinfo.info.memory_start + hwinfo.info.memory_size);
    logger.debug("Usable RAM start\t 0x{x}", .{memory_start});
    logger.debug("Usable RAM ends\t 0x{x}", .{memory_end});

    physical.init(memory_start, memory_end);

    logger.info("Physical memory data structure initialized", .{});
}
