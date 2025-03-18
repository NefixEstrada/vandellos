const std = @import("std");
const reader = @import("reader.zig");

test "refAlDecls" {
    std.testing.refAllDecls(@This());
    _ = reader;
}
