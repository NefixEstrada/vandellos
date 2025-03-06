const std = @import("std");

pub const SDTHeader = extern struct {
    pub const VerifyError = error{InvalidChecksum};

    signature: [4]u8,
    length: u32,
    revision: u8,
    checksum: u8,
    oem_id: [6]u8,
    oem_table_id: [8]u8,
    oem_revision: u32,
    creator_id: u32,
    creator_revision: u32,

    pub fn verify(self: @This()) VerifyError!void {
        var checksum: u8 = 0;

        // Add all sum all the bytes of the SDT, overflowing
        // the checksum calculation
        for (std.mem.asBytes(self)) |b| {
            checksum = @addWithOverflow(checksum, b)[0];
        }

        // If the checksum value doesn't end up being 0, the checksum
        // validation has failed
        if (checksum != 0) return error.InvalidChecksum;
    }
};

pub const RSDT = struct {
    // The RSDT has the following structure:
    // header -> SDTHeader
    // entries -> []*SDTHeader
    //
    // Since we cannot know how many entries there are
    // at comptime (it varies between each PC), we can only
    // store the address to the header and need to find each
    // entry at comptime
    header: *SDTHeader,
    entries: u32,

    pub fn init(header: *SDTHeader) @This() {
        return .{
            .header = header,
            .entries = (header.length - @sizeOf(SDTHeader)) / @sizeOf(u32),
        };
    }

    pub fn getEntry(self: @This(), i: usize) *SDTHeader {
        // This is the memory address after the RSDT header
        const base_addr = @intFromPtr(self.header) + @sizeOf(SDTHeader);

        // Here we use two pointers because:
        // - The first pointer is the memory address where the pointer of
        //   the header we're is located in memory (right afterwards the RSDT header)
        // - The second pointer is the address of the SDT we're searching
        const ptr: **SDTHeader = @ptrFromInt(base_addr + (i * @sizeOf(u32)));

        // We return only the pointer to the found header itself
        return ptr.*;
    }
};
