const std = @import("std");
const rsdp = @import("acpi/rsdp.zig");

pub fn init() void {
    std.log.scoped(.acpi).info("Setting up ACPI", .{});
    rsdp.init();
}
