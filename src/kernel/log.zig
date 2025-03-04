const std = @import("std");

pub fn logFn(writer: std.io.AnyWriter) fn (
    comptime std.log.Level,
    comptime @TypeOf(.enum_literal),
    comptime []const u8,
    args: anytype,
) void {
    return struct {
        fn logFn(
            comptime level: std.log.Level,
            comptime scope: @TypeOf(.enum_literal),
            comptime format: []const u8,
            args: anytype,
        ) void {
            const scope_prefix = switch (scope) {
                std.log.default_log_scope => "",
                else => "(" ++ @tagName(scope) ++ "): ",
            };

            const prefix = "[" ++ comptime level.asText() ++ "] " ++ scope_prefix;
            writer.print(prefix ++ format ++ "\n", args) catch return;
        }
    }.logFn;
}

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
