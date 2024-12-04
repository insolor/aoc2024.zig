const std = @import("std");

const ArrayList = std.ArrayList;

fn loadData(filename: []const u8, allocator: std.mem.Allocator) !ArrayList([]const u8) {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();
    var line = ArrayList(u8).init(allocator);
    defer line.deinit();

    var data = ArrayList([]const u8).init(allocator);

    const writer = line.writer();
    while (reader.streamUntilDelimiter(writer, '\n', null)) {
        defer line.clearRetainingCapacity();

        if (line.items.len == 0) {
            continue;
        }
        try data.append(try allocator.dupe(u8, line.items));
    } else |err| switch (err) {
        error.EndOfStream => {
            if (line.items.len > 0) {
                try data.append(try allocator.dupe(u8, line.items));
            }
        },
        else => return err,
    }

    return data;
}

fn checkHorizontal(row: []const u8, string: []const u8) usize {
    return if (std.mem.startsWith(u8, row, string)) 1 else 0;
}

fn checkVertical(data: []const []const u8, string: []const u8, column: usize) usize {
    if (string.len > data.len) {
        return 0;
    }

    for (string, 0..) |char, i| {
        const row = data[i];
        if (row[column] != char) {
            return 0;
        }
    }
    return 1;
}

fn checkRightDownDiagonal(data: []const []const u8, string: []const u8, column: usize) usize {
    if (string.len > data.len) {
        return 0;
    }

    for (string, 0..) |char, i| {
        const row = data[i];
        if (column + i >= row.len) {
            return 0;
        }
        if (row[column + i] != char) {
            return 0;
        }
    }
    return 1;
}

fn checkLeftDownDiagonal(data: []const []const u8, string: []const u8, column: usize) usize {
    if (string.len > data.len) {
        return 0;
    }

    for (string, 0..) |char, i| {
        const row = data[i];
        if (column < i) {
            return 0;
        }
        if (row[column - i] != char) {
            return 0;
        }
    }
    return 1;
}

fn fullCount(data: []const []const u8, string: []const u8) usize {
    var count: usize = 0;
    for (data, 0..) |row, i| {
        for (row, 0..) |char, j| {
            if (char == string[0]) {
                count += checkHorizontal(row[j..], string);
                count += checkVertical(data[i..], string, j);
                count += checkRightDownDiagonal(data[i..], string, j);
                count += checkLeftDownDiagonal(data[i..], string, j);
            }
        }
    }
    return count;
}

fn part1() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData("src/inputs/04.txt", allocator);
    defer {
        for (data.items) |row| {
            allocator.free(row);
        }
        data.deinit();
    }

    const count = fullCount(data.items, "XMAS") + fullCount(data.items, "SAMX");
    std.debug.print("Part 1: {d}\n", .{count});
}

fn checkXmas(data: []const []const u8, row: usize, column: usize) usize {
    if (row + 2 >= data.len) {
        return 0;
    }

    if (column + 2 >= data[row].len) {
        return 0;
    }

    var diag: [3]u8 = undefined;
    for (diag, 0..) |_, i| {
        diag[i] = data[row + i][column + i];
    }

    if (!std.mem.eql(u8, &diag, "MAS") and !std.mem.eql(u8, &diag, "SAM")) {
        return 0;
    }

    for (diag, 0..) |_, i| {
        diag[i] = data[row + i][column + 2 - i];
    }

    if (!std.mem.eql(u8, &diag, "MAS") and !std.mem.eql(u8, &diag, "SAM")) {
        return 0;
    }

    return 1;
}

fn part2() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData("src/inputs/04.txt", allocator);
    defer {
        for (data.items) |row| {
            allocator.free(row);
        }
        data.deinit();
    }

    var count: usize = 0;
    for (data.items, 0..) |row, i| {
        for (row, 0..) |_, j| {
            if (data.items[i][j] == 'M' or data.items[i][j] == 'S') {
                count += checkXmas(data.items, i, j);
            }
        }
    }
    std.debug.print("Part 2: {d}\n", .{count});
}

pub fn run() !void {
    std.debug.print("Day 04\n", .{});
    try part1();
    try part2();
}
