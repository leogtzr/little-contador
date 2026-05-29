const std = @import("std");
const Io = std.Io;

// Read a file line by line and returns all the lines as a owned slice.
pub fn readFileLines(allocator: std.mem.Allocator, io: std.Io, filename: []const u8) !std.ArrayList([]const u8) {
    const file = try std.Io.Dir.cwd().openFile(io, filename, .{});
    defer file.close(io);

    var lines: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit(allocator);
    }

    var buffer: [4096]u8 = undefined;
    var file_reader: Io.File.Reader = .init(file, io, &buffer);
    const reader = &file_reader.interface;

    while (true) {
        const maybe_line = try reader.takeDelimiter('\n');

        if (maybe_line) |line| {
            const owned_line = try allocator.dupe(u8, line);
            try lines.append(allocator, owned_line);
        } else {
            break;
        }
    }

    return lines;
}
