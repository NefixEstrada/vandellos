const std = @import("std");

//
// These are I/O helpers for x86
//

// outb writes a value in a port
pub fn outb(port: u16, val: u8) void {
    asm volatile (
        \\ outb %[val], %[port]
        :
        : [val] "{al}" (val),
          [port] "N{dx}" (port),
        : "memory"
    );
}

// inb reads a value from a port
pub fn inb(port: u16) u8 {
    return asm volatile (
        \\ inb %[port], %[ret]
        : [ret] "={al}" (-> u8),
        : [port] "N{dx}" (port),
        : "memory"
    );
}

// TODO: Document this!
pub fn ioWait() void {
    outb(0x80, 0);
}

pub fn structAsByte(s: anytype) u8 {
    comptime {
        const size = @sizeOf(@TypeOf(s));
        if (size != @sizeOf(u8)) {
            @compileError(std.fmt.comptimePrint("struct doesn't have a size of 1 byte, has {d}", .{size}));
        }
    }

    return std.mem.asBytes(&s)[0];
}
