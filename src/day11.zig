const std = @import("std");
const ArrayList = std.ArrayList;
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

fn nextState(stones: []const u64, allocator: std.mem.Allocator) ArrayList(u64) {
    var result = ArrayList(u64).init(allocator);

    for (stones) |stone| {
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
        const new_state = nextState(current_state.items, allocator);
        current_state.deinit();
        current_state = new_state;
    }

    print("Part 1: {d}\n", .{current_state.items.len});
    current_state.deinit();
}

fn part2() !void {}

pub fn main() !void {
    print("Day 11\n", .{});
    
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const data = try loadData(allocator);
    // defer data.deinit();
    try part1(data, allocator);
    
    print("\n", .{});
}
