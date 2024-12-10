const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

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

const Position = struct { x: usize, y: usize };

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
                position = Position{ .x = self.x, .y = self.y };
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

fn part1(data: []const []const u8) !void {
    var iterator = TrailheadsIterator.init(data);
    while (iterator.next()) |trailhead| {
        print("{any}, {c}\n", .{ trailhead, data[trailhead.y][trailhead.x] });
    }

    print("Part 1\n", .{});
}

fn part2() !void {
    print("Part 2\n", .{});
}

pub fn main() !void {
    const data = try loadData(std.heap.page_allocator);
    defer data.deinit();

    try part1(data.items);

    print("Day 10\n", .{});
}
