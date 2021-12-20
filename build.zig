const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {

    // RiscV-64 freestanding target

    // Work around to eliminate 'D' feature, see https://github.com/ziglang/zig/issues/9760
    var sub_set = std.Target.Cpu.Feature.Set.empty;
    const d: std.Target.riscv.Feature = .d;
    sub_set.addFeature(@enumToInt(d));
    const target = std.zig.CrossTarget{
        .cpu_arch = std.Target.Cpu.Arch.riscv64,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
        .cpu_features_sub = sub_set,
    };

    const mode = b.standardReleaseOptions();

    // Kernel
    const kernel = b.addExecutable("zesty-core", "src/main.zig");
    kernel.addAssemblyFile("src/arch/riscv64/_start.S");
    kernel.addAssemblyFile("src/arch/riscv64/handler.S");
    kernel.setTarget(target);
    kernel.setOutputDir("build/");
    kernel.setBuildMode(mode);
    kernel.setLinkerScriptPath("src/arch/riscv64/linker.ld");

    // Work around for https://www.sifive.com/blog/all-aboard-part-4-risc-v-code-models
    // see https://github.com/ziglang/zig/issues/5558
    kernel.code_model = .medium;

    b.default_step.dependOn(&kernel.step);

    // QEMU
    const qemu_params = [_][]const u8{
        "qemu-system-riscv64",
        "-machine",
        "virt",
        "-nographic",
        "-bios",
        "default",
        "-smp",
        "4", // CPUS
        "-kernel",
        kernel.getOutputPath(),
        "-m",
        "128M",
    };

    const qemu = b.addSystemCommand(&qemu_params);
    qemu.step.dependOn(b.default_step);
    const run_step = b.step("run", "Run the kernel with QEMU");
    run_step.dependOn(&qemu.step);
}
