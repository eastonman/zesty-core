//! Register access

pub inline fn w_sstatus(a: usize) void {
    asm volatile ("csrw sstatus, %[arg1]"
        :
        : [arg1] "r" (a)
    );
}

pub inline fn r_sstatus() usize {
    return asm volatile ("csrr %[ret], sstatus"
        : [ret] "=r" (-> usize)
    );
}

pub inline fn w_sie(a: usize) void {
    asm volatile ("csrw sie, %[arg]"
        :
        : [arg] "r" (a)
    );
}

pub inline fn r_sie() usize {
    return asm volatile ("csrr %[ret], sie"
        : [ret] "=r" (-> usize)
    );
}

pub inline fn r_cycle() usize {
    return asm volatile ("csrr %[ret], cycle"
        : [ret] "=r" (-> usize)
    );
}
