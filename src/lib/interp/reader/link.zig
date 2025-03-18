const std = @import("std");
const io = std.io;
const reader = @import("../reader.zig");
const parseOperand = reader.parseOperand;

pub const LinkItem = struct {
    pc: i32,
    desc_number: i32,
    sig: i32,
    name: []u8,
};

pub const ParseLinkItemError = error{} || reader.ParseOperandError;

pub fn parseLinkItem(buf: io.AnyReader) ParseLinkItemError!LinkItem {
    const pc = try parseOperand(buf);
    const desc_number = try parseOperand(buf);
    const sig = try buf.readByte();

    var name_buf = std.mem.zeroes([reader.MAX_SIZE]u8);
    const name_size = try reader.parseUtf8(buf, &name_buf);

    return .{
        .pc = pc,
        .desc_number = desc_number,
        .sig = sig,
        .name = name_buf[0..name_size],
    };
}

// TODO: This!
test "parseLinkItem" {}

// TODO: This!
test "fuzz parseLinkItem" {}

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
