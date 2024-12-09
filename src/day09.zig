const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const input = @embedFile("inputs/09.txt");

fn loadDiskMap(allocator: Allocator) ArrayList(u8) {
    var processed = ArrayList(u8).init(allocator);
    for (input) |char| {
        processed.append(char - '0') catch unreachable;
    }
    return processed;
}

fn getLayout(disk_map: []const u8, allocator: Allocator) ArrayList(?usize) {
    var layout = ArrayList(?usize).init(allocator);
    var id: usize = 0;
    var is_empty: bool = false;
    for (disk_map) |value| {
        defer is_empty = !is_empty;

        if (!is_empty) {
            for (0..value) |_| {
                layout.append(id) catch unreachable;
            }
            id += 1;
        } else {
            for (0..value) |_| {
                layout.append(null) catch unreachable;
            }
        }
    }
    return layout;
}

fn getEmptySpaces(layout: []const ?usize, allocator: Allocator) ArrayList(usize) {
    var empty_spaces = ArrayList(usize).init(allocator);
    for (layout, 0..) |value, i| {
        if (value == null) {
            empty_spaces.append(i) catch unreachable;
        }
    }
    return empty_spaces;
}

fn compactVer1(layout: *ArrayList(?usize), empty_spaces: *ArrayList(usize)) void {
    var available_empty: usize = 0;
    while (available_empty < empty_spaces.items.len) {
        const empty_index = empty_spaces.items[available_empty];
        if (empty_index >= layout.items.len) {
            break;
        }

        const last_item = layout.pop();
        if (last_item == null) {
            continue;
        }

        layout.items[empty_index] = last_item;
        available_empty += 1;
    }
}

fn calculateChecksum(layout: []const ?usize) usize {
    var checksum: usize = 0;
    for (layout, 0..) |value, i| {
        checksum += value.? * i;
    }
    return checksum;
}

fn part1(disk_map: []const u8, allocator: std.mem.Allocator) !void {
    var layout = getLayout(disk_map, allocator);
    defer layout.deinit();

    var empty_spaces = getEmptySpaces(layout.items, allocator);
    defer empty_spaces.deinit();

    compactVer1(&layout, &empty_spaces);

    print("Part 1: {d}\n", .{calculateChecksum(layout.items)});
}

fn part2() !void {
    print("Part 2\n", .{});
}

pub fn main() !void {
    print("Day 09\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const disk_map = loadDiskMap(allocator);
    defer disk_map.deinit();

    try part1(disk_map.items, allocator);
    try part2();

    print("\n", .{});
}
