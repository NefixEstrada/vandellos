// TODO: This should be CPU architecture agnostic
usingnamespace @import("arch/x86/boot.zig");

const options = @import("arch.zig").options;

export fn main() void {
    var tty = options.Tty{};

    tty.reset();
    tty.write("Hola Vandellos");
}
