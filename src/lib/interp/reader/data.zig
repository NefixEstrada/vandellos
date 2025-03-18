const std = @import("std");
const io = std.io;
const reader = @import("../reader.zig");
const parseOperand = reader.parseOperand;

pub const DatumType = enum(u4) {
    _invalid1 = 0b0000,
    byte = 0b0001,
    @"32_bit_word" = 0b0010,
    utf_string = 0b0011,
    real = 0b0100,
    array = 0b0101,
    set_array_address = 0b0110,
    restore_load_address = 0b0111,
    @"64_bigint" = 0b1000,
    _invalid2 = 0b1001,
    _invalid3 = 0b1010,
    _invalid4 = 0b1011,
    _invalid5 = 0b1100,
    _invalid6 = 0b1101,
    _invalid7 = 0b1110,
    _invalid8 = 0b1111,
};

pub const DataItem = struct {
    const DataItemCode = packed struct {
        data_values: u4,
        datum_type: DatumType,
    };
    const DataItemData = union(DatumType) {
        _invalid1: void,
        byte: []u8,
        @"32_bit_word": []u32,
        utf_string: []u8,
        // TODO: Ensure this is the correct
        real: f64,
        // TODO: This!
        array: void,
        // TODO: This!
        set_array_address: void,
        // TODO: This!
        restore_load_address: void,
        // TODO: This!
        @"64_bigint": void,
        _invalid2: void,
        _invalid3: void,
        _invalid4: void,
        _invalid5: void,
        _invalid6: void,
        _invalid7: void,
        _invalid8: void,
    };

    code: DataItemCode,
    count: ?u32,
    data: DataItemData,
};

pub const ParseDataSectionError = error{InvalidCount} || io.AnyReader.Error;

pub fn parseDataSection(buf: io.AnyReader) ParseDataSectionError![]DataItem {
    var data_items: [reader.MAX_SIZE]DataItem = undefined;

    var code = try buf.readStruct(DataItem.DataItemCode);
    var i: usize = 0;

    // Read until there's a 0b000_0000 byte as the control code
    while (code != std.mem.zeroes(DataItem.DataItemCode)) : (code = try buf.readStruct(DataItem.DataItemCode)) {
        defer i += 1;

        // Check if there's the count field
        const count: ?u32 = if (code.data_values == 0) blk: {
            const s = try parseOperand(buf);
            if (s < 0) return error.InvalidCount;
            break :blk @intCast(s);
        } else null;
        const num_items = count orelse code.data_values;

        std.debug.print("ITEMS NUM: {d}\n", .{num_items});

        const offset = try parseOperand(buf);
        std.debug.print("OFFSET: {d}\n", .{offset});

        const data: DataItem.DataItemData = blk: switch (code.datum_type) {
            .byte => {
                var items = std.mem.zeroes([reader.MAX_SIZE]u8);

                for (0..num_items) |j| {
                    const b = try buf.readByte();
                    std.debug.print("FOUND BYTE: {b}\n", .{b});

                    items[j] = b;
                }

                break :blk .{
                    .byte = items[0..num_items],
                };
            },
            .@"32_bit_word" => {
                var items = std.mem.zeroes([reader.MAX_SIZE]u32);

                for (0..num_items) |j| {
                    const word = try buf.readInt(u32, .big);
                    std.debug.print("FOUND WORD: {b}\n", .{word});
                    items[j] = word;
                }

                break :blk .{
                    .@"32_bit_word" = items[0..num_items],
                };
            },
            .utf_string => {
                // TODO: NULL SENTINEL?
                var str: [reader.MAX_SIZE]u8 = undefined;
                try buf.readNoEof(str[0..num_items]);
                std.debug.print("FOUND STRING: (size: {d}) '{s}: {b}'\n", .{ num_items, str[0..num_items], str[0..num_items] });
                break :blk .{
                    .utf_string = str[0..num_items],
                };
            },
            else => {
                std.debug.print("FOUND ITEM: {s}\n", .{@tagName(code.datum_type)});
                @panic("AAAAAAA");
            },
        };

        data_items[i] = .{
            .code = code,
            .count = count,
            .data = data,
        };
    }

    return data_items[0..i];
}
