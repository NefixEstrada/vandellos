const std = @import("std");
const log = std.log.scoped(.acpi);
const rsdp = @import("acpi/rsdp.zig");
const rsdt = @import("acpi/rsdt.zig");

pub fn init() void {
    log.info("Setting up ACPI", .{});

    const dp = rsdp.init() orelse {
        log.warn("No ACPI found", .{});
        return;
    };

    const table = rsdt.RSDT.init(dp.rsdt_address);
    _ = table;
}
