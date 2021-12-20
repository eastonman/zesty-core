# Zesty-Core

> Zesty means we embrace new technology!
>
> Zesty begins with 'Z', which implies we are using Zig

[![Zig Build Test](https://github.com/eastonman/zesty-core/actions/workflows/main.yml/badge.svg)](https://github.com/eastonman/zesty-core/actions/workflows/main.yml)

Zesty-Core is a [RISC-V](https://riscv.org/) kernel written in [Zig](https://ziglang.org/), aiming to be compatible with [POSIX](https://docs.oracle.com/cd/E19048-01/chorus4/806-3328/6jcg1bm05/index.html) (may not be accomplished).


Currently can only run on QEMU with `-machine virt`

## Feature
It currently only have kernel, and only print out some naive strings every second.

It currently don't have any syscall support, and also no userspace development support.

It just don't have userspace!

Hopefully by the time some of the system call is implemented, userspace development can simply use any libc implemention.

## Build

### Requirements

- Zig==0.8.1
- OpenSBI>=0.9

**Require Zig 0.8.1 Exactly!**

Since Zig is still under development, the API of std library is not stablized, so the exact same version of Zig is required.

By 2021-12-13, the upcoming Zig 0.9.0 is already breaking many std API and prevent the project from building.

Zig 0.9.0 is comming soon, and of course `Zesty-Core` is planning to migrate to Zig 0.9.0.

Some SBI feature used in the kernel is in SBI v0.3, So OpenSBI v0.9 and above is required.

If you have installed QEMU 6.0.0+, OpenSBI v0.3 is already included.

### Build Command

Currently, this project is tested against:
- QEMU 6.2.0 
- GCC 10.2 with target riscv64-unknown-elf
- QEMU -machine virt

```
zig build // Will build the project into build/

zig build run // Will run the kernel with qemu, must have qemu-system-riscv64 installed
```

## RoadMap
- [x] spinlock (2021-12-13)
- [ ] std.log and panic support
    - [x] UART Driver (2021-12-13)
    - [ ] initialize using the device tree info
- [x] migrate to OpenSBI (see [SBI](docs/SBI.md) in this project)
    - [ ] ~~console related~~ (SBI v0.1 feature, deprecated in SBI specification v0.2 and above)
    - [x] shutdown (2021-12-14)
    - [x] hardware timer setup
- [ ] interrupt
    - [x] interrupt handler setup (2021-12-14)
    - [x] clock interrupt (2021-12-14)
    - [ ] other interrupt handlers
- [ ] physical memory management
    - [x] device tree parsing (2021-12-16)
    - [x] xv6 alike linklist management (2021-12-16)
    - [x] buddy allocator (2021-12-20)
    - [ ] std.mem.GerneralPurposeAllocator
    - [ ] 2-stage initial
- [ ] pagetable
    - [x] initial stage kernel pagetable (2021-12-18)
    - [x] enable paging (2021-12-18)
    - [ ] KPTI, **K**ernel **P**age-**T**able **I**solation
    - [ ] user page table
- [ ] proccess
    - [ ] process structure
    - [ ] context switching
    - [ ] hart status management
    - [ ] smp env setup
- [ ] proccess scheduling
    - [ ] clock interrupt scheduling
    - [ ] schedule() function
- [ ] syscall
    - [ ] fork
    - [ ] write

## Development

### Environment

Tools required:
- riscv-gnu-toolchain
- qemu (build with riscv64)

#### GNU toolchain
Clone

```
$ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
```

Install

```
$ cd riscv-gnu-toolchain
$ sudo ./configure --prefix=/usr/local
$ sudo make
```

notice: this will install the toolchain into /usr/local, you can change to install location as you wish, but you will need to add it to you `$PATH` mannually.

#### QEMU

Download, at least QEMU 6.0.0 is required

```
$ wget https://download.qemu.org/qemu-6.2.0.tar.xz
$ tar xf qemu-6.2.0.tar.xz
```

Install

```
$ cd qemu-6.2.0
$ sudo ./configure --disable-kvm --disable-werror --prefix=/usr/local --target-list="riscv64-softmmu"
$ sudo make
$ sudo make install
```

#### Check Installation
```
$ riscv64-unknown-elf-gcc --version
riscv64-unknown-elf-gcc (GCC) 10.2.0
...

$ qemu-system-riscv64 --version
QEMU emulator version 6.2.0
```

#### How to exit QEMU
Ctrl+A and then x, this will terminate QEMU.


### What can be used
- std.log
- @panic
- Some architecture independent datastructure container

### What can not be used
Pretty much anything else related to system.

## Credit
- [https://github.com/AndreaOrru/zen](https://github.com/AndreaOrru/zen)
- [https://github.com/rcore-os/rCore](https://github.com/rcore-os/rCore)
- [https://github.com/mit-pdos/xv6-riscv](https://github.com/mit-pdos/xv6-riscv) xv6 from MIT re-written for RISC-V

## Copyright
`src/dtb` is a project from [@kivikakk](https://github.com/kivikakk/dtb.zig), by the time the code was copied in, the project is licensed under MIT license. All right reserved for [@kivikakk](https://github.com/kivikakk).

All other files in this project are licensed under the AGPL-3.0 license.