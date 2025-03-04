const std = @import("std");

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

fn vgaEntryColor(fg: VGAColor, bg: VGAColor) u16 {
    return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

fn vgaEntry(uc: u8, color: u16) u16 {
    return uc | color << 8;
}

pub const Tty = struct {
    const Self = @This();

    // 0xb8000 is the address of the VGA text buffer
    const buffer: [*]volatile u16 = @ptrFromInt(0xb8000);

    // width is the width of the terminal
    const width: usize = 80;
    // width is the height of the terminal
    const height: usize = 25;
    // row is the current row position
    row: usize = 0,
    // column is the current column position
    column: usize = 0,
    // color is the active combination of background and foreground colors
    color: u16 = vgaEntryColor(.light_brown, .red),

    // Implement std.io.Writer
    pub const WriteError = error{hello};
    pub const Writer = std.io.Writer(*Tty, WriteError, write);
    pub fn writer(self: *Self) Writer {
        return .{ .context = self };
    }

    // writeByteAt writes a byte in a specific location with a specific color
    fn writeByteAt(b: u8, color: u16, x: usize, y: usize) void {
        // Calculate the index of the buffer
        const i = y * width + x;

        // Write to the buffer
        buffer[i] = vgaEntry(b, color);
    }

    // writeByte writes a byte in the next place with the current color
    fn writeByte(self: *Self, b: u8) void {
        switch (b) {
            '\n' => self.newLine(),
            else => {
                writeByteAt(b, self.color, self.column, self.row);
                self.column += 1;

                // Check if we've reached the end of the line
                if (self.column == width) {
                    self.newLine();
                }
            },
        }
    }

    fn newLine(self: *Self) void {
        // If we are in the last row, move everything up one row
        if (self.row == height - 1) {
            // We start at 1, since the line at index 0 is going to be moved out of the buffer view
            for (1..height) |y| {
                for (0..width) |x| {
                    // Calculate the old index of the buffer
                    const oi = y * width + x;

                    // Calculate the new index of the buffer
                    const ni = (y - 1) * width + x;

                    // Move the character from the current line to the previous line (one row up)
                    buffer[ni] = buffer[oi];
                }
            }

            // Remove the last line we moved up to make room for the new line
            self.resetLine(height - 1);
        } else {
            self.row += 1;
        }

        self.column = 0;
    }

    // write writes a buffer into the Tty text buffer
    pub fn write(self: *Self, buf: []const u8) WriteError!usize {
        for (buf) |b| {
            self.writeByte(b);
        }

        return buf.len;
    }

    fn resetLine(self: *Self, y: usize) void {
        for (0..width) |x| {
            writeByteAt(' ', self.color, x, y);
        }
    }

    // reset cleans the screen with the active color
    pub fn reset(self: *Self) void {
        for (0..height) |y| {
            self.resetLine(y);
        }
    }
};
