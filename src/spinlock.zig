//! Spinlock

const arch = @import("arch/riscv64/riscv.zig");
const irq = @import("interrupt/interrupt.zig");

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
            @panic("lock already held");
        } else {
            irq.disable(); // disable interrupts to avoid deadlock
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
            irq.enable(); // enable interrupts
        } else {
            @panic("not holding lock");
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
