const std = @import("std");
const Io = std.Io;

pub const Date = struct { year: u16, month: u8, day: u8 };

pub const Writers = struct {
    stdout_file: Io.File.Writer,
    stderr_file: Io.File.Writer,

    pub fn init(io: std.Io) Writers {
        var stdout_buf: [4096]u8 = undefined;
        const stdout_file: Io.File.Writer = .init(.stdout(), io, &stdout_buf);

        var stderr_buf: [1024]u8 = undefined;
        const stderr_file: Io.File.Writer = .init(.stderr(), io, &stderr_buf);

        return .{
            .stdout_file = stdout_file,
            .stderr_file = stderr_file,
        };
    }

    pub fn stdout(self: *Writers) *Io.Writer {
        return &self.stdout_file.interface;
    }

    pub fn stderr(self: *Writers) *Io.Writer {
        return &self.stderr_file.interface;
    }
};

pub fn splitLine(
    allocator: std.mem.Allocator,
    line: []const u8,
    delimiter: u8,
) !std.ArrayList([]const u8) {
    var fields: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (fields.items) |field| {
            allocator.free(field);
        }
        fields.deinit(allocator);
    }

    var it = std.mem.splitScalar(u8, line, delimiter);
    while (it.next()) |field| {
        const owned = try allocator.dupe(u8, field);
        try fields.append(allocator, owned);
    }

    return fields;
}

// Returns the actual date in UTC
pub fn getCurrentDate(io: std.Io) Date {
    const now = std.Io.Clock.real.now(io);
    const epoch_seconds = std.time.epoch.EpochSeconds{
        .secs = @intCast(@divTrunc(now.nanoseconds, 1_000_000_000)),
    };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    return .{
        .year = year_day.year,
        .month = @intCast(month_day.month.numeric()),
        .day = month_day.day_index + 1,
    };
}

pub fn parseDate(date_str: []const u8) !Date {
    var it = std.mem.splitScalar(u8, date_str, '-');
    const y = it.next() orelse return error.InvalidFormat;
    const m = it.next() orelse return error.InvalidFormat;
    const d = it.next() orelse return error.InvalidFormat;
    return .{
        .year = try std.fmt.parseInt(u16, y, 10),
        .month = try std.fmt.parseInt(u8, m, 10),
        .day = try std.fmt.parseInt(u8, d, 10),
    };
}

fn dateToTimestamp(date: Date) i64 {
    const epoch = std.time.epoch;
    var days: i64 = 0;
    var y: u16 = epoch.epoch_year;
    while (y < date.year) : (y += 1) {
        days += epoch.getDaysInYear(y);
    }
    var m: u4 = 1;
    while (m < date.month) : (m += 1) {
        days += epoch.getDaysInMonth(date.year, @enumFromInt(m));
    }
    days += date.day - 1;
    return days * epoch.secs_per_day;
}

pub fn daysBetween(date1: Date, date2: Date) i64 {
    const ts1 = dateToTimestamp(date1);
    const ts2 = dateToTimestamp(date2);

    // 86400 seconds in a day.
    return @divTrunc(ts2 - ts1, 86400);
}

pub const Color = struct {
    pub const Reset = "\x1b[0m";
    pub const Red = "\x1b[31m";
    pub const Green = "\x1b[32m";
    pub const Yellow = "\x1b[33m";
    pub const Cyan = "\x1b[36m";
    pub const Bold = "\x1b[1m";

    pub fn print(writer: *std.Io.Writer, color: []const u8, fmt: []const u8, args: anytype) !void {
        try writer.print(color ++ fmt ++ Reset ++ args);
    }

    pub fn red(writer: *std.Io.Writer, fmt: []const u8, args: anytype) !void {
        try print(writer, Red, fmt, args);
    }

    pub fn green(writer: *std.Io.Writer, fmt: []const u8, args: anytype) !void {
        try print(writer, Green, fmt, args);
    }

    pub fn yellow(writer: *std.Io.Writer, fmt: []const u8, args: anytype) !void {
        try print(writer, Yellow, fmt, args);
    }

    pub fn cyan(writer: *std.Io.Writer, fmt: []const u8, args: anytype) !void {
        try print(writer, Cyan, fmt, args);
    }
};
