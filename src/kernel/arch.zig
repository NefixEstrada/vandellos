const std = @import("std");
const builtin = @import("builtin");

pub const options = switch (builtin.cpu.arch) {
    .x86 => @import("arch/x86/arch.zig"),
    else => @compileError("unsupported architecture"),
};

test "test the target architecture" {
    std.testing.refAllDecls(options);
}
