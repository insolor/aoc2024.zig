const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const print = std.debug.print;
const utils = @import("utils.zig");
const Direction = utils.Direction;
const Position = utils.Position;
const outOfBounds = utils.outOfBounds;

const input = @embedFile("inputs/10.txt");

fn loadData(allocator: std.mem.Allocator) !ArrayList([]const u8) {
    var lines = std.mem.splitSequence(u8, input, "\n");

    var result = ArrayList([]const u8).init(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        try result.append(line);
    }

    return result;
}

const TrailheadsIterator = struct {
    field: []const []const u8,
    x: usize,
    y: usize,

    fn init(field: []const []const u8) TrailheadsIterator {
        return .{ .field = field, .x = 0, .y = 0 };
    }

    fn next(self: *TrailheadsIterator) ?Position {
        if (self.y > self.field.len) {
            return null;
        }

        while (true) {
            var position: ?Position = null;
            if (self.field[self.y][self.x] == '0') {
                position = Position{ .x = @intCast(self.x), .y = @intCast(self.y) };
            }

            self.x += 1;
            if (self.x >= self.field[self.y].len) {
                self.y += 1;
                self.x = 0;
            }

            if (self.y >= self.field.len) {
                return null;
            }

            if (position != null) {
                return position;
            }
        }
    }
};

fn findPath(data: []const []const u8, x: usize, y: usize, result: *AutoHashMap(Position, void)) void {
    if (data[y][x] == '9') {
        result.*.put(.{ .x = @intCast(x), .y = @intCast(y) }, void{}) catch unreachable;
        return;
    }

    const current_value = data[@intCast(y)][@intCast(x)];
    inline for (std.meta.fields(Direction)) |direction| {
        const new_position = @field(Direction, direction.name)
            .step(.{ .x = @intCast(x), .y = @intCast(y) });

        if (!outOfBounds(new_position, data)) {
            const new_value = data[@intCast(new_position.y)][@intCast(new_position.x)];
            if (@as(i64, new_value) - current_value == 1) {
                findPath(data, @intCast(new_position.x), @intCast(new_position.y), result);
            }
        }
    }
}

fn part1(data: []const []const u8, allocator: Allocator) !void {
    var iterator = TrailheadsIterator.init(data);
    var result = AutoHashMap(Position, void).init(allocator);
    defer result.deinit();

    var total_score: usize = 0;
    while (iterator.next()) |trailhead| {
        result.clearRetainingCapacity();

        findPath(data, @intCast(trailhead.x), @intCast(trailhead.y), &result);
        total_score += result.count();
    }

    print("Part 1: {d}\n", .{total_score});
}

fn findPath2(data: []const []const u8, x: usize, y: usize) usize {
    if (data[y][x] == '9') {
        return 1;
    }

    var score: usize = 0;
    const current_value = data[@intCast(y)][@intCast(x)];
    inline for (std.meta.fields(Direction)) |direction| {
        const new_position = @field(Direction, direction.name)
            .step(.{ .x = @intCast(x), .y = @intCast(y) });

        if (!outOfBounds(new_position, data)) {
            const new_value = data[@intCast(new_position.y)][@intCast(new_position.x)];
            if (@as(i64, new_value) - current_value == 1) {
                score += findPath2(data, @intCast(new_position.x), @intCast(new_position.y));
            }
        }
    }
    return score;
}

fn part2(data: []const []const u8) !void {
    var iterator = TrailheadsIterator.init(data);

    var total_score: usize = 0;
    while (iterator.next()) |trailhead| {
        total_score += findPath2(data, @intCast(trailhead.x), @intCast(trailhead.y));
    }

    print("Part 2: {d}\n", .{total_score});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer data.deinit();

    try part1(data.items, allocator);
    try part2(data.items);

    print("Day 10\n", .{});
}
