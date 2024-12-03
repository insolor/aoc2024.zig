const std = @import("std");
const input = @embedFile("inputs/03.txt");
const prefix = "mul(";

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

fn part1() !void {
    var sum: u32 = 0;

    for (0..input.len - prefix.len) |i| {
        if (!std.mem.eql(u8, input[i .. i + prefix.len], prefix)) {
            continue;
        }

        const arg1_start = i + prefix.len;
        const arg1_slice = getIntPart(input[arg1_start ..]) orelse continue;
        
        if (input[arg1_start + arg1_slice.len] != ',') {
            continue;
        }
        
        const arg1 = try std.fmt.parseInt(u32, arg1_slice, 10);

        const arg2_start: usize = arg1_start + arg1_slice.len + 1;
        const arg2_slice = getIntPart(input[arg2_start ..]) orelse continue;
        if (input[arg2_start + arg2_slice.len] != ')') {
            continue;
        }
        const arg2 = try std.fmt.parseInt(u32, arg2_slice, 10);

        sum += arg1 * arg2;
    }

    std.debug.print("Part 1: {d}\n", .{sum});
}

pub fn run() !void {
    std.debug.print("Day 03\n", .{});
    try part1();
}
