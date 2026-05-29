const std = @import("std");
const Io = std.Io;
const contador = @import("contador");
const lector = @import("reader.zig");
const utils = @import("utils.zig");
pub fn main(init: std.process.Init) !void {
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const arena = init.arena.allocator();
    const io = init.io;
    var writers = utils.Writers.init(io);
    defer writers.stdout_file.flush() catch {};
    defer writers.stderr_file.flush() catch {};

    const args = try init.minimal.args.toSlice(arena);
    const filename = if (args.len > 1) args[1] else "ejemplo.txt";

    // const lines = try lector.readFileLines(arena, io, filename);
    const lines = lector.readFileLines(arena, io, filename) catch |err| switch (err) {
        error.FileNotFound => {
            // writers.stderr.print(comptime fmt: []const u8, args: anytype)
            try writers.stdout().print("Error: El archivo '{s}' no existe.\n", .{filename});
            if (args.len <= 1) {
                try writers.stderr().print("Uso: {s} <filename>\n", .{args[0]});
            }
            return;
        },
        else => |e| return e,
    };

    // Ahora tienes las líneas por separado en lines.items
    // std.debug.print("Se leyeron {d} líneas del archivo '{s}'\n", .{
    //     lines.items.len,
    //     filename,
    // });

    for (lines.items) |line| {
        // std.debug.print("Línea {d}: '{s}'\n", .{ i, line });

        var fields = try utils.splitLine(arena, line, '|');
        defer {
            for (fields.items) |field| arena.free(field);
            fields.deinit(arena);
        }

        try writers.stdout().print("Linea: '{s}'\n", .{line});

        const date = fields.items[1];
        const currentDate = utils.getCurrentDate(io);
        const counterExpectedParsedDate = try utils.parseDate(date);

        const daysInBetween = utils.daysBetween(counterExpectedParsedDate, currentDate);

        try writers.stdout().print("The date is: {s}, from now: {d}\n", .{ date, daysInBetween });

        for (fields.items) |field| {
            try writers.stdout().print("f{{{s}}}\n\t", .{field});
        }
    }
}
