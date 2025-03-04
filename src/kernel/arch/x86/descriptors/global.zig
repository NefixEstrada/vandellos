/// The Global Descriptor Table is a struct responsible for managing
/// the CPU memory segmentation in the x86 architecture.
const std = @import("std");

const SEGMENT_DESCRIPTOR_EXECUTABLE = enum(u1) {
    data = 0,
    code = 1,
};

const SEGMENT_DESCRIPTOR_TYPE = enum(u1) {
    system = 0,
    code_data = 1,
};

const SEGMENT_DESCRIPTOR_PRIVILEGE = enum(u2) {
    ring_0 = 0,
    ring_1 = 1,
    ring_2 = 2,
    ring_3 = 3,
};

const SEGMENT_DESCRIPTOR_SIZE = enum(u1) {
    @"16_bits" = 0,
    @"32_bits" = 1,
};

const SEGMENT_DESCRIPTOR_GRANULARITY = enum(u1) {
    byte = 0,
    page = 1,
};

// Entry is an entry of the Global Descriptor Table
// TODO: Document more this!
const Entry = packed struct {
    const Self = @This();

    limit_low: u16,
    base_low: u16,
    base_mid: u8,
    access: packed struct {
        accessed: bool,
        read_write: bool,
        direction_conforming: bool,
        executable: SEGMENT_DESCRIPTOR_EXECUTABLE,
        descriptor_type: SEGMENT_DESCRIPTOR_TYPE,
        descriptor_privilege: SEGMENT_DESCRIPTOR_PRIVILEGE,
        // present needs to be always set to true
        present: bool = true,
    },
    limit_high: u4,
    flags: packed struct {
        // _reserved needs to always be 0
        _reserved: u1 = 0,
        long_mode: bool,
        size: SEGMENT_DESCRIPTOR_SIZE,
        granularity: SEGMENT_DESCRIPTOR_GRANULARITY,
    },
    base_high: u8,

    pub fn init(
        base: u32,
        limit: u20,
        access: std.meta.fieldInfo(Self, .access).type,
        flags: std.meta.fieldInfo(Self, .flags).type,
    ) @This() {
        return .{
            .base_low = @truncate(base),
            .base_mid = @truncate(base >> @sizeOf(std.meta.fieldInfo(Self, .base_low).type)),
            .base_high = @truncate(base >> (@sizeOf(std.meta.fieldInfo(Self, .base_low).type) + @sizeOf(std.meta.fieldInfo(Self, .base_mid).type))),
            .limit_low = @truncate(limit),
            .limit_high = @truncate(limit >> @sizeOf(std.meta.fieldInfo(Self, .limit_low).type)),
            .access = access,
            .flags = flags,
        };
    }
};

const TableRegistry = packed struct {
    limit: u16,
    offset: u32,
};

var table = [3]Entry{
    // TODO: Document what does each segment
    // Null Descriptor
    std.mem.zeroes(Entry),
    // Kernel Mode Code Segment
    Entry.init(
        // TODO: Explain why we set the base to 0
        0,
        // Set the limit to 0xffff to span the whole 4GiB
        0xffff,
        .{
            // TODO: Explain why
            .accessed = false,
            // TODO: explain why: We set the read access to true
            .read_write = true,
            // We set the conforming bit to false, since only the ring 0 will be able to
            // access this segment
            .direction_conforming = false,
            // We set the executable bit to true, since it's a code segment
            .executable = .code,
            // This is a code segment
            .descriptor_type = .code_data,
            // Since it's the kernel segment, only those with ring 0 privilege can
            // use it
            .descriptor_privilege = .ring_0,
        },
        .{
            // TODO: Explain why
            .long_mode = false,
            // TODO: Explain why
            .size = .@"32_bits",
            // TODO: Explain why
            .granularity = .page,
        },
    ),
    // Kernel Mode Data Segment
    Entry.init(
        0,
        0xffff,
        .{
            // TODO: Explain why
            .accessed = false,
            // TODO: explain why: We set the write access to true (it's write since it's a data segment)
            .read_write = true,
            // We set the conforming bit to false, since only the ring 0 will be able to
            // access this segment
            .direction_conforming = false,
            // We set the executable bit to false, since it's a data segment
            .executable = .data,
            // This is a data segment
            .descriptor_type = .code_data,
            // Since it's the kernel segment, only those with ring 0 privilege can
            // use it
            .descriptor_privilege = .ring_0,
        },
        .{
            // TODO: Explain why
            .long_mode = false,
            // TODO: Explain why
            .size = .@"32_bits",
            // TODO: Explain why
            .granularity = .page,
        },
    ),
    // // User Mode Code Segment
    // .{},
    // // User Mode Data Segment
    // .{},
    // TODO: Task segment?
};

pub fn init() void {
    const table_registry = TableRegistry{
        .limit = @sizeOf(Entry) * table.len - 1,
        .offset = @intFromPtr(&table[0]),
    };

    // Load the global descriptor table register
    asm volatile (
        \\ lgdt %[tbl_reg]
        :
        : [tbl_reg] "*p" (&table_registry),
    );
}
