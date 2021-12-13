const arch = @import("arch/riscv64/riscv.zig");

// Spinlock Struct
pub const Spinlock = struct {
    _lock: usize align(64),
    name: []const u8,
    hart: i64,

    /// new_spinlock accept a lock name, create a new spinlock
    pub fn new(name: ?[]const u8) Spinlock {
        if (name) |real_name| {
            return Spinlock{
                ._lock = 0,
                .hart = -1,
                .name = real_name,
            };
        } else {
            return Spinlock{
                ._lock = 0,
                .hart = -1,
                .name = "anonymous_lock",
            };
        }
    }

    /// Lock itself
    pub fn lock(self: *Spinlock) void {
        if (self.holding()) {
            // TODO: Already holding lock, panic for safety, not implemented yet
        } else {
            // TODO: disable IRQ
            while (arch.__sync_lock_test_and_set(&self._lock, 1) == 0) {}
            arch.__sync_synchronize();
            self.hart = @intCast(i64, arch.hart_id()); // Set hart ID
        }
    }

    /// Release itself
    pub fn unlock(self: *Spinlock) void {
        if (self.holding()) {
            self.hart = -1;
            arch.__sync_synchronize();
            arch.__sync_lock_release(&self._lock);
            // TODO: enable IRQ
        } else {
            // TODO: panic
        }
    }

    // Check for holding
    inline fn holding(self: *const Spinlock) bool {
        if (self._lock == 1 and self.hart == @intCast(i64, arch.hart_id())) {
            return true;
        } else {
            return false;
        }
    }
};
