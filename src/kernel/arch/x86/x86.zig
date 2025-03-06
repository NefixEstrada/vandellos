const std = @import("std");

pub const Tty = @import("tty.zig").Tty;
pub const boot = @import("boot.zig");
pub const descriptors = @import("descriptors.zig");

pub fn init() void {
    std.log.scoped(.x86).info("Setting up architecture", .{});

    descriptors.init();
}
