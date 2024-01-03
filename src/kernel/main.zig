const std = @import("std");
//
// TODO: This should be CPU architecture agnostic
usingnamespace @import("arch/x86/boot.zig");

const options = @import("arch.zig").options;

export fn main() void {
    var tty = options.Tty{};
    tty.reset();

    const writer = tty.writer();
    std.fmt.format(writer, "Hola VandellOS!\n:D {d}!", .{2}) catch unreachable;
}
