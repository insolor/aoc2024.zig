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
        if (value != null) {
            checksum += value.? * i;
        }
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

const Block = struct {
    index: usize,
    size: usize,
};

fn getLastNotEmpty(layout: []const ?usize) ?Block {
    const id = layout[layout.len - 1];
    for (layout, 0..) |_, i| {
        const block_start = layout.len - 1 - i;
        if (layout[block_start] != id) {
            return Block{ .index = block_start + 1, .size = layout.len - block_start - 1 };
        }
    }
    return Block{ .index = 0, .size = layout.len - 1 };
}

fn printLayout(layout: []const ?usize) void {
    for (layout) |value| {
        if (value == null) {
            print(".", .{});
        } else {
            print("{d}", .{value.?});
        }
    }
    print("\n", .{});
}

fn compactVer2(layout: *ArrayList(?usize)) void {
    var empty_blocks = ArrayList(Block).init(layout.allocator);
    defer empty_blocks.deinit();

    var block_start: ?usize = null;
    for (layout.items, 0..) |value, i| {
        if (block_start != null) {
            if (value != null) {
                empty_blocks.append(Block{ .index = block_start.?, .size = i - block_start.? }) catch unreachable;
                block_start = null;
            }
        } else if (value == null) {
            block_start = i;
        }
    }

    // print("Empty blocks: {any}\n", .{empty_blocks.items});
    // print("Layout: ", .{});
    // printLayout(layout.items);

    var i = layout.items.len;
    var prev_id: ?usize = null;
    while (i > 0) {
        if (layout.items[i - 1] == null) {
            i -= 1;
            continue;
        }

        const last_block = getLastNotEmpty(layout.items[0..i]) orelse unreachable;

        const id = layout.items[last_block.index].?;
        defer prev_id = id;

        if (id == 0) {
            break;
        }

        if (prev_id != null and id >= prev_id.?) {
            // print("Already seen\n", .{});
        } else {
            for (0..empty_blocks.items.len) |j| {
                var empty = empty_blocks.items[j];
                if (last_block.size <= empty.size) {
                    // print("Block: {d} {any}\n", .{ id, last_block });
                    std.debug.assert(layout.items[empty.index] == null);
                    // print("Moved\n", .{});
                    std.mem.copyBackwards(
                        ?usize,
                        layout.items[empty.index .. empty.index + last_block.size],
                        layout.items[last_block.index .. last_block.index + last_block.size],
                    );

                    @memset(layout.items[last_block.index .. last_block.index + last_block.size], null);

                    empty.size -= last_block.size;
                    empty.index += last_block.size;
                    empty_blocks.items[j] = empty;

                    break;
                }
            }
        }

        i -= last_block.size;
        // print("Layout: ", .{});
        // printLayout(layout.items);
    }
}

fn part2(disk_map: []const u8, allocator: std.mem.Allocator) !void {
    var layout = getLayout(disk_map, allocator);
    defer layout.deinit();

    compactVer2(&layout);

    print("Part 2: {d}\n", .{calculateChecksum(layout.items)});
}

pub fn main() !void {
    print("Day 09\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const disk_map = loadDiskMap(allocator);
    defer disk_map.deinit();

    try part1(disk_map.items, allocator);
    try part2(disk_map.items, allocator);

    print("\n", .{});
}
