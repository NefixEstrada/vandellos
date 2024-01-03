const builtin = @import("std").builtin;
const main = @import("main.zig");

const MultiBootHeaderFlag = enum(u8) {
    @"align" = 1 << 0,
    meminfo = 1 << 1,
};

const MultiBootHeader = extern struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};

export const multiboot align(4) linksection(".multiboot") = boot: {
    var h = MultiBootHeader{
        .magic = 0x1badb002,
        .flags = @intFromEnum(MultiBootHeaderFlag.@"align") | @intFromEnum(MultiBootHeaderFlag.meminfo),
        .checksum = 0,
    };
    h.checksum = -(h.magic + h.flags);

    break :boot h;
};

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

export fn _main() noreturn {
    asm volatile (
        \\ movl %[stk], %esp
        \\ movl %esp, %ebp
        :
        : [stk] "{ecx}" (@intFromPtr(&stack_bytes) + @sizeOf(@TypeOf(stack_bytes))),
    );

    @call(.auto, main.main, .{});

    while (true) {}
}
