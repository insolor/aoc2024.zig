const std = @import("std");
const input = @embedFile("inputs/03.txt");

const mul_prefix = "mul(";
const do_prefix = "do()";
const dont_prefix = "don't()";

fn getIntPart(s: []const u8) ?[]const u8 {
    for (s, 0..) |c, i| {
        if (c < '0' or c > '9') {
            if (i == 0) {
                return null;
            }

            return s[0..i];
        }
    }

    return null;
}

fn startsWith(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) {
        return false;
    }
    return std.mem.eql(u8, s[0..prefix.len], prefix);
}

fn parseMul(s: []const u8) !?struct { value: u32, len: usize } {
    var i: usize = 0;
    if (!startsWith(s, mul_prefix)) {
        return null;
    }

    i += mul_prefix.len;
    const arg1_slice = getIntPart(s[i..]) orelse return null;

    if (s[i + arg1_slice.len] != ',') {
        return null;
    }

    const arg1 = try std.fmt.parseInt(u32, arg1_slice, 10);

    i += arg1_slice.len + 1;
    const arg2_slice = getIntPart(s[i..]) orelse return null;
    if (s[i + arg2_slice.len] != ')') {
        return null;
    }

    const arg2 = try std.fmt.parseInt(u32, arg2_slice, 10);

    return .{
        .value = arg1 * arg2,
        .len = i + arg2_slice.len,
    };
}

fn part1() !void {
    var sum: u32 = 0;

    var i: usize = 0;
    while (i < input.len - mul_prefix.len) : (i += 1) {
        const result = try parseMul(input[i..]) orelse continue;
        sum += result.value;
        i += result.len;
    }

    std.debug.print("Part 1: {d}\n", .{sum});
}

fn part2() !void {
    var sum: u32 = 0;

    var do: bool = true;
    var i: usize = 0;
    while (i < input.len - mul_prefix.len) {
        if (startsWith(input[i..], mul_prefix)) {
            const result = try parseMul(input[i..]) orelse {
                i += 1;
                continue;
            };
            if (do) {
                sum += result.value;
            }
            i += result.len;
        } else if (startsWith(input[i..], do_prefix)) {
            do = true;
            i += do_prefix.len;
        } else if (startsWith(input[i..], dont_prefix)) {
            do = false;
            i += dont_prefix.len;
        } else {
            i += 1;
        }
    }

    std.debug.print("Part 2: {d}\n", .{sum});
}

pub fn run() !void {
    std.debug.print("Day 03\n", .{});
    try part1();
    try part2();
}
