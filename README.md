# Zesty-Core

> Zesty means we embrace new technology!
>
> Zesty begins with 'Z', which implies we are using Zig

Zesty-Core is a kernel written in [Zig](https://ziglang.org/), aiming to compatible with POSIX(May not be accomplished).

Currently can only run on QEMU with `-machine virt`


## Build

### Requirements

- Zig==0.8.1
- OpenSBI>=0.9

**Require Zig 0.8.1 Exactly!**

Since Zig is still under development, the API of std library is not stablized, so the exact same version of Zig is required.

By 2021-12-13, the upcoming Zig 0.9.0-dev is already breaking many std API and prevent the project from building.

Some SBI feature used in the kernel is in SBi v0.3, So OpenSBI v0.9 and above is required.

If you have installed QEMU 6.0.0+, OpenSBI v0.3 is already included.

### Build Command

```
zig build // Will build the project into build/

zig build run // Will run the kernel with qemu, must have qemu-system-riscv64 installed
```

## Feature
- [x] spinlock (2021-12-13)
- [ ] std.log and panic support
    - [x] UART Driver (2021-12-13)
    - [ ] initialize using the device tree info
- [x] migrate to OpenSBI
    - [ ] ~~console related~~ (SBI v0.1 feature, deprecated in SBI specification v0.2 and above)
    - [x] shutdown (2021-12-14)
    - [x] hardware timer setup
- [x] interrupt
    - [x] interrupt handler setup (2021-12-14)
    - [x] clock interrupt (2021-12-14)
- [ ] physical memory management
    - [x] device tree parsing (2021-12-16)
- [ ] pagetable
- [ ] proccess
- [ ] proccess scheduling
- [ ] syscall

## Development

### What can be used
- std.log
- @panic

### What can not be used
Pretty much anything else related to system.

## Credit
- [https://github.com/AndreaOrru/zen](https://github.com/AndreaOrru/zen)
- [https://github.com/rcore-os/rCore](https://github.com/rcore-os/rCore)
- [https://github.com/mit-pdos/xv6-riscv](https://github.com/mit-pdos/xv6-riscv) xv6 from MIT re-written for RISC-V

## Copyright
`src/dtb` is a project from [@kivikakk](https://github.com/kivikakk/dtb.zig), by the time the code was copied in, the project is licensed under MIT license. All right reserved for [@kivikakk](https://github.com/kivikakk).

All other files in this project are licensed under the AGPL-3.0 license.