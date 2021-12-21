pub const FDTMagic: u32 = 0xd00dfeed;

pub const FDTHeader = packed struct {
    magic: u32,
    totalsize: u32,
    off_dt_struct: u32,
    off_dt_strings: u32,
    off_mem_rsvmap: u32,
    version: u32,
    last_comp_version: u32,
    boot_cpuid_phys: u32,
    size_dt_strings: u32,
    size_dt_struct: u32,
};

pub const FDTReserveEntry = packed struct {
    address: u64,
    size: u64,
};

pub const FDTToken = enum(u32) {
    BeginNode = 0x00000001,
    EndNode = 0x00000002,
    Prop = 0x00000003,
    Nop = 0x00000004,
    End = 0x00000009,
};

pub const FDTProp = packed struct {
    len: u32,
    nameoff: u32,
};
