//! Zig level of IRQ handler

export fn zig_handler() void {
    @panic("IRQ handled!");
}

extern fn register_asm_handler() void;
/// Setup 
pub fn init() void {
    register_asm_handler();
}
