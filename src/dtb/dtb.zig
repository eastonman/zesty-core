// https://github.com/kivikakk/dtb.zig
// All rights reserved.

const std = @import("std");
const testing = std.testing;
const parser = @import("parser.zig");
const traverser = @import("traverser.zig");
pub const Traverser = traverser.Traverser;
pub const totalSize = traverser.totalSize;

pub const Node = struct {
    name: []const u8,
    props: []Prop,
    root: *Node,
    parent: ?*Node,
    children: []*Node,

    pub fn propAt(start: *const Node, path: []const []const u8, comptime prop_tag: std.meta.Tag(Prop)) ?std.meta.TagPayload(Prop, prop_tag) {
        var node: *const Node = start;
        var i: usize = 0;
        while (i < path.len) : (i += 1) {
            node = node.child(path[i]) orelse return null;
        }
        return node.prop(prop_tag);
    }

    pub fn child(node: *const Node, child_name: []const u8) ?*Node {
        for (node.children) |c| {
            if (std.mem.eql(u8, child_name, c.name)) {
                return c;
            }
        }
        return null;
    }

    pub fn prop(node: *const Node, comptime prop_tag: std.meta.Tag(Prop)) ?std.meta.TagPayload(Prop, prop_tag) {
        for (node.props) |p| {
            if (p == prop_tag) {
                return @field(p, @tagName(prop_tag));
            }
        }
        return null;
    }

    pub fn interruptCells(node: *Node) ?u32 {
        if (node.prop(.InterruptCells)) |ic| {
            return ic;
        }
        if (node.interruptParent()) |ip| {
            return ip.interruptCells();
        }
        return null;
    }

    pub fn interruptParent(node: *Node) ?*Node {
        if (node.prop(.InterruptParent)) |ip| {
            return node.root.findPHandle(ip);
        }
        return node.parent;
    }

    pub fn findPHandle(node: *Node, phandle: u32) ?*Node {
        if (node.prop(.PHandle)) |v| {
            if (v == phandle) {
                return node;
            }
        }
        for (node.children) |c| {
            if (c.findPHandle(phandle)) |n| {
                return n;
            }
        }
        return null;
    }

    pub fn addressCells(node: *const Node) ?u32 {
        return node.prop(.AddressCells) orelse (node.parent orelse return null).addressCells();
    }

    pub fn sizeCells(node: *const Node) ?u32 {
        return node.prop(.SizeCells) orelse (node.parent orelse return null).sizeCells();
    }

    pub fn deinit(node: *Node, allocator: *std.mem.Allocator) void {
        for (node.props) |p| {
            p.deinit(allocator);
        }
        allocator.free(node.props);
        for (node.children) |c| {
            c.deinit(allocator);
        }
        allocator.free(node.children);
        allocator.destroy(node);
    }

    pub fn format(node: Node, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try node.formatNode(writer, 0);
    }

    fn formatNode(node: Node, writer: anytype, depth: usize) std.os.WriteError!void {
        try indent(writer, depth);
        try std.fmt.format(writer, "Node <{'}>\n", .{std.zig.fmtEscapes(node.name)});
        for (node.props) |p| {
            try indent(writer, depth + 1);
            try std.fmt.format(writer, "{}\n", .{p});
        }
        for (node.children) |c| {
            try c.formatNode(writer, depth + 1);
        }
    }

    fn indent(writer: anytype, depth: usize) !void {
        var i: usize = 0;
        while (i < depth) : (i += 1) {
            try writer.writeAll("  ");
        }
    }
};

pub const PropStatus = enum {
    Okay,
    Disabled,
    Fail,

    pub fn format(status: PropStatus, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (status) {
            .Okay => try writer.writeAll("okay"),
            .Disabled => try writer.writeAll("disabled"),
            .Fail => try writer.writeAll("fail"),
        }
    }
};

pub const Prop = union(enum) {
    AddressCells: u32,
    SizeCells: u32,
    InterruptCells: u32,
    ClockCells: u32,
    RegShift: u32,
    PHandle: u32,
    InterruptParent: u32,
    Reg: [][2]u128,
    Ranges: [][3]u128,
    Compatible: [][]const u8,
    Status: PropStatus,
    Interrupts: [][]u32,
    Clocks: [][]u32,
    ClockNames: [][]const u8,
    ClockOutputNames: [][]const u8,
    ClockFrequency: u64,
    InterruptNames: [][]const u8,
    RegIoWidth: u64,
    PinctrlNames: [][]const u8,
    Pinctrl0: []u32,
    Pinctrl1: []u32,
    Pinctrl2: []u32,
    AssignedClockRates: []u32,
    AssignedClocks: [][]u32,
    Unresolved: PropUnresolved,
    Unknown: PropUnknown,

    pub fn format(prop: Prop, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (prop) {
            .AddressCells => |v| try std.fmt.format(writer, "#address-cells: 0x{x:0>2}", .{v}),
            .SizeCells => |v| try std.fmt.format(writer, "#size-cells: 0x{x:0>2}", .{v}),
            .InterruptCells => |v| try std.fmt.format(writer, "#interrupt-cells: 0x{x:0>2}", .{v}),
            .ClockCells => |v| try std.fmt.format(writer, "#clock-cells: 0x{x:0>2}", .{v}),
            .RegShift => |v| try std.fmt.format(writer, "reg-shift: 0x{x:0>2}", .{v}),
            .Reg => |v| {
                try writer.writeAll("reg: <");
                for (v) |pair, i| {
                    if (i != 0) {
                        try writer.writeAll(">, <");
                    }
                    try std.fmt.format(writer, "0x{x:0>2} 0x{x:0>2}", .{ pair[0], pair[1] });
                }
                try writer.writeByte('>');
            },
            .Ranges => |v| {
                try writer.writeAll("ranges: <");
                for (v) |triple, i| {
                    if (i != 0) {
                        try writer.writeAll(">, <");
                    }
                    try std.fmt.format(writer, "0x{x:0>2} 0x{x:0>2} 0x{x:0>2}", .{ triple[0], triple[1], triple[2] });
                }
                try writer.writeByte('>');
            },
            .Compatible => |v| try (StringListFormatter{ .string_list = v }).write("compatible: ", writer),
            .Status => |v| try std.fmt.format(writer, "status: \"{s}\"", .{v}),
            .PHandle => |v| try std.fmt.format(writer, "phandle: <0x{x:0>2}>", .{v}),
            .InterruptParent => |v| try std.fmt.format(writer, "interrupt-parent: <0x{x:0>2}>", .{v}),
            .Interrupts => |groups| {
                try writer.writeAll("interrupts: <");
                for (groups) |group, i| {
                    if (i != 0) {
                        try writer.writeAll(">, <");
                    }
                    for (group) |item, j| {
                        if (j != 0) {
                            try writer.writeAll(" ");
                        }
                        try std.fmt.format(writer, "0x{x:0>2}", .{item});
                    }
                }
                try writer.writeAll(">");
            },
            .Clocks,
            .AssignedClocks,
            => |groups| {
                switch (prop) {
                    .Clocks => try writer.writeAll("clocks: <"),
                    .AssignedClocks => try writer.writeAll("assigned-clocks: <"),
                    else => unreachable,
                }
                for (groups) |group, i| {
                    if (i != 0) {
                        try writer.writeAll(">, <");
                    }
                    for (group) |item, j| {
                        if (j != 0) {
                            try writer.writeAll(" ");
                        }
                        try std.fmt.format(writer, "0x{x:0>2}", .{item});
                    }
                }
                try writer.writeAll(">");
            },
            .ClockNames => |v| try (StringListFormatter{ .string_list = v }).write("clock-names: ", writer),
            .ClockOutputNames => |v| try (StringListFormatter{ .string_list = v }).write("clock-output-names: ", writer),
            .ClockFrequency => |v| try (FrequencyFormatter{ .freq = v }).write("clock-frequency: ", writer),
            .InterruptNames => |v| try (StringListFormatter{ .string_list = v }).write("interrupt-names: ", writer),
            .RegIoWidth => |v| try std.fmt.format(writer, "reg-io-width: 0x{x:0>2}", .{v}),
            .PinctrlNames => |v| try (StringListFormatter{ .string_list = v }).write("pinctrl-names: ", writer),
            .Pinctrl0, .Pinctrl1, .Pinctrl2 => |phandles| {
                try std.fmt.format(writer, "pinctrl{s}: <", .{switch (prop) {
                    .Pinctrl0 => "0",
                    .Pinctrl1 => "1",
                    .Pinctrl2 => "2",
                    else => unreachable,
                }});
                for (phandles) |phandle, i| {
                    if (i != 0) {
                        try writer.writeAll(" ");
                    }
                    try std.fmt.format(writer, "0x{x:0>4}", .{phandle});
                }
                try writer.writeByte('>');
            },
            .AssignedClockRates => |clock_rates| {
                try writer.writeAll("assigned-clock-rates: <");
                for (clock_rates) |clock_rate, i| {
                    if (i != 0) {
                        try writer.writeAll(" ");
                    }
                    try (FrequencyFormatter{ .freq = clock_rate }).write("", writer);
                }
                try writer.writeByte('>');
            },
            .Unresolved => |_| try writer.writeAll("UNRESOLVED"),
            .Unknown => |v| try std.fmt.format(writer, "{'}: (unk {} bytes) <{}>", .{ std.zig.fmtEscapes(v.name), v.value.len, std.zig.fmtEscapes(v.value) }),
        }
    }

    const FrequencyFormatter = struct {
        freq: u64,

        // Exists to work around https://github.com/ziglang/zig/issues/7534.
        pub fn write(this: @This(), comptime prefix: []const u8, writer: anytype) !void {
            try writer.writeAll(prefix);
            try this.format("", .{}, writer);
        }

        pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            if (this.freq / 1_000_000_000 > 0) {
                try std.fmt.format(writer, "{d}GHz", .{@intToFloat(f32, this.freq / 1_000_000) / 1_000});
            } else if (this.freq / 1_000_000 > 0) {
                try std.fmt.format(writer, "{d}MHz", .{@intToFloat(f32, this.freq / 1_000) / 1_000});
            } else if (this.freq / 1_000 > 0) {
                try std.fmt.format(writer, "{d}kHz", .{@intToFloat(f32, this.freq) / 1_000});
            } else {
                try std.fmt.format(writer, "{}Hz", .{this.freq});
            }
        }
    };
    const StringListFormatter = struct {
        string_list: [][]const u8,

        // Exists to work around https://github.com/ziglang/zig/issues/7534.
        pub fn write(this: @This(), comptime prefix: []const u8, writer: anytype) !void {
            try writer.writeAll(prefix);
            try this.format("", .{}, writer);
        }

        pub fn format(this: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.writeByte('"');
            for (this.string_list) |s, i| {
                if (i != 0) {
                    try writer.writeAll("\", \"");
                }
                try writer.writeAll(s);
            }
            try writer.writeByte('"');
        }
    };

    pub fn deinit(prop: Prop, allocator: *std.mem.Allocator) void {
        switch (prop) {
            .Reg => |v| allocator.free(v),
            .Ranges => |v| allocator.free(v),

            .Compatible,
            .ClockNames,
            .ClockOutputNames,
            .InterruptNames,
            .PinctrlNames,
            => |v| allocator.free(v),

            .Interrupts,
            .Clocks,
            .AssignedClocks,
            => |groups| {
                for (groups) |group| {
                    allocator.free(group);
                }
                allocator.free(groups);
            },

            .Pinctrl0,
            .Pinctrl1,
            .Pinctrl2,
            => |phandles| allocator.free(phandles),

            .AssignedClockRates => |clock_rates| allocator.free(clock_rates),

            .AddressCells,
            .SizeCells,
            .InterruptCells,
            .ClockCells,
            .RegShift,
            .PHandle,
            .InterruptParent,
            .Status,
            .Unresolved,
            .Unknown,
            .ClockFrequency,
            .RegIoWidth,
            => {},
        }
    }
};

pub const PropUnresolved = union(enum) {
    Reg: []const u8,
    Ranges: []const u8,
    Interrupts: []const u8,
    Clocks: []const u8,
    AssignedClocks: []const u8,
};

pub const PropUnknown = struct {
    name: []const u8,
    value: []const u8,
};

pub const parse = parser.parse;
pub const Error = parser.Error;

const qemu_arm64_dtb = @embedFile("../qemu_arm64.dtb");
const rockpro64_dtb = @embedFile("../rk3399-rockpro64.dtb");

test "parse" {
    {
        var qemu_arm64 = try parse(std.testing.allocator, qemu_arm64_dtb);
        defer qemu_arm64.deinit(std.testing.allocator);

        // This QEMU DTB places 512MiB of memory at 1GiB.
        testing.expectEqualSlices(
            [2]u128,
            &.{.{ 1024 * 1024 * 1024, 512 * 1024 * 1024 }},
            qemu_arm64.propAt(&.{"memory@40000000"}, .Reg).?,
        );

        // It has an A53-compatible CPU.
        const compatible = qemu_arm64.propAt(&.{ "cpus", "cpu@0" }, .Compatible).?;
        testing.expectEqual(@as(usize, 1), compatible.len);
        testing.expectEqualStrings("arm,cortex-a53", compatible[0]);

        // Its pl011 UART controller has interrupts defined by <0x00 0x01 0x04>.
        // This tests the #interrupt-cells lookup.  Its interrupt domain
        // is defined ahead of it in the file.
        // This defines one SPI-type interrupt, IRQ 1, active high
        // level-sensitive. See https://git.io/JtKJk.
        const pl011 = qemu_arm64.child("pl011@9000000").?;
        const interrupts = pl011.prop(.Interrupts).?;
        testing.expectEqual(@as(usize, 1), interrupts.len);
        testing.expectEqualSlices(u32, &.{ 0x0, 0x01, 0x04 }, interrupts[0]);

        // Test we refer to the apb-pclk's clock cells (0) correctly.
        testing.expectEqual(@as(u32, 0), qemu_arm64.propAt(&.{"apb-pclk"}, .ClockCells).?);
        const clock_names = pl011.prop(.ClockNames).?;
        testing.expectEqual(@as(usize, 2), clock_names.len);
        testing.expectEqualSlices(u8, "uartclk", clock_names[0]);
        testing.expectEqualSlices(u8, "apb_pclk", clock_names[1]);
        const clocks = pl011.prop(.Clocks).?;
        testing.expectEqual(@as(usize, 2), clocks.len);
        testing.expectEqualSlices(u32, &.{0x8000}, clocks[0]);
        testing.expectEqualSlices(u32, &.{0x8000}, clocks[1]);

        // Make sure this works (and that the code gets compiled).
        std.debug.print("{}\n", .{qemu_arm64});
    }

    {
        var rockpro64 = try parse(std.testing.allocator, rockpro64_dtb);
        defer rockpro64.deinit(std.testing.allocator);

        // This ROCKPro64 DTB has a serial at 0xff1a0000.
        const serial = rockpro64.child("serial@ff1a0000").?;
        testing.expectEqualSlices([2]u128, &.{.{ 0xff1a0000, 0x100 }}, serial.prop(.Reg).?);
        testing.expectEqual(PropStatus.Okay, serial.prop(.Status).?);
        testing.expectEqual(@as(u32, 2), serial.prop(.RegShift).?);
        testing.expectEqual(@as(u32, 0x2e), serial.prop(.PHandle).?);

        const compatible = serial.prop(.Compatible).?;
        testing.expectEqual(@as(usize, 2), compatible.len);
        testing.expectEqualStrings("rockchip,rk3399-uart", compatible[0]);
        testing.expectEqualStrings("snps,dw-apb-uart", compatible[1]);

        const interrupts = serial.prop(.Interrupts).?;
        testing.expectEqual(@as(usize, 1), interrupts.len);
        // GICv3 specifies 4 interrupt cells. This defines an SPI-type
        // interrupt, IRQ 100, level triggered. The last field must be zero
        // for SPI interrupts.
        testing.expectEqualSlices(u32, &.{ 0x0, 0x64, 0x04, 0x00 }, interrupts[0]);

        // Test that we refer to the clock controller's clock cells (1) correctly.
        testing.expectEqual(@as(u32, 1), rockpro64.propAt(&.{"clock-controller@ff760000"}, .ClockCells).?);
        const clock_names = serial.prop(.ClockNames).?;
        testing.expectEqual(@as(usize, 2), clock_names.len);
        testing.expectEqualSlices(u8, "baudclk", clock_names[0]);
        testing.expectEqualSlices(u8, "apb_pclk", clock_names[1]);
        const clocks = serial.prop(.Clocks).?;
        testing.expectEqual(@as(usize, 2), clocks.len);
        testing.expectEqualSlices(u32, &.{ 0x85, 0x53 }, clocks[0]);
        testing.expectEqualSlices(u32, &.{ 0x85, 0x162 }, clocks[1]);

        // Print it out.
        std.debug.print("{}\n", .{rockpro64});
    }
}

test "Traverser" {
    var qemu_arm64: Traverser = undefined;
    try qemu_arm64.init(qemu_arm64_dtb);

    var state: union(enum) { OutsidePl011, InsidePl011 } = .OutsidePl011;
    var ev = try qemu_arm64.current();

    var reg_value: ?[]const u8 = null;

    while (ev != .End) : (ev = try qemu_arm64.next()) {
        switch (state) {
            .OutsidePl011 => if (ev == .BeginNode and std.mem.startsWith(u8, ev.BeginNode, "pl011@")) {
                state = .InsidePl011;
            },
            .InsidePl011 => switch (ev) {
                .EndNode => state = .OutsidePl011,
                .Prop => |prop| if (std.mem.eql(u8, prop.name, "reg")) {
                    reg_value = prop.value;
                },
                else => {},
            },
        }
    }

    std.testing.expectEqualSlices(u8, &.{ 0, 0, 0, 0, 0x09, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x10, 0 }, reg_value.?);
}
