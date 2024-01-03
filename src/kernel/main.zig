const std = @import("std");

// TODO: This should be CPU architecture agnostic
usingnamespace @import("arch/x86/boot.zig");

const options = @import("arch.zig").options;

var tty = options.Tty{};
const writer = tty.writer();

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    @setCold(true);

    _ = ret_addr;
    _ = error_return_trace;

    _ = writer.write("kernel panic! :(\n") catch unreachable;
    _ = writer.write("----------------\n") catch unreachable;
    _ = writer.write(msg) catch unreachable;

    while (true) {}
}

export fn main() void {
    tty.reset();

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

    @panic("AAAAAAAAAAAAA");
}
