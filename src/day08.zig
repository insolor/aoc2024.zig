const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;

const input = @embedFile("inputs/08.txt");

fn loadData(allocator: std.mem.Allocator) !ArrayList([]const u8) {
    var lines = std.mem.splitSequence(u8, input, "\n");

    var result = ArrayList([]const u8).init(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        print("{s}\n", .{line});
        try result.append(line);
    }

    return result;
}

const Position = struct { x: isize, y: isize };

fn addNodes(data: ArrayList([]const u8), nodes: *AutoHashMap(u8, ArrayList(Position)), allocator: Allocator) !void {
    for (data.items, 0..) |row, i| {
        for (row, 0..) |char, j| {
            if (char == '.') {
                continue;
            }

            const maybe_entry = nodes.getEntry(char);
            if (maybe_entry) |entry| {
                try entry.value_ptr.append(.{ .x = @intCast(j), .y = @intCast(i) });
            } else {
                var list = ArrayList(Position).init(allocator);
                try list.append(.{ .x = @intCast(j), .y = @intCast(i) });
                try nodes.put(char, list);
            }
        }
    }
}

fn freeNodes(nodes: *AutoHashMap(u8, ArrayList(Position))) void {
    var value_iterator = nodes.valueIterator();
    while (value_iterator.next()) |positions| {
        positions.deinit();
    }
    nodes.deinit();
}

fn printField(data: ArrayList([]const u8)) void {
    for (data.items) |row| {
        print("{s}\n", .{row});
    }
}

fn printNodes(nodes: AutoHashMap(u8, ArrayList(Position))) void {
    var entry_iterator = nodes.iterator();
    while (entry_iterator.next()) |entry| {
        print("{c}: {any}\n", .{ entry.key_ptr.*, entry.value_ptr.*.items });
    }
}

fn part1(data: ArrayList([]const u8), allocator: Allocator) !void {
    var nodes = AutoHashMap(u8, ArrayList(Position)).init(allocator);
    defer freeNodes(&nodes);

    try addNodes(data, &nodes, std.heap.page_allocator);

    printNodes(nodes);

    const result = 0;
    print("Part 1: {d}\n", .{result});
}

fn part2() !void {}

pub fn main() !void {
    print("Day 08\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer data.deinit();

    try part1(data, allocator);
    try part2();
}
