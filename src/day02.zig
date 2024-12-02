const std = @import("std");

const input = @embedFile("inputs/02.txt");

pub fn run() !void {
    std.debug.print("Day 02\n", .{});

    var lines = std.mem.split(u8, input, "\n");
    var safe: u32 = 0;

    while (lines.next()) |line| {
        var parts = std.mem.split(u8, line, " ");

        var prev: ?i32 = null;
        var asc: ?bool = null;
        while (parts.next()) |part| {
            const value = try std.fmt.parseInt(i32, part, 10);

            if (prev == null) {
                prev = value;
                continue;
            }

            const new_asc = value > prev.?;

            if (asc == null) {
                asc = new_asc;
            } else if (asc.? != new_asc) {
                break;
            }

            const delta = @abs(prev.? - value);
            if (delta < 1 or delta > 3) {
                break;
            }
            prev = value;
        } else {
            safe += 1;
        }
    }

    std.debug.print("Part 1: {}\n", .{safe});
}
