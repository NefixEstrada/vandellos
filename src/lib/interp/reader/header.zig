const std = @import("std");
const io = std.io;
const reader = @import("../reader.zig");
const parseOperand = reader.parseOperand;

pub const XMAGIC = 819248;
pub const SMAGIC = 923426;

pub const Header = struct {
    magic_number: i32,

    signature: ?Signature,

    runtime_flag: RuntimeFlag,

    // The stack_extent value indicates the number of bytes by which the thread stack of
    // this module should be extended in the event that procedure calls exhaust the allocated
    // stack. While stack extension is transparent to programs, increasing this value may improve
    // the efficiency of execution at the expense of using more memory.
    stack_extend: i32,
    // The code_size is a count of the number of instructions stored in the Code_section.
    code_size: u32,
    // The data_size gives the size in bytes of the module's global data, which is initialized
    // by evaluating the contents of the data section.
    data_size: u32,
    // The type_size is a count of the number of type descriptors stored in the Type_section.
    type_size: u32,
    // The link_size is a count of the number of external linkage directives stored in the Link_section.
    link_size: u32,
    // The entry_pc is an integer index into the instruction stream that is the default entry point for
    // this module. The entry_pc should point to the first instruction of a function. Instructions are numbered
    // from a program counter value of zero.
    entry_pc: i32,
    // The entry_type is the index of the type descriptor that corresponds to the function entry point set by entry_pc.
    entry_type: i32,
};

pub const Signature = struct {
    length: i32,
    signature: []u8,
};

pub const RuntimeFlag = packed struct {
    // The MUSTCOMPILE flag indicates that a load instruction should draw an error
    // if the implementation is unable to compile the module into native instructions
    // using a just-in-time compiler.
    must_compile: bool,
    // The DONTCOMPILE flag indicates that the module should not be compiled into native
    // instructions, even though it is the default for the runtime environment. This flag
    // may be set to allow debugging or to save memory.
    dont_compile: bool,
    // The SHAREMP flag indicates that each instance of the module should use the same module
    // data for all instances of the module. There is no implicit synchronization between
    // threads using the shared data.
    share_mp: bool,
    // TODO: Document all this
    // [SPEC]
    _reserved: u1,
    // [SPEC]
    has_import_deprecated: bool,
    // [SPEC]
    has_handler: bool,
    // [SPEC]
    has_import: bool,
    // [SPEC]
    builtin: bool,
};

pub const ParseHeaderError = error{
    InvalidMagic,
    InvalidRuntimeFlag,
    InvalidCodeSize,
    InvalidDataSize,
    InvalidTypeSize,
    InvalidLinkSize,
} || reader.ParseOperandError;

pub fn parseHeader(buf: io.AnyReader) ParseHeaderError!Header {
    const magic = try parseOperand(buf);
    switch (magic) {
        // The module has been cryptographically signed
        SMAGIC => {
            // TODO: Implement signature
            const signature = {
                const length = try parseOperand(buf);
                if (length < 0) @panic("AAAAAAAA");
                try buf.skipBytes(@intCast(length), .{});
            };
            _ = signature;
            std.debug.print("SIGNED!\n", .{});
        },
        XMAGIC => {},
        else => return error.InvalidMagic,
    }

    // TODO: Ensure this is working correctly
    const runtime_flag = std.mem.bytesToValue(RuntimeFlag, &.{try parseOperand(buf)});

    const stack_extend = try parseOperand(buf);
    const code_size: u32 = blk: {
        const s = try parseOperand(buf);
        std.debug.print("CODE SIZE: {d}\n", .{s});
        if (s < 0) return error.InvalidCodeSize;
        break :blk @intCast(s);
    };
    const data_size: u32 = blk: {
        const s = try parseOperand(buf);
        if (s < 0) return error.InvalidDataSize;
        break :blk @intCast(s);
    };
    const type_size: u32 = blk: {
        const s = try parseOperand(buf);
        if (s < 0) return error.InvalidTypeSize;
        break :blk @intCast(s);
    };
    const link_size: u32 = blk: {
        const s = try parseOperand(buf);
        if (s < 0) return error.InvalidLinkSize;
        break :blk @intCast(s);
    };
    const entry_pc = try parseOperand(buf);
    const entry_type = try parseOperand(buf);

    return .{
        .magic_number = magic,
        // TODO: Implement signature
        .signature = null,
        .runtime_flag = runtime_flag,
        .stack_extend = stack_extend,
        .code_size = code_size,
        .data_size = data_size,
        .type_size = type_size,
        .link_size = link_size,
        .entry_pc = entry_pc,
        .entry_type = entry_type,
    };
}

// TODO: This!
test "parseHeader" {}

// TODO: This!
test "fuzz parseHeader" {}

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
