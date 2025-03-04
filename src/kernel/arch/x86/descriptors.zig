pub const global = @import("descriptors/global.zig");
pub const interrupt = @import("descriptors/interrupt.zig");

pub fn init() void {
    global.init();
    interrupt.init();
}
