const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const input = @embedFile("inputs/07.txt");

const DataRow = struct {
    result: u64 = undefined,
    arguments: ArrayList(u64) = undefined,
};

fn parseUnsigned(s: []const u8) !u64 {
    return try std.fmt.parseUnsigned(u64, s, 10);
}

fn loadData(allocator: std.mem.Allocator) !ArrayList(*DataRow) {
    var result = ArrayList(*DataRow).init(allocator);

    var lines = std.mem.splitSequence(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var row = allocator.create(DataRow) catch unreachable;
        try result.append(row);

        var parts = std.mem.splitSequence(u8, line, " ");

        const result_str = parts.next().?;

        row.result = try parseUnsigned(result_str[0 .. result_str.len - 1]);

        row.arguments = ArrayList(u64).init(allocator);
        while (parts.next()) |part| {
            try row.arguments.append(parseUnsigned(part) catch unreachable);
        }
    }

    return result;
}

fn freeData(data: ArrayList(*DataRow), allocator: std.mem.Allocator) void {
    for (data.items) |row| {
        row.arguments.deinit();
        allocator.destroy(row);
    }
    data.deinit();
}

fn printRow(row: *DataRow) void {
    print("{d}: {any}\n", .{ row.result, row.arguments.items });
}

fn printData(data: ArrayList(*DataRow)) void {
    for (data.items) |row| {
        printRow(row);
    }
}

const OperatorIterator = struct {
    operators: []const u8,
    max: u64,
    state: u64 = 0,
    buffer: []u8 = undefined,
    allocator: Allocator = undefined,

    fn init(operators: []const u8, count: u64, allocator: Allocator) OperatorIterator {
        return OperatorIterator{
            .operators = operators,
            .max = std.math.pow(u64, operators.len, count),
            .buffer = allocator.alloc(u8, count) catch unreachable,
            .allocator = allocator,
        };
    }

    fn deinit(self: *OperatorIterator) void {
        self.allocator.free(self.buffer);
    }

    fn next(self: *OperatorIterator) ?[]u8 {
        if (self.state >= self.max) {
            return null;
        }

        var value = self.state;

        for (self.buffer, 0..) |_, i| {
            self.buffer[i] = self.operators[value % self.operators.len];
            value /= self.operators.len;
        }
        self.state += 1;
        return self.buffer;
    }
};

fn applyOperators(arguments: []u64, operators: []u8) u64 {
    var result = arguments[0];

    for (operators, 1..) |op, i| {
        const argument = arguments[i];
        if (op == '+') {
            result += argument;
        } else if (op == '*') {
            result *= argument;
        } else if (op == '|') {
            result = result * getMagnitude(argument) + argument;
        } else unreachable;
    }
    return result;
}

fn solvable(row: *DataRow, possible_operators: []const u8, allocator: Allocator) bool {
    var op_iterator = OperatorIterator.init(
        possible_operators,
        row.arguments.items.len - 1,
        allocator,
    );
    defer op_iterator.deinit();
    while (op_iterator.next()) |operators| {
        if (applyOperators(row.arguments.items, operators) == row.result) {
            // printSolution(row, operators);
            return true;
        }
    }
    return false;
}

fn printSolution(row: *DataRow, opertors: []u8) void {
    print("{d} = {d} ", .{ row.result, row.arguments.items[0] });
    for (opertors, 0..) |op, i| {
        print("{c} {d} ", .{ op, row.arguments.items[i + 1] });
    }
    print("\n", .{});
}

fn part1(data: ArrayList(*DataRow), allocator: std.mem.Allocator) !void {
    var sum: u64 = 0;
    for (data.items) |row| {
        if (solvable(row, "+*", allocator)) {
            sum += row.result;
        }
    }
    print("Part 1: {d}\n", .{sum});
}

fn getMagnitude(n: u64) u64 {
    var result: u64 = 1;
    while (result <= n) {
        result *= 10;
    }
    return result;
}

test "applyOperators" {
    var arguments = [_]u64{ 6, 8, 6, 15 };
    var operators = [_]u8{ '*', '|', '*' };

    const result = applyOperators(arguments[0..], operators[0..]);
    try std.testing.expectEqual(((6 * 8) * 10 + 6) * 15, result);
}

fn part2(data: ArrayList(*DataRow), allocator: std.mem.Allocator) !void {
    var sum: u64 = 0;
    for (data.items) |row| {
        // printRow(row);
        if (solvable(row, "+*|", allocator)) {
            sum += row.result;
        }
    }
    print("Part 2: {d}\n", .{sum});
}

pub fn main() !void {
    print("Day 07\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer freeData(data, allocator);

    try part1(data, allocator);
    try part2(data, allocator);

    print("\n", .{});
}
