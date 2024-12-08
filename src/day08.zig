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

fn getAntinodes(node1: Position, node2: Position) [2]Position {
    const dx = node2.x - node1.x;
    const dy = node2.y - node1.y;
    return .{
        .{ .x = node1.x - dx, .y = node1.y - dy },
        .{ .x = node2.x + dx, .y = node2.y + dy },
    };
}

test "getAntinodes" {
    const node1 = Position{ .x = 0, .y = 0 };
    const node2 = Position{ .x = 1, .y = 1 };
    const result = getAntinodes(node1, node2);
    try std.testing.expectEqual(Position{ .x = -1, .y = -1 }, result[0]);
    try std.testing.expectEqual(Position{ .x = 2, .y = 2 }, result[1]);
}

fn positionInBounds(position: Position, data: []const []const u8) bool {
    return (position.y >= 0 and
        position.y < data.len and
        position.x >= 0 and
        position.x < data[@intCast(position.y)].len);
}

fn part1(data: ArrayList([]const u8), allocator: Allocator) !void {
    var nodes = AutoHashMap(u8, ArrayList(Position)).init(allocator);
    defer freeNodes(&nodes);

    try addNodes(data, &nodes, std.heap.page_allocator);

    var antinodes_set = AutoHashMap(Position, void).init(allocator);
    defer antinodes_set.deinit();

    // printNodes(nodes);

    var node_iterator = nodes.iterator();
    while (node_iterator.next()) |entry| {
        const positions = entry.value_ptr.*.items;
        for (positions, 0..) |node1, i| {
            for (i + 1..positions.len) |j| {
                const node2 = positions[j];
                const antinodes = getAntinodes(node1, node2);
                for (antinodes) |antinode| {
                    if (positionInBounds(antinode, data.items)) {
                        antinodes_set.put(antinode, void{}) catch unreachable;
                    }
                }
            }
        }
    }

    print("Part 1: {d}\n", .{antinodes_set.count()});
}

const AntinodesIterator = struct {
    current_position: Position,
    dx: isize,
    dy: isize,

    fn init(node1: Position, node2: Position) AntinodesIterator {
        const dx = node2.x - node1.x;
        const dy = node2.y - node1.y;
        return .{ .current_position = node2, .dx = dx, .dy = dy };
    }

    fn next(self: *AntinodesIterator) ?Position {
        self.current_position.x += self.dx;
        self.current_position.y += self.dy;
        return self.current_position;
    }
};

fn part2(data: ArrayList([]const u8), allocator: Allocator) !void {
    var nodes = AutoHashMap(u8, ArrayList(Position)).init(allocator);
    defer freeNodes(&nodes);

    try addNodes(data, &nodes, std.heap.page_allocator);

    var antinodes_set = AutoHashMap(Position, void).init(allocator);
    defer antinodes_set.deinit();

    var node_iterator = nodes.iterator();
    while (node_iterator.next()) |entry| {
        const positions = entry.value_ptr.*.items;
        for (positions, 0..) |node1, i| {
            for (i + 1..positions.len) |j| {
                const node2 = positions[j];
                
                antinodes_set.put(node1, void{}) catch unreachable;
                antinodes_set.put(node2, void{}) catch unreachable;
                
                var forward_antinodes = AntinodesIterator.init(node1, node2);
                while (forward_antinodes.next()) |antinode| {
                    if (!positionInBounds(antinode, data.items)) {
                        break;
                    }

                    antinodes_set.put(antinode, void{}) catch unreachable;
                }

                var backward_antinodes = AntinodesIterator.init(node2, node1);
                while (backward_antinodes.next()) |antinode| {
                    if (!positionInBounds(antinode, data.items)) {
                        break;
                    }

                    antinodes_set.put(antinode, void{}) catch unreachable;
                }
            }
        }
    }

    print("Part 1: {d}\n", .{antinodes_set.count()});
}

pub fn main() !void {
    print("Day 08\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer data.deinit();

    try part1(data, allocator);
    try part2(data, allocator);
}
