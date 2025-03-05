const std = @import("std");

const arch_options = @import("arch.zig").options;
const log = @import("log.zig");

var tty = arch_options.Tty{};
const writer = tty.writer();

// Setup the global logger function
pub const std_options = std.Options{
    .logFn = log.logFn(writer.any()),
};

// Import the main entrypoints for the current architecture
usingnamespace arch_options.boot;

export fn main() void {
    tty.reset();

    std.log.info("Starting up VandellOS! :)", .{});

    arch_options.init();

    asm volatile ("int $25");
    asm volatile ("int $12");
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    @branchHint(.cold);

    _ = ret_addr;
    _ = error_return_trace;

    _ = writer.print("\nkernel panic! :(\n", .{}) catch unreachable;
    _ = writer.print("----------------\n", .{}) catch unreachable;
    _ = writer.print("{s}", .{msg}) catch unreachable;

    while (true) {}
}

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
