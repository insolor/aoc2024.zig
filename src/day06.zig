const std = @import("std");
const utils = @import("utils.zig");
const Position = utils.Position;
const Direction = utils.Direction;
const outOfBounds = utils.outOfBounds;
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
            self.direction = self.direction.turnRight();
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

fn checkInfiniteLoop(field: [][]u8, initial_position: Position, states: *AutoHashMap(State, void)) !bool {
    var iterator = Iterator{
        .field = field,
        .position = initial_position,
    };
    while (iterator.next()) |state| {
        if (states.contains(state)) {
            return true;
        }
        try states.put(state, {});
    }
    return false;
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

            if (try checkInfiniteLoop(field_copy, initial_position, &states)) {
                variants += 1;
            }
        }
    }

    print("Part 2: {}\n", .{variants});
}

pub fn main() !void {
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
