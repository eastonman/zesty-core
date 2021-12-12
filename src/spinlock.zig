const arch = @import("riscv.zig");

// Spinlock Struct
const Spinlock = struct { lock: u32, name: []u8, hart: i64 };

/// new_spinlock accept a lock name, create a new spinlock
pub fn new(name: ?[]u8) Spinlock {
    if (name) |real_name| {
        return Spinlock{
            .lock = 0,
            .hart = arch.hart_id(),
            .name = "anonymous_lock",
        };
    } else {
        return Spinlock{
            .lock = 0,
            .hart = arch.hart_id(),
            .name = name,
        };
    }
}

pub fn lock(s: *Spinlock) void {
    if (holding(s)) {
        // TODO: Already holding lock, panic for safety, not implemented yet
    } else {
        // TODO: disable IRQ
        while (arch.__sync_lock_test_and_test(&s.lock, 1) != 0) {}
        arch.__sync_synchronize();
        s.hart = arch.hart_id(); // Set hart ID
    }
}

pub fn unlock(s: *Spinlock) void {
    if (holding(s)) {
        s.hart = -1;
        arch.__sync_synchronize();
        arch.__sync_lock_release(&s.lock);
        // TODO: enable IRQ
    } else {
        // TODO: panic
    }
}

inline fn holding(s: *Spinlock) bool {
    if (s.lock == 1 and s.hart == arch.hart_id()) {
        return true;
    } else {
        return false;
    }
}
