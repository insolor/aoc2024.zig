const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const utils = @import("utils.zig");
const Direction = utils.Direction;
const Position = utils.Position;
const outOfBounds = utils.outOfBounds;

const input = @embedFile("inputs/12.txt");

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

const AreaPerimeter = struct { area: usize, perimeter: usize };

fn countGroupAreaAndPerimeter(
    data: []const []const u8,
    position: Position,
    visited: *AutoHashMap(Position, void),
    area_perimeter: *AreaPerimeter,
) !void {
    const current_value = data[@intCast(position.y)][@intCast(position.x)];
    try visited.put(position, {});

    var cell_fences: isize = 4;
    inline for (std.meta.fields(Direction)) |direction| {
        const new_position = @field(Direction, direction.name)
            .step(position);
        if (!outOfBounds(new_position, data)) {
            if (data[@intCast(new_position.y)][@intCast(new_position.x)] == current_value) {
                cell_fences -= 1;
                if (!visited.contains(.{ .x = @intCast(new_position.x), .y = @intCast(new_position.y) })) {
                    try countGroupAreaAndPerimeter(
                        data,
                        new_position,
                        visited,
                        area_perimeter,
                    );
                }
            }
        }
    }

    area_perimeter.area += 1;
    area_perimeter.perimeter += @intCast(cell_fences);
}

fn part1(data: []const []const u8, allocator: std.mem.Allocator) !void {
    var visited = AutoHashMap(Position, void).init(allocator);
    defer visited.deinit();

    var total_cost: usize = 0;
    for (data, 0..) |row, y| {
        for (row, 0..) |_, x| {
            const position = Position{ .x = @intCast(x), .y = @intCast(y) };
            if (visited.contains(position)) {
                continue;
            }

            var result = AreaPerimeter{ .area = 0, .perimeter = 0 };

            try countGroupAreaAndPerimeter(data, position, &visited, &result);
            // print("Region {c}: area={d}, perimeter={d}\n", .{ row[x], result.area, result.perimeter });
            total_cost += result.area * result.perimeter;
        }
    }

    print("Part 1: {d}\n", .{total_cost});
}

fn part2() !void {}

pub fn main() !void {
    print("Day 12\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const data = try loadData(allocator);
    defer data.deinit();

    try part1(data.items, allocator);
    try part2();
    print("\n", .{});
}
