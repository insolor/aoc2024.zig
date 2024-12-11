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

fn nextStateFiles(fileName1: []const u8, fileName2: []const u8, allocator: std.mem.Allocator) !void {
    var fileIn = try std.fs.cwd().openFile(fileName1, .{});
    defer fileIn.close();

    var buf_reader = std.io.bufferedReader(fileIn.reader());
    var in_stream = buf_reader.reader();

    var fileOut = try std.fs.cwd().createFile(fileName2, .{});
    defer fileOut.close();

    var buf_writer = std.io.bufferedWriter(fileOut.writer());
    var out_stream = buf_writer.writer();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const stone = try std.fmt.parseUnsigned(u64, line, 10);
        if (stone == 0) {
            try out_stream.print("1\n", .{});
            continue;
        }

        const new_stones = splitNumber(stone, allocator);
        if (new_stones != null) {
            try out_stream.print("{}\n{}\n", .{ new_stones.?[0], new_stones.?[1] });
            continue;
        }
        try out_stream.print("{}\n", .{stone * 2024});
    }
    try buf_writer.flush();
}

fn writeDataToFile(data: []const u64, fileName: []const u8) !void {
    var file = try std.fs.cwd().createFile(fileName, .{});
    defer file.close();

    var buf_writer = std.io.bufferedWriter(file.writer());
    var out_stream = buf_writer.writer();
    for (data) |stone| {
        try out_stream.print("{}\n", .{stone});
    }
    try buf_writer.flush();
}

fn countFileLines(fileName: []const u8) !u64 {
    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var count: u64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |_| {
        if (buf.len != 0) {
            count += 1;
        }
    }
    return count;
}

fn formatFileName(counter: usize, allocator: Allocator) ![]const u8 {
    return try std.fmt.allocPrint(allocator, "{d}.txt", .{counter});
}

fn part2(data: []const u64, allocator: Allocator) !void {
    var counter: usize = 0;

    const initial_file_name = try formatFileName(counter, allocator);
    defer allocator.free(initial_file_name);
    try writeDataToFile(data, initial_file_name);
    try std.testing.expectEqual(data.len, try countFileLines(initial_file_name));

    var prev_name = initial_file_name;
    for (0..75) |i| {
        print("Iteration: {d}\n", .{i});

        const next_name = try formatFileName(counter + 1, allocator);

        try nextStateFiles(prev_name, next_name, allocator);

        try std.fs.cwd().deleteFile(prev_name);
        allocator.free(prev_name);

        prev_name = next_name;
        counter += 1;
    }

    counter = 0;

    print("Part 2: {d}\n", .{try countFileLines(prev_name)});
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
