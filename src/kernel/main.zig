const std = @import("std");
//
// TODO: This should be CPU architecture agnostic
usingnamespace @import("arch/x86/boot.zig");

const options = @import("arch.zig").options;

export fn main() void {
    var tty = options.Tty{};
    tty.reset();

    const writer = tty.writer();

    const msg =
        \\Hola VandellOS! 1
        \\Hola VandellOS! 2
        \\Hola VandellOS! 3
        \\Hola VandellOS! 4
        \\Hola VandellOS! 5
        \\Hola VandellOS! 6
        \\Hola VandellOS! 7
        \\Hola VandellOS! 8
        \\Hola VandellOS! 9
        \\Hola VandellOS! 10
        \\Hola VandellOS! 11
        \\Hola VandellOS! 12
        \\Hola VandellOS! 13
    ;
    writer.print(msg, .{}) catch unreachable;
    writer.print("\n", .{}) catch unreachable;
    writer.print(msg, .{}) catch unreachable;
    writer.print("\n", .{}) catch unreachable;
}
