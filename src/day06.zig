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

fn findStart(data: []const []const u8) ?Position {
    for (data, 0..) |row, y| {
        for (row, 0..) |char, x| {
            if (char == '^') {
                return .{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
    }
    return null;
}

fn outOfBounds(position: Position, data: []const []const u8) bool {
    return position.x < 0 or position.y < 0 or position.x >= data[0].len or position.y >= data.len;
}

const State = struct { position: Position, direction: Direction };

const Iterator = struct {
    field: []const []const u8,
    position: Position,
    direction: Direction = .north,

    fn next(self: *Iterator) ?State {
        var new_position: Position = self.direction.step(self.position);
        if (outOfBounds(new_position, self.field)) {
            return null;
        }
        while (self.field[@intCast(new_position.y)][@intCast(new_position.x)] == '#') {
            self.direction = self.direction.turn();
            new_position = self.direction.step(self.position);
        }
        self.position = new_position;
        return .{ .position = self.position, .direction = self.direction };
    }
};

fn part1(data: []const []const u8, allocator: std.mem.Allocator) !void {
    var visited = AutoHashMap(Position, void).init(allocator);
    defer visited.deinit();

    var iterator = Iterator{
        .field = data,
        .position = findStart(data) orelse unreachable,
    };
    while (iterator.next()) |it| {
        try visited.put(it.position, {});
    }

    print("Part 1: {}\n", .{visited.count()});
}

fn createFieldCopy(data: []const []const u8, allocator: std.mem.Allocator) ![][]u8 {
    const field_copy = try allocator.alloc([]u8, data.len);
    for (field_copy, 0..) |_, y| {
        field_copy[y] = try allocator.dupe(u8, data[y]);
    }
    return field_copy;
}

fn freeFieldCopy(field_copy: [][]u8, allocator: std.mem.Allocator) void {
    for (field_copy) |row| {
        allocator.free(row);
    }
    allocator.free(field_copy);
}

fn printVisited(field: [][]u8, visited: AutoHashMap(Position, void)) void {
    for (field, 0..) |row, i| {
        for (row, 0..) |char, j| {
            if (visited.contains(.{ .x = @intCast(j), .y = @intCast(i) })) {
                print("x", .{});
            } else {
                print("{c}", .{char});
            }
        }
        print("\n", .{});
    }
}

fn printVariant(field: [][]u8, x: usize, y: usize) void {
    for (field, 0..) |row, i| {
        for (row, 0..) |char, j| {
            if (i == y and j == x) {
                print("O", .{});
            } else {
                print("{c}", .{char});
            }
        }
        print("\n", .{});
    }
}

fn part2(data: []const []const u8, allocator: std.mem.Allocator) !void {
    var states = AutoHashMap(State, void).init(allocator);
    defer states.deinit();

    var field_copy = try createFieldCopy(data, allocator);
    defer freeFieldCopy(field_copy, allocator);

    const initial_position = findStart(data) orelse unreachable;

    var variants: usize = 0;
    for (data, 0..) |row, y| {
        for (row, 0..) |char, x| {
            if (char != '.') {
                continue;
            }
            states.clearRetainingCapacity();

            field_copy[y][x] = '#';
            defer field_copy[y][x] = '.';

            var iterator = Iterator{
                .field = field_copy,
                .position = initial_position,
            };
            while (iterator.next()) |state| {
                if (states.contains(state)) {
                    // printVariant(field_copy, x, y);
                    // print("\n", .{});

                    variants += 1;
                    break;
                }
                try states.put(state, {});
            }
        }
    }

    print("Part 2: {}\n", .{variants});
}

pub fn run() !void {
    print("Day 06\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer data.deinit();

    try part1(data.items, allocator);
    try part2(data.items, allocator);

    print("\n", .{});
}
