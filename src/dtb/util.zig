const std = @import("std");

pub fn structBigToNative(comptime T: type, s: T) T {
    var r = s;
    inline for (std.meta.fields(T)) |field| {
        @field(r, field.name) = std.mem.bigToNative(field.field_type, @field(r, field.name));
    }
    return r;
}
