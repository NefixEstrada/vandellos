/// RSDP (Root System Description Pointer) is a
/// datastructure used for ACPI
///
/// Depending on the ACPI version, it varies
const std = @import("std");
const log = std.log.scoped(.acpi);

const RSDP = extern struct {
    signature: [8]u8,
    checksum: u8,
    oem_id: [6]u8,
    revision: u8,
    rsdt_address: u32,
};

const XSDP = extern struct {
    usingnamespace RSDP;

    length: u32,
    xsdt_address: u64,
    extended_checksum: u8,
    _reserved: [3]u8,
};

// The RSDP has to be located between those two memory addresses
const RSDP_MEM_START = 0xe0000;
const RSDP_MEM_END = 0xfffff;
const RSDP_MEM_SIZE = RSDP_MEM_END - RSDP_MEM_START;

// RSDP magic is a magic string that needs to be located in the memory. The table
// lies within 16 bytes
const RSDP_SIGNATURE = "RSD PTR ";

const rsdp_buffer: *[RSDP_MEM_SIZE]u8 = @ptrFromInt(RSDP_MEM_START);

pub fn init() void {
    const rsdp = locateRSDP() catch |err| {
        log.err("error locating the RSDP: {s}", .{@errorName(err)});
        return;
    };

    validateRSDP(rsdp) catch |err| {
        log.err("error validating the RSDP: {s}", .{@errorName(err)});
        return;
    };
}

const LocateRSDPError = error{
    NotFound,
};

fn locateRSDP() LocateRSDPError!*RSDP {
    log.info("locating the RSDP", .{});

    var i: usize = 0;
    // We iterate every 16 bytes, since the RSDP is on a 16 byte boundary
    while (i < RSDP_MEM_SIZE) : (i += 16) {
        const rsdp: *RSDP = @ptrFromInt(RSDP_MEM_START + i);

        // Check for the signature
        if (!std.mem.eql(u8, &rsdp.signature, RSDP_SIGNATURE)) {
            continue;
        }

        // TODO: Support for XSDP
        if (rsdp.revision != 0) {
            @panic("unsupported RSDP revision");
        }

        return rsdp;
    }

    return error.NotFound;
}

const ValidateRSDPError = error{
    InvalidChecksum,
};

fn validateRSDP(rsdp: *RSDP) ValidateRSDPError!void {
    log.info("validating the RSDP: {any}", .{rsdp});

    // Verify the checksum
    var checksum: u8 = 0;

    // Add all sum all the bytes of the RSDP, overflowing
    // the checksum calculation
    for (std.mem.asBytes(rsdp)) |b| {
        checksum = @addWithOverflow(checksum, b)[0];
    }

    // If the checksum value doesn't end up being 0, the checksum
    // validation has failed
    if (checksum != 0) return error.InvalidChecksum;
}
