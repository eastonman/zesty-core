const uart = @import("uart.zig");
const arch = @import("arch/riscv64/riscv.zig");

export fn zig_main() void {

    // Inital UART0
    uart.uart = uart.Uart.new(arch.memory_layout.UART0);
    uart.uart.init();
    uart.uart.put('A');

    // No return
    while (true) {}
}
