const std = @import("std");
const Io = std.Io;
const contador = @import("contador");
const lector = @import("reader.zig");
const utils = @import("utils.zig");

const math = std.math;

const MIN_NUMBER_OF_FIELDS = 2;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    var writers = utils.Writers.init(io);
    defer writers.stdout_file.flush() catch {};
    defer writers.stderr_file.flush() catch {};

    const args = try init.minimal.args.toSlice(arena);
    const filename = if (args.len > 1) args[1] else "input.txt";

    const lines = lector.readFileLines(arena, io, filename) catch |err| switch (err) {
        error.FileNotFound => {
            try writers.stdout().print("Error: El archivo '{s}' no existe.\n", .{filename});
            if (args.len <= 1) {
                try writers.stderr().print("Uso: {s} <filename>\n", .{args[0]});
            }
            return;
        },
        else => |e| return e,
    };

    for (lines.items) |line| {
        if (std.mem.startsWith(u8, line, "#")) continue;

        var fields = try utils.splitLine(arena, line, '|');
        defer {
            for (fields.items) |field| arena.free(field);
            fields.deinit(arena);
        }

        try printLine(&fields.items, &writers, &io);
    }
}

fn printLine(fields: *const []const []const u8, writers: *utils.Writers, io: *const std.Io) !void {
    const event = fields.*[0];
    const date = fields.*[1];
    const currentDate = utils.getCurrentDate(io.*);
    const counterExpectedParsedDate = try utils.parseDate(date);

    const daysInBetween = utils.daysBetween(currentDate, counterExpectedParsedDate);
    try utils.Color.cyan(writers.stdout(), "{s}{s}{s}", .{ utils.Color.Bold, event, utils.Color.Reset });

    //try writers.stdout().print("'{s}' in {d} days", .{ event, daysInBetween });
    // Días en verde (positivo) o rojo (negativo)
    if (daysInBetween >= 0) {
        try utils.Color.cyan(writers.stdout(), " en {d} días", .{daysInBetween});
    } else {
        if (daysInBetween == 0) {
            try utils.Color.green(writers.stdout(), " hace {d} días", .{-daysInBetween});
        } else {
            const how_many_days = @abs(daysInBetween);
            // try writers.stdout().print("\nWhat: {d},{d}\n", .{daysInBetween, how_many_days});

            if (how_many_days == 1 or how_many_days == 0) {
                try utils.Color.green(writers.stdout(), " hoy ({d}-{d}-{d})...", .{currentDate.year, currentDate.month, currentDate.day});
            } else if (how_many_days > 1 and how_many_days <= 3) {
                try utils.Color.gray(writers.stdout(), " hace {d} días", .{-daysInBetween});
            } else {
                try utils.Color.yellow(writers.stdout(), " hace {d} días", .{-daysInBetween});
            }
        }
    }
    if (fields.*.len > MIN_NUMBER_OF_FIELDS) {
        const notes = fields.*[2];
        try writers.stdout().print("\t\t... {s}\n", .{notes});
    } else {
        try writers.stdout().print("\n", .{});
    }
}
