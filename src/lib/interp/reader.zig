const std = @import("std");
const io = std.io;
const header = @import("./reader/header.zig");
const code = @import("./reader/code.zig");
// TODO: Change this name
const types = @import("./reader/types.zig");
const link = @import("./reader/link.zig");
const data = @import("./reader/data.zig");

// TODO: Figure out max size
pub const MAX_SIZE = 4096;

pub const ObjectFile = struct {
    header: header.Header,
    code_section: []code.CodeInstruction,
    type_section: []types.TypeDescriptor,
    // data_section
    module_name: []u8,
    link_section: []link.LinkItem,
};

// TODO: Handle all errors (check all functions that error declarations are correct)
const ParseObjectFileError = error{} || header.ParseHeaderError;

pub fn parseObjectFile(buf: io.AnyReader) ParseObjectFileError!ObjectFile {
    const h = try header.parseHeader(buf);

    std.debug.print("{any}\n", .{h});

    var code_section = std.mem.zeroes([MAX_SIZE]code.CodeInstruction);
    for (0..h.code_size) |i| {
        std.debug.print("CODE #{d}\n", .{i});
        const instr = try code.parseCodeInstruction(buf);
        code_section[i] = instr;
    }

    var type_section = std.mem.zeroes([MAX_SIZE]types.TypeDescriptor);
    for (0..h.type_size) |i| {
        std.debug.print("TYPE #{d}\n", .{i});
        type_section[i] = try types.parseTypeDescriptor(buf);
    }

    _ = try data.parseDataSection(buf);

    // _ = try data.parseDataItem(buf);

    var module_name_buf = std.mem.zeroes([MAX_SIZE]u8);
    const module_name_size = try parseUtf8(buf, &module_name_buf);

    var link_section = std.mem.zeroes([MAX_SIZE]link.LinkItem);
    for (0..h.link_size) |i| {
        link_section[i] = try link.parseLinkItem(buf);
    }

    return .{
        .header = h,
        .code_section = code_section[0..h.code_size],
        .type_section = type_section[0..h.type_size],
        .module_name = module_name_buf[0..module_name_size],
        .link_section = link_section[0..h.link_size],
    };
}

// TODO: This!
test "parseObjectFile" {
    const pwd = @embedFile("./reader/testdata/hello.dis");
    var stream = io.fixedBufferStream(pwd);
    const object = try parseObjectFile(stream.reader().any());

    std.debug.print("{any}\n", .{object});
    std.debug.print("MODULE NAME: {s}\n", .{object.module_name});
}

// TODO: This!
test "fuzz parseObjectFile" {}

pub const ParseOperandError = io.AnyReader.Error;

pub fn parseOperand(buf: io.AnyReader) ParseOperandError!i32 {
    // Get the first byte
    const b = try buf.readByte();

    // Get the 2 most significant bits to check in how
    // many bytes is the integer represented
    const enc = b >> 6;

    // Negative numbers have all the bits in the i32 flipped (set as 1)
    switch (enc) {
        // 7 signed bits, 1 byte
        // The 7th bit indicates the sign (positive / negative)
        0b00 => return b,
        // 7 signed bits, 1 byte
        // The 7th bit indicates the sign (positive / negative)
        0b01 => return b | ~@as(i32, 0b0111_1111),
        // 0b10 => 14 signed bits, 2 bytes
        // 0b11 => 30 signed bits, 4 bytes
        0b10, 0b11 => {
            var result: i32 = b;

            // The 6th bit indicates the integer sign (positive / negative)
            if (b & 0b0010_0000 != 0) {
                // Since it's a negative integer, we need to flip
                // all the bits in the i32 first
                result |= ~@as(i32, 0b0011_1111);
            } else {
                // If it's a positive integer, grab only the relevant bits, ignoring
                // the encoding ones
                result &= 0b0011_1111;
            }

            // Since we've already figured out the first byte, read
            // the remaining bytes, that will be added to the result
            // "as is"
            const remaining_bytes: u8 = if (enc == 0b10) 1 else 3;
            for (0..remaining_bytes) |_| {
                result = result << 8 | try buf.readByte();
            }

            return result;
        },
        // This branch is unreachable, since we've handled all the 4 possible bits
        else => unreachable,
    }
}

test "parseOperand" {
    const cases = [_]struct {
        buf: []const u8,
        expected: i32,
    }{
        // 1 byte, positive
        .{
            .buf = &.{0b0000_0010},
            .expected = 2,
        },
        // 1 byte, negative
        .{
            .buf = &.{0b0100_0010},
            .expected = -62,
        },
        // 2 bytes, positive
        .{
            .buf = &.{ 0b1000_0010, 0b1111_1010 },
            .expected = 762,
        },
        // 2 bytes, negative
        .{
            .buf = &.{ 0b1010_0010, 0b1111_1010 },
            .expected = -7430,
        },
        // 4 bytes, positive
        .{
            .buf = &.{ 0b1100_0010, 0b1111_1010, 0b1010_0010, 0b1100_1100 },
            .expected = 49980108,
        },
        // 4 bytes, negative
        .{
            .buf = &.{ 0b1110_0010, 0b1111_1010, 0b1010_0010, 0b1100_1100 },
            .expected = -486890804,
        },
    };

    for (cases) |tc| {
        var buf = std.io.fixedBufferStream(tc.buf);
        const res = try parseOperand(buf.reader().any());
        try std.testing.expectEqual(tc.expected, res);
    }
}

test "fuzz parseOperand" {}

pub const ParseUtf8Error = error{} || io.AnyReader.Error;

pub fn parseUtf8(buf: io.AnyReader, dst: []u8) ParseUtf8Error!usize {
    var stream = io.fixedBufferStream(dst);
    try buf.streamUntilDelimiter(stream.writer(), 0, null);

    return stream.pos;
}

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
