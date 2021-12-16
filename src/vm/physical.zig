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
    var current_addr = start_addr;
    while (current_addr < end_addr - arch.PAGE_SIZE) : (current_addr += arch.PAGE_SIZE) {
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

pub const OutOfMemoryError = error{};

pub fn alloc() OutOfMemoryError!usize {

    // Lock the list
    kmem_lock.lock();
    defer kmem_lock.unlock();

    var r = @intToPtr(*kmem_list_node, @ptrToInt(pool));
    if (r == null) {
        return OutOfMemoryError;
    } else {
        // Fill the page with junk
        @memset(@bitCast([*]u8, r), 5, arch.PAGE_SIZE);
    }
}
