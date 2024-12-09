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

fn part1(disk_map: []const u8, allocator: std.mem.Allocator) !void {
    var layout = ArrayList(?usize).init(allocator);
    defer layout.deinit();

    var empty_spaces = ArrayList(usize).init(allocator);
    defer empty_spaces.deinit();

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
                empty_spaces.append(layout.items.len) catch unreachable;
                layout.append(null) catch unreachable;
            }
        }
    }
    print("Layout: {any}\n", .{layout.items});
    print("Empty spaces: {any}\n", .{empty_spaces.items});

    // Compacting
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

    print("Final layout: {any}\n", .{layout.items});

    // Checksum
    var checksum: usize = 0;
    for (layout.items, 0..) |value, i| {
        checksum += value.? * i;
    }

    print("Part 1: {d}\n", .{checksum});
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
}
