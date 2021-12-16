const std = @import("std");
usingnamespace @import("util.zig");
usingnamespace @import("fdt.zig");

pub const Error = error{
    Truncated,
    BadMagic,
    UnsupportedVersion,
    BadStructure,
    Internal,
};

pub const Event = union(enum) {
    BeginNode: []const u8,
    EndNode,
    Prop: Prop,
    End,
};

pub const State = union(enum) {
    Event: Event,
    Error: Error,
};

pub const Prop = struct {
    name: []const u8,
    value: []const u8,
};

pub const Traverser = struct {
    const Self = @This();

    state: State = .{ .Error = error.Internal },
    frame: @Frame(traverse) = undefined,

    pub fn init(self: *Self, fdt: []const u8) Error!void {
        self.frame = async traverse(fdt, &self.state);
        switch (try self.current()) {
            .BeginNode => {},
            else => return error.Internal,
        }
    }

    pub fn current(self: *Self) Error!Event {
        switch (self.state) {
            .Event => |ev| return ev,
            .Error => |err| return err,
        }
    }

    pub fn next(self: *Self) Error!Event {
        resume self.frame;
        return self.current();
    }
};

/// Try to carefully extract the total size of an FDT at this address.
pub fn totalSize(fdt: *c_void) Error!u32 {
    const header_ptr = @ptrCast(*const FDTHeader, fdt);

    if (std.mem.bigToNative(u32, header_ptr.magic) != FDTMagic) {
        return error.BadMagic;
    }

    return std.mem.bigToNative(u32, header_ptr.totalsize);
}

pub fn traverse(fdt: []const u8, state: *State) void {
    if (fdt.len < @sizeOf(FDTHeader)) {
        state.* = .{ .Error = error.Truncated };
        return;
    }

    const header = structBigToNative(FDTHeader, @ptrCast(*const FDTHeader, fdt.ptr).*);
    if (header.magic != FDTMagic) {
        state.* = .{ .Error = error.BadMagic };
        return;
    }
    if (fdt.len < header.totalsize) {
        state.* = .{ .Error = error.Truncated };
        return;
    }
    if (header.version != 17) {
        state.* = .{ .Error = error.UnsupportedVersion };
        return;
    }

    var traverser = InternalTraverser{ .fdt = fdt, .header = header, .offset = header.off_dt_struct };
    if (traverser.token() != .BeginNode) {
        state.* = .{ .Error = error.BadStructure };
        return;
    }

    {
        const node_name = traverser.cstring();
        traverser.alignTo(u32);
        state.* = .{ .Event = .{ .BeginNode = node_name } };
        suspend {}
    }

    var depth: usize = 1;
    while (depth > 0) {
        switch (traverser.token()) {
            .BeginNode => {
                depth += 1;
                const node_name = traverser.cstring();
                traverser.alignTo(u32);
                state.* = .{ .Event = .{ .BeginNode = node_name } };
                suspend {}
            },
            .EndNode => {
                depth -= 1;
                state.* = .{ .Event = .EndNode };
                suspend {}
            },
            .Prop => {
                const prop = traverser.object(FDTProp);
                const prop_name = traverser.cstringFromSectionOffset(prop.nameoff);
                const prop_value = traverser.buffer(prop.len);
                state.* = .{
                    .Event = .{
                        .Prop = .{
                            .name = prop_name,
                            .value = prop_value,
                        },
                    },
                };
                suspend {}
                traverser.alignTo(u32);
            },
            .Nop => {},
            .End => {
                state.* = .{ .Error = error.BadStructure };
                return;
            },
        }
    }

    if (traverser.token() != .End) {
        state.* = .{ .Error = error.BadStructure };
        return;
    }
    if (traverser.offset != header.off_dt_struct + header.size_dt_struct) {
        state.* = .{ .Error = error.BadStructure };
        return;
    }

    state.* = .{ .Event = .End };
}

/// ---
const InternalTraverser = struct {
    fdt: []const u8,
    header: FDTHeader,
    offset: usize,

    fn aligned(traverser: *@This(), comptime T: type) T {
        const size = @sizeOf(T);
        const value = @ptrCast(*const T, @alignCast(@alignOf(T), traverser.fdt[traverser.offset .. traverser.offset + size])).*;
        traverser.offset += size;
        return value;
    }

    fn buffer(traverser: *@This(), length: usize) []const u8 {
        const value = traverser.fdt[traverser.offset .. traverser.offset + length];
        traverser.offset += length;
        return value;
    }

    fn token(traverser: *@This()) FDTToken {
        return @intToEnum(FDTToken, std.mem.bigToNative(u32, traverser.aligned(u32)));
    }

    fn object(traverser: *@This(), comptime T: type) T {
        return structBigToNative(T, traverser.aligned(T));
    }

    fn cstring(traverser: *@This()) []const u8 {
        const length = std.mem.lenZ(@ptrCast([*c]const u8, traverser.fdt[traverser.offset..]));
        const value = traverser.fdt[traverser.offset .. traverser.offset + length];
        traverser.offset += length + 1;
        return value;
    }

    fn cstringFromSectionOffset(traverser: @This(), offset: usize) []const u8 {
        const length = std.mem.lenZ(@ptrCast([*c]const u8, traverser.fdt[traverser.header.off_dt_strings + offset ..]));
        return traverser.fdt[traverser.header.off_dt_strings + offset ..][0..length];
    }

    fn alignTo(traverser: *@This(), comptime T: type) void {
        traverser.offset += @sizeOf(T) - 1;
        traverser.offset &= ~@as(usize, @sizeOf(T) - 1);
    }
};
