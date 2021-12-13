# Zesty-Core

> Zesty means we embrace new technology!
>
> Zesty begins with 'Z' which implies we are using Zig

Zesty-Core is a kernel written in [Zig](https://ziglang.org/), aiming to compatible with POSIX.


## Build
**Require Zig 0.8.1 Exactly!**

Since Zig is still under development, the API of std library is not stablized, so the exact same version of Zig is required.

By 2021-12-13, the upcoming Zig 0.9.0-dev is already breaking many std API and prevent the project from building.

## Feature
- [x] std.log and panic support
- [] migrate to OpenSBI
- [] clock interrupt
- [] physical memory management
- [] pagetable
- [] proccess
- [] proccess scheduling
- [] syscall

## Development

### What can be used
- std.log

## License
AGPL v3.0