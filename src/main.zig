const std = @import("std");
const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const day03 = @import("day03.zig");

pub fn main() !void {
    try day01.run();
    try day02.run();
    try day03.run();
}
