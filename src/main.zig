usingnamespace @import("boot.zig");

pub fn main() void {
    var term = Terminal{};

    term.reset();
    term.write("Hola Vandellos");
}

const VGAColor = enum(u8) {
    black,
    blue,
    green,
    cyan,
    red,
    magenta,
    brown,
    light_grey,
    dark_grey,
    light_blue,
    light_green,
    light_cyan,
    light_red,
    light_magenta,
    light_brown,
    white,
};

fn vgaEntryColor(fg: VGAColor, bg: VGAColor) VGAColor {
    return @enumFromInt(@intFromEnum(fg) | (@intFromEnum(bg) << 4));
}

fn vgaEntry(uc: u8, color: VGAColor) u16 {
    return uc | @as(u16, @intFromEnum(color)) << 8;
}

pub const Terminal = struct {
    const Self = @This();

    // 0xb8000 is the address of the VGA text buffer
    pub const buffer: [*]volatile u16 = @ptrFromInt(0xb8000);

    // width is the width of the terminal
    const width: usize = 80;
    // width is the height of the terminal
    const height: usize = 25;

    // row is the current row position
    row: usize = 0,
    // column is the current column position
    column: usize = 0,
    // color is the active color
    color: VGAColor = vgaEntryColor(.light_grey, .black),

    // reset resets the screen with the active color
    fn reset(self: *Self) void {
        for (0..height) |y| {
            for (0..width) |x| {
                self.putCharAt(' ', self.color, x, y);
            }
        }
    }

    // putCharAt writes a character in a specific location with a specific color
    fn putCharAt(_: *Self, char: u8, c: VGAColor, x: usize, y: usize) void {
        const i = y * width + x;
        buffer[i] = vgaEntry(char, c);
    }

    // putChar writes a character in the next place with the current color
    fn putChar(self: *Self, char: u8) void {
        self.putCharAt(char, self.color, self.column, self.row);
        self.column += 1;

        // Check if we've reached the end of the line
        if (self.column == width) {
            self.column = 0;
            self.row += 1;

            // Check if we've reached the end of the screen
            if (self.row == height) {
                self.row = 0;
            }
        }
    }

    // write writes a slice of strings to the screen
    fn write(self: *Self, data: []const u8) void {
        for (data) |c| {
            self.putChar(c);
        }
    }
};
