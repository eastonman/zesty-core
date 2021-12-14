//! Context struct

pub const Context = struct {
    reg: [32]usize,
    sstatus: usize,
    sepc: usize,
};
