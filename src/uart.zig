// UART Driver
const Spinlock = @import("spinlock.zig").Spinlock;
const fmt = @import("std").fmt;
const io = @import("std").io;

// the UART control registers.
// some have different meanings for
// read vs write.
// http://byterunner.com/16550.html
const RHR: usize = 0; // receive holding register (for input bytes)
const THR: usize = 0; // transmit holding register (for output bytes)
const IER: usize = 1; // interrupt enable register
const FCR: usize = 2; // FIFO control register
const ISR: usize = 2; // interrupt status register
const LCR: usize = 3; // line control register
const LSR: usize = 5; // line status register

const spinlock_name = "uart_spinlock";

pub var uart: Uart = undefined;

/// UART Driver
/// seems not thread-safe, use with caution when in SMP mode
pub const Uart = struct {
    base_address: usize,
    lock: Spinlock,

    /// Return an uninitialized Uart instance
    pub fn new(address: usize) Uart {
        return Uart{
            .base_address = address,
            .lock = Spinlock.new(spinlock_name),
        };
    }

    /// init set baud rate and enable UART
    pub fn init(self: *Uart) void {
        self.lock.lock();
        defer self.lock.unlock();

        // Volatile needed
        // using C-type ptr
        const reg = @intToPtr([*c]volatile u8, self.base_address);

        // Disable interrupt
        reg[IER] = 0x00;

        // Enter setting mode
        reg[LCR] = 0x80;
        // Set baud rate to 38.4K, other value may be valid
        // but here just copy xv6 behaviour
        reg[0] = 0x03;
        reg[1] = 0x00;
        // Leave setting mode
        reg[LCR] = 0x03;

        // Reset and enable FIFO
        reg[FCR] = 0x07;

        // Re-enable interrupt
        reg[IER] = 0x01;
    }

    /// Put a char in to UART
    pub fn put(self: *Uart, c: u8) void {
        self.lock.lock();
        defer self.lock.unlock();
        const ptr = @intToPtr([*c]volatile u8, self.base_address);

        // Wait until previous data is flushed
        while (ptr[5] & (1 << 5) == 0) {}

        // Write our data
        ptr[0] = c;
    }

    /// Get a char from UART
    /// Return a optional u8, must check
    pub fn get(self: *Uart) ?u8 {
        self.lock.lock();
        defer self.lock.unlock();
        const ptr = @intToPtr([*c]volatile u8, self.base_address);

        if (ptr[5] & 1 == 0) {
            return null;
        } else {
            return ptr[0];
        }
    }
};

pub fn write(str: []const u8) void {
    for (str) |v| {
        uart.put(v);
    }
}

const WriteError = error{};

const Uart_Writer = io.Writer(void, WriteError, write_bytes);
const Uart_writer = @as(Uart_Writer, .{ .context = {} });
fn write_bytes(context: void, bytes: []const u8) WriteError!usize {
    write(bytes);
    return bytes.len;
}
pub fn print(comptime format: []const u8, args: anytype) void {
    Uart_writer.print(format, args) catch return;
}
