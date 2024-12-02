const std = @import("std");
const ArrayList = std.ArrayList;
const input = @embedFile("inputs/01.txt");

pub fn run() !void {
    std.debug.print("Day 01\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer _ = arena.deinit();

    var pairs = ArrayList(ArrayList(i32)).init(allocator);

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        var parts = std.mem.split(u8, line, " ");
        var pair = ArrayList(i32).init(allocator);

        while (parts.next()) |part| {
            if (part.len == 0) {
                continue;
            }

            try pair.append(try std.fmt.parseInt(i32, part, 10));
        }

        if (pair.items.len != 2) {
            continue;
        }
        try pairs.append(pair);
    }

    var left = try allocator.alloc(i32, pairs.items.len);
    var right = try allocator.alloc(i32, pairs.items.len);

    for (pairs.items, 0..) |pair, i| {
        left[i] = pair.items[0];
        right[i] = pair.items[1];
    }

    std.mem.sort(i32, left, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, right, {}, comptime std.sort.asc(i32));

    var sum: u32 = 0;
    for (left, right) |l, r| {
        sum += @abs(l - r);
    }

    std.debug.print("Part 1: {}\n", .{sum});

    var rightCounts = std.AutoHashMap(i32, i32).init(allocator);

    for (right) |r| {
        const value = (rightCounts.getOrPutValue(r, 0) catch unreachable).value_ptr.*;
        rightCounts.put(r, value + 1) catch unreachable;
    }

    var similarity: i32 = 0;
    for (left) |l| {
        similarity += (rightCounts.get(l) orelse 0) * l;
    }

    std.debug.print("Part 2: {}\n", .{similarity});
}
