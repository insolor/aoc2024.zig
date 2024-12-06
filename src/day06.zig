const std = @import("std");
const print = std.debug.print;

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const input = @embedFile("inputs/06.txt");

fn loadData(allocator: std.mem.Allocator) !ArrayList([]const u8) {
    var result = ArrayList([]const u8).init(allocator);

    var lines = std.mem.splitSequence(u8, input, "\n");
    while (lines.next()) |line| {
        try result.append(line);
    }

    return result;
}

const Position = struct { x: isize, y: isize };

const Direction = enum {
    north,
    south,
    east,
    west,

    fn turn(self: Direction) Direction {
        return switch (self) {
            .north => .east,
            .east => .south,
            .south => .west,
            .west => .north,
        };
    }

    fn step(self: Direction, position: Position) Position {
        return switch (self) {
            .north => .{ .x = position.x, .y = position.y - 1 },
            .south => .{ .x = position.x, .y = position.y + 1 },
            .west => .{ .x = position.x - 1, .y = position.y },
            .east => .{ .x = position.x + 1, .y = position.y },
        };
    }
};

fn findStart(data: []const []const u8) Position {
    for (data, 0..) |row, y| {
        for (row, 0..) |char, x| {
            if (char == '^') {
                return .{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
    }
    unreachable;
}

fn outOfBounds(position: Position, data: []const []const u8) bool {
    return position.x < 0 or position.y < 0 or position.x >= data[0].len or position.y >= data.len;
}

fn printVisited(visited: AutoHashMap(Position, void)) void {
    var iterator = visited.keyIterator();
    while (iterator.next()) |position| {
        print("{}\n", .{position});
    }
}

fn part1(data: []const []const u8, allocator: std.mem.Allocator) !void {
    var position = findStart(data);
    var direction = Direction.north;

    var visited = AutoHashMap(Position, void).init(allocator);
    defer visited.deinit();

    while (true) {
        try visited.put(position, {});
        print("direction: {}\n", .{direction});
        print("position: {}\n", .{position});
        // printVisited(visited);
        var newPosition: Position = direction.step(position);
        if (outOfBounds(newPosition, data)) {
            break;
        }
        print("ahead: {c}\n", .{data[@intCast(newPosition.y)][@intCast(newPosition.x)]});
        while (data[@intCast(newPosition.y)][@intCast(newPosition.x)] == '#') {
            print("turning\n", .{});
            direction = direction.turn();
            newPosition = direction.step(position);
            print("direction: {}\n", .{direction});
            print("ahead: {c}\n", .{data[@intCast(newPosition.y)][@intCast(newPosition.x)]});
        }
        position = newPosition;
        print("\n", .{});
    }

    print("Part 1: {}\n", .{visited.count()});
}

fn part2(data: []const []const u8) !void {
    _ = data;

    print("Part 2\n", .{});
}

pub fn run() !void {
    print("Day 06\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer data.deinit();

    try part1(data.items, allocator);
    try part2(data.items);

    print("\n", .{});
}
