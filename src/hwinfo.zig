//! Hardware Information

const dtb = @import("dtb/dtb.zig");
const fdt = @import("dtb/fdt.zig");
const std = @import("std");

const Hardware_Info = struct {
    memory_start: usize = 0, // start of usable memory
    memory_size: u64 = 0,
};

pub var info: Hardware_Info = Hardware_Info{};

pub fn init(fdt_ptr: usize) void {
    const fdt_header: fdt.FDTHeader = @intToPtr(*fdt.FDTHeader, fdt_ptr).*;
    // const dtb_size = @byteSwap(u32, @intToPtr([*]u32, fdt_ptr)[1]);

    var dtb_traverser: dtb.Traverser = undefined;
    const dtb_content: []u8 = @intToPtr([*]u8, fdt_ptr)[0..fdt_header.totalsize];
    dtb_traverser.init(dtb_content) catch return;

    var state: enum {
        Inside,
        Outside,
    } = .Outside;

    var ev = dtb_traverser.current() catch return;
    var reg_value: ?[]const u64 = null;

    // Check the memory information
    while (ev != .End) : (ev = dtb_traverser.next() catch return) {
        switch (state) {
            .Outside => if (ev == .BeginNode and std.mem.startsWith(u8, ev.BeginNode, "memory")) {
                state = .Inside;
            },
            .Inside => {
                switch (ev) {
                    .EndNode => state = .Outside,
                    .Prop => |prop| if (std.mem.eql(u8, prop.name, "reg")) {
                        reg_value = @bitCast([]u64, prop.value);
                    },
                    else => {},
                }
            },
        }
    }
    if (reg_value) |value| {
        info.memory_start = @byteSwap(u64, value[0]);
        info.memory_size = @byteSwap(u64, value[1]);
    }
}
