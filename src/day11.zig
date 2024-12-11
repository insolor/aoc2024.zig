const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const input = @embedFile("inputs/11.txt");

fn loadData(allocator: std.mem.Allocator) !ArrayList(u64) {
    var result = ArrayList(u64).init(allocator);
    var parts = std.mem.splitSequence(u8, input, " ");
    while (parts.next()) |item| {
        try result.append(try std.fmt.parseUnsigned(u64, item, 10));
    }
    return result;
}

fn countDigits(n: u64) usize {
    if (n == 0) {
        return 1;
    }

    var value: u64 = n;
    var count: usize = 0;
    while (value > 0) {
        count += 1;
        value /= 10;
    }
    return count;
}

test "countDigits" {
    try std.testing.expectEqual(1, countDigits(0));
    try std.testing.expectEqual(1, countDigits(1));
    try std.testing.expectEqual(2, countDigits(12));
    try std.testing.expectEqual(3, countDigits(123));
}

fn constructNumber(digits: []const u8) u64 {
    var value: u64 = 0;
    for (digits) |digit| {
        value *= 10;
        value += digit;
    }
    return value;
}

test "constructNumber" {
    try std.testing.expectEqual(123, constructNumber(&[_]u8{ 1, 2, 3 }));
}

fn splitNumber(n: u64, allocator: Allocator) ?[2]u64 {
    const digits = countDigits(n);
    if (digits % 2 != 0) {
        return null;
    }
    const half = digits / 2;
    var value = n;

    var result: [2]u64 = [2]u64{ 0, 0 };

    var buffer = ArrayList(u8).init(allocator);
    defer buffer.deinit();

    var part_index: isize = 1;
    while (value > 0) {
        const digit = value % 10;
        buffer.insert(0, @intCast(digit)) catch unreachable;
        value /= 10;
        if (buffer.items.len == half) {
            result[@intCast(part_index)] = constructNumber(buffer.items);
            buffer.clearRetainingCapacity();
            part_index -= 1;
        }
    }

    return result;
}

test "splitNumber" {
    try std.testing.expectEqual(null, splitNumber(1, std.testing.allocator));
    try std.testing.expectEqual([2]u64{ 1, 2 }, splitNumber(12, std.testing.allocator).?);
    try std.testing.expectEqual(null, splitNumber(123, std.testing.allocator));
    try std.testing.expectEqual([2]u64{ 12, 34 }, splitNumber(1234, std.testing.allocator).?);
}

fn nextState(stones: *ArrayList(u64), allocator: std.mem.Allocator) ArrayList(u64) {
    var result = ArrayList(u64).init(allocator);

    while (stones.popOrNull()) |stone| {
        if (stone == 0) {
            result.append(1) catch unreachable;
            continue;
        }

        const new_stones = splitNumber(stone, allocator);
        if (new_stones != null) {
            result.append(new_stones.?[0]) catch unreachable;
            result.append(new_stones.?[1]) catch unreachable;
            continue;
        }

        result.append(stone * 2024) catch unreachable;
    }

    return result;
}

fn part1(data: ArrayList(u64), allocator: Allocator) !void {
    var current_state = data;
    for (0..25) |_| {
        const new_state = nextState(&current_state, allocator);
        current_state.deinit();
        current_state = new_state;
    }

    print("Part 1: {d}\n", .{current_state.items.len});
    current_state.deinit();
}

fn addValue(stones: *AutoHashMap(u64, usize), key: u64, value: usize) void {
    if (stones.get(key)) |v| {
        stones.put(key, v + value) catch unreachable;
    } else {
        stones.put(key, value) catch unreachable;
    }
}

fn nextStateHashMap(stones: *AutoHashMap(u64, usize), allocator: std.mem.Allocator) AutoHashMap(u64, usize) {
    var result = AutoHashMap(u64, usize).init(allocator);

    var iterator = stones.iterator();
    while (iterator.next()) |entry| {
        const value = entry.key_ptr.*;
        const count = entry.value_ptr.*;
        if (value == 0) {
            addValue(&result, 1, count);
            continue;
        }

        const new_stones = splitNumber(entry.key_ptr.*, allocator);
        if (new_stones != null) {
            addValue(&result, new_stones.?[0], count);
            addValue(&result, new_stones.?[1], count);
            continue;
        }

        addValue(&result, value * 2024, count);
    }

    return result;
}

fn part2(data: []const u64, allocator: Allocator) !void {
    var current_state = AutoHashMap(u64, usize).init(allocator);
    for (data) |stone| {
        addValue(&current_state, stone, 1);
    }

    for (0..75) |_| {
        // print("Step {d}\n", .{i});
        // print("Size {d}\n\n", .{current_state.count()});
        const new_state = nextStateHashMap(&current_state, allocator);
        current_state.deinit();
        current_state = new_state;
    }

    var total: usize = 0;
    var iterator = current_state.valueIterator();
    while (iterator.next()) |value| {
        total += value.*;
    }

    print("Part 2: {d}\n", .{total});
    current_state.deinit();
}

pub fn main() !void {
    print("Day 11\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const data1 = try loadData(allocator);
    // defer data1.deinit();
    try part1(data1, allocator);

    const data2 = try loadData(allocator);
    defer data2.deinit();
    try part2(data2.items, allocator);

    print("\n", .{});
}
