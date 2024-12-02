const std = @import("std");
const ArrayList = std.ArrayList;

const input = @embedFile("inputs/02.txt");

fn check_safe(row: []const i32, skip: ?usize) bool {
    var prev: ?i32 = null;
    var asc: ?bool = null;
    for (row, 0..) |value, i| {
        if (i == skip) continue;

        if (prev == null) {
            prev = value;
            continue;
        }

        const new_asc = value > prev.?;

        if (asc == null) {
            asc = new_asc;
        } else if (asc.? != new_asc) {
            return false;
        }

        const delta = @abs(prev.? - value);
        if (delta < 1 or delta > 3) {
            return false;
        }
        prev = value;
    }

    return true;
}

pub fn run() !void {
    std.debug.print("Day 02\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var rows = ArrayList(ArrayList(i32)).init(allocator);
    defer {
        for (rows.items) |row| {
            row.deinit();
        }
        rows.deinit();
    }

    var lines = std.mem.split(u8, input, "\n");

    while (lines.next()) |line| {
        var parts = std.mem.split(u8, line, " ");
        var row = ArrayList(i32).init(allocator);

        while (parts.next()) |part| {
            const value = try std.fmt.parseInt(i32, part, 10);
            try row.append(value);
        }

        try rows.append(row);
    }

    var safe: u32 = 0;
    for (rows.items) |row| {
        if (check_safe(row.items, null)) {
            safe += 1;
        }
    }

    std.debug.print("Part 1: {}\n", .{safe});

    safe = 0;
    for (rows.items) |row| {
        if (check_safe(row.items, null)) {
            safe += 1;
            continue;
        }

        for (0..row.items.len) |i| {
            if (check_safe(row.items, i)) {
                safe += 1;
                break;
            }
        }
    }

    std.debug.print("Part 2: {}\n", .{safe});
}
