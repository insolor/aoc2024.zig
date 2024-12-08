const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const input = @embedFile("inputs/07.txt");
fn part1() !void {
    const result = 0;
    print("Part 1: {d}\n", .{result});
}

fn part2() !void {}

pub fn main() !void {
    print("Day 08\n", .{});
    try part1();
    try part2();
}