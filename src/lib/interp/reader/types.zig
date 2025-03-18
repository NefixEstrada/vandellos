const std = @import("std");
const io = std.io;
const reader = @import("../reader.zig");
const parseOperand = reader.parseOperand;

pub const TypeDescriptor = struct {
    desc_number: i32,
    size: u32,
    number_ptrs: u32,
    map: []u8,
};

const ParseTypeDescriptorError = error{ InvalidSize, InvalidNumberPtrs } || reader.ParseOperandError;

pub fn parseTypeDescriptor(buf: io.AnyReader) ParseTypeDescriptorError!TypeDescriptor {
    const desc_number = try parseOperand(buf);

    const size: u32 = blk: {
        const s = try parseOperand(buf);
        if (s < 0) return error.InvalidSize;
        break :blk @intCast(s);
    };

    const number_ptrs: u32 = blk: {
        const s = try parseOperand(buf);
        if (s < 0) return error.InvalidNumberPtrs;
        break :blk @intCast(s);
    };

    var map = std.mem.zeroes([reader.MAX_SIZE]u8);
    const read = try buf.readAtLeast(map[0..number_ptrs], number_ptrs);
    if (read != number_ptrs) {
        return error.EndOfStream;
    }

    return .{
        .desc_number = desc_number,
        .size = size,
        .number_ptrs = number_ptrs,
        .map = map[0..number_ptrs],
    };
}

// TODO: This!
test "parseTypeDescriptor" {}

// TODO: This!
test "fuzz parseTypeDescriptor" {}

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
