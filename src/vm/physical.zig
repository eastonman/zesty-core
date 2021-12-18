//! Physical memory management interface

const std = @import("std");
const spinlock = @import("../spinlock.zig");
const arch = @import("../arch/riscv64/riscv.zig");

var kmem_lock: spinlock.Spinlock = undefined;

/// The whole physical memory pool
var pool: ?*kmem_list_node = null;

/// Linked list node
const kmem_list_node = struct {
    next: ?*kmem_list_node,
};

/// init prepend all the physical page to a linked list
/// @param start_addr must be rounded up to PAGE_SIZE
pub fn init(start_addr: usize, end_addr: usize) void {
    // Initial lock
    kmem_lock = spinlock.Spinlock.new("kmem_lock");

    // Start initialization
    var current_addr = end_addr - arch.PAGE_SIZE;
    while (current_addr > start_addr) : (current_addr -= arch.PAGE_SIZE) {
        free(current_addr);
    }
}

pub fn free(addr: usize) void {

    // Lock the list
    kmem_lock.lock();
    defer kmem_lock.unlock();

    // Prepend the page
    var r = @intToPtr(*kmem_list_node, addr);
    r.next = pool;
    pool = r;
}

/// alloc allocate a physical page 
/// return empty if out of memory
pub fn alloc() ?usize {

    // Lock the list
    kmem_lock.lock();
    defer kmem_lock.unlock();

    if (pool) |p| {
        // Get one page
        const r = p;
        pool = p.next;

        // Fill the page with junk
        @memset(@ptrCast([*]u8, r), 5, arch.PAGE_SIZE);

        return @ptrToInt(r);
    } else {
        return null;
    }
}

fn test_alloc() void {
    const page = alloc();
    if (page) |p| {
        std.log.debug("page addr: {x}", .{p});
        free(p);
    } else {
        @panic("allocate physical page failed");
    }
}
