const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = std.zig.CrossTarget{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
        .abi = .none,
    };

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "vandellos",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.setLinkerScript(.{ .path = b.pathFromRoot("./src/linker.ld") });

    // Add Multiboot2 headers
    // const grub2_dep = b.dependency("grub2", .{});
    // const grub2_elf = b.addTranslateC(.{
    //     .source_file = grub2_dep.path("include/grub/elf.h"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // grub2_elf.addIncludeDir(grub2_dep.path("include/").getPath(b));
    // const grub2_multiboot = b.addTranslateC(.{
    //     .source_file = grub2_dep.path("include/multiboot.h"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // grub2_multiboot.step.dependOn(&grub2_elf.step);

    // exe.addModule("grub2", grub2_multiboot.createModule());

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // Verify Multiboot
    const verify_multiboot = b.addSystemCommand(&.{ "grub-file", "--is-x86-multiboot" });
    verify_multiboot.addArtifactArg(exe);
    verify_multiboot.step.dependOn(b.getInstallStep());

    const verify_multiboot_step = b.step("verify-multiboot", "Verify the binary is Multiboot compatible");
    verify_multiboot_step.dependOn(&verify_multiboot.step);

    // Make ISO
    // b.installFile("grub.cfg", "grub/grub.cfg");
    // const iso = b.addSystemCommand(&.{"true"});
    // // const iso = b.addSystemCommand(&.{ "grub-mkrescue", "-o", "AAA.iso", "" });
    // // iso.addArtifactArg(exe);
    // iso.step.dependOn(&verify_multiboot.step);

    // const iso_step = b.step("iso", "Generate an ISO, ready to be booted!");
    // iso_step.dependOn(&iso.step);

    // Boot
    const boot = b.addSystemCommand(&.{ "qemu-system-i386", "-s", "-S", "-kernel" });
    boot.addArtifactArg(exe);
    boot.step.dependOn(&verify_multiboot.step);

    const boot_step = b.step("boot", "Boot to the build Kernel using QEMU");
    boot_step.dependOn(&boot.step);

    // Debug
    const debug = b.addSystemCommand(&.{ "gdb", "--eval-command='target remote localhost:1234'", "--eval-command='echo hello\n'" });
    debug.addArtifactArg(exe);
    debug.step.dependOn(&verify_multiboot.step);

    const debug_step = b.step("debug", "Attach to a running QEMU machine using GDB");
    debug_step.dependOn(&debug.step);
}
