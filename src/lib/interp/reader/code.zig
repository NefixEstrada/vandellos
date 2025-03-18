const std = @import("std");
const io = std.io;
const reader = @import("../reader.zig");
const parseOperand = reader.parseOperand;

pub const CodeInstruction = struct {
    const SourceDestData = union(enum) {
        single: i32,
        double: struct {
            first: i32,
            second: i32,
        },
    };

    opcode: Instruction,
    address_mode: AddressMode,
    middle_data: ?i32,
    source_data: ?SourceDestData,
    destination_data: ?SourceDestData,
};

const AddressMode = packed struct {
    const MiddleMode = enum(u2) {
        none = 0b00,
        small_intermediate = 0b01,
        small_offset_fp = 0b10,
        small_offset_mp = 0b11,
    };

    const SourceDestMode = enum(u3) {
        offset_mp = 0b000,
        offset_fp = 0b001,
        @"30_bits" = 0b010,
        none = 0b011,
        double_indirect_mp = 0b100,
        double_indirect_fp = 0b101,
        _reserved1 = 0b110,
        _reserved2 = 0b111,
    };

    destination: SourceDestMode,
    source: SourceDestMode,
    middle: MiddleMode,
};

const ParseCodeInstructionError = error{ InvalidOperationCode, InvalidSourceAddressMode, InvalidDestinationAddressMode } || reader.ParseOperandError;

pub fn parseCodeInstruction(buf: io.AnyReader) ParseCodeInstructionError!CodeInstruction {
    const opcode = blk: {
        const op = try buf.readByte();
        const code = std.meta.intToEnum(Instruction, op) catch |err| {
            switch (err) {
                error.InvalidEnumTag => return error.InvalidOperationCode,
            }
        };

        break :blk code;
    };

    std.debug.print("OP: {s}: \n", .{@tagName(opcode)});

    const address_mode = std.mem.bytesToValue(AddressMode, &.{try buf.readByte()});

    const middle_data: ?i32 = blk: {
        if (address_mode.middle == .none) {
            break :blk null;
        }

        break :blk try parseOperand(buf);
    };

    const source_data: ?CodeInstruction.SourceDestData = switch (address_mode.source) {
        .none => null,
        .offset_mp, .offset_fp, .@"30_bits" => .{
            .single = try parseOperand(buf),
        },
        .double_indirect_mp, .double_indirect_fp => .{
            .double = .{
                .first = try parseOperand(buf),
                .second = try parseOperand(buf),
            },
        },
        else => return error.InvalidSourceAddressMode,
    };

    const dest_data: ?CodeInstruction.SourceDestData = switch (address_mode.destination) {
        .none => null,
        .offset_mp, .offset_fp, .@"30_bits" => .{
            .single = try parseOperand(buf),
        },
        .double_indirect_mp, .double_indirect_fp => .{
            .double = .{
                .first = try parseOperand(buf),
                .second = try parseOperand(buf),
            },
        },
        else => return error.InvalidDestinationAddressMode,
    };

    return .{
        .opcode = opcode,
        .address_mode = address_mode,
        .middle_data = middle_data,
        .source_data = source_data,
        .destination_data = dest_data,
    };
}

// TODO: This!
test "parseCodeInstruction" {}

// TODO: This!
test "fuzz parseCodeInstruction" {}

pub const Instruction = enum(u8) {
    nop = 0x00,
    alt = 0x01,
    nbalt = 0x02,
    goto = 0x03,
    call = 0x04,
    frame = 0x05,
    spawn = 0x06,
    runt = 0x07,
    load = 0x08,
    mcall = 0x09,
    mspawn = 0x0a,
    mframe = 0x0b,
    ret = 0x0c,
    jmp = 0x0d,
    case = 0x0e,
    exit = 0x0f,
    new = 0x10,
    newa = 0x11,
    newcb = 0x12,
    newcw = 0x13,
    newcf = 0x14,
    newcp = 0x15,
    newcm = 0x16,
    newcmp = 0x17,
    send = 0x18,
    recv = 0x19,
    consb = 0x1a,
    consw = 0x1b,
    consp = 0x1c,
    consf = 0x1d,
    consm = 0x1e,
    consmp = 0x1f,
    headb = 0x20,
    headw = 0x21,
    headp = 0x22,
    headf = 0x23,
    headm = 0x24,
    headmp = 0x25,
    tail = 0x26,
    lea = 0x27,
    indx = 0x28,
    movp = 0x29,
    movm = 0x2a,
    movmp = 0x2b,
    movb = 0x2c,
    movw = 0x2d,
    movf = 0x2e,
    cvtbw = 0x2f,
    cvtwb = 0x30,
    cvtfw = 0x31,
    cvtwf = 0x32,
    cvtca = 0x33,
    cvtac = 0x34,
    cvtwc = 0x35,
    cvtcw = 0x36,
    cvtfc = 0x37,
    cvtcf = 0x38,
    addb = 0x39,
    addw = 0x3a,
    addf = 0x3b,
    subb = 0x3c,
    subw = 0x3d,
    subf = 0x3e,
    mulb = 0x3f,
    mulw = 0x40,
    mulf = 0x41,
    divb = 0x42,
    divw = 0x43,
    divf = 0x44,
    modw = 0x45,
    modb = 0x46,
    andb = 0x47,
    andw = 0x48,
    orb = 0x49,
    orw = 0x4a,
    xorb = 0x4b,
    xorw = 0x4c,
    shlb = 0x4d,
    shlw = 0x4e,
    shrb = 0x4f,
    shrw = 0x50,
    insc = 0x51,
    indc = 0x52,
    addc = 0x53,
    lenc = 0x54,
    lena = 0x55,
    lenl = 0x56,
    beqb = 0x57,
    bneb = 0x58,
    bltb = 0x59,
    bleb = 0x5a,
    bgtb = 0x5b,
    bgeb = 0x5c,
    beqw = 0x5d,
    bnew = 0x5e,
    bltw = 0x5f,
    blew = 0x60,
    bgtw = 0x61,
    bgew = 0x62,
    beqf = 0x63,
    bnef = 0x64,
    bltf = 0x65,
    blef = 0x66,
    bgtf = 0x67,
    bgef = 0x68,
    beqc = 0x69,
    bnec = 0x6a,
    bltc = 0x6b,
    blec = 0x6c,
    bgtc = 0x6d,
    bgec = 0x6e,
    slicea = 0x6f,
    slicela = 0x70,
    slicec = 0x71,
    indw = 0x72,
    indf = 0x73,
    indb = 0x74,
    negf = 0x75,
    movl = 0x76,
    addl = 0x77,
    subl = 0x78,
    divl = 0x79,
    modl = 0x7a,
    mull = 0x7b,
    andl = 0x7c,
    orl = 0x7d,
    xorl = 0x7e,
    shll = 0x7f,
    shrl = 0x80,
    bnel = 0x81,
    bltl = 0x82,
    blel = 0x83,
    bgtl = 0x84,
    bgel = 0x85,
    beql = 0x86,
    cvtlf = 0x87,
    cvtfl = 0x88,
    cvtlw = 0x89,
    cvtwl = 0x8a,
    cvtlc = 0x8b,
    cvtcl = 0x8c,
    headl = 0x8d,
    consl = 0x8e,
    newcl = 0x8f,
    casec = 0x90,
    indl = 0x91,
    movpc = 0x92,
    tcmp = 0x93,
    mnewz = 0x94,
    cvtrf = 0x95,
    cvtfr = 0x96,
    cvtws = 0x97,
    cvtsw = 0x98,
    lsrw = 0x99,
    lsrl = 0x9a,
    eclr = 0x9b,
    newz = 0x9c,
    newaz = 0x9d,

    // [SPEC]
    iraise = 0x9e,
    // [SPEC]
    casel = 0x9f,
    // [SPEC]
    mulx = 0xa0,
    // [SPEC]
    divx = 0xa1,
    // [SPEC]
    cvtxx = 0xa2,
    // [SPEC]
    mulx0 = 0xa3,
    // [SPEC]
    divx0 = 0xa4,
    // [SPEC]
    cvtxx0 = 0xa5,
    // [SPEC]
    mulx1 = 0xa6,
    // [SPEC]
    divx1 = 0xa7,
    // [SPEC]
    cvtxx1 = 0xa8,
    // [SPEC]
    cvtfx = 0xa9,
    // [SPEC]
    cvtxf = 0xaa,
    // [SPEC]
    iexpw = 0xab,
    // [SPEC]
    iexpl = 0xac,
    // [SPEC]
    iexpf = 0xad,
    // [SPEC]
    self = 0xae,
};

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
