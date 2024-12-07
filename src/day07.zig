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
        } else {
            result *= argument;
        }
    }
    return result;
}

fn solvable(row: *DataRow, allocator: Allocator) bool {
    var op_iterator = OperatorIterator.init(
        "*+",
        row.arguments.items.len - 1,
        allocator,
    );
    defer op_iterator.deinit();
    while (op_iterator.next()) |operators| {
        if (applyOperators(row.arguments.items, operators) == row.result) {
            printSolution(row, operators);
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
        if (solvable(row, allocator)) {
            sum += row.result;
        }
    }
    print("Part 1: {d}\n", .{sum});
}

fn getMagnitude(n: u64) u64 {
    var result: u64 = 1;
    while (result < n) {
        result *= 10;
    }
    return result;
}

fn glueArgument(arguments: []u64, argument: u64) void {
    const last = arguments[arguments.len - 1];
    arguments[arguments.len - 1] = last * getMagnitude(argument) + argument;
}

fn glueArguments(
    arguments: []u64,
    operators: []u8,
    allocator: Allocator,
) struct { ArrayList(u64), ArrayList(u8) } {
    var new_arguments = ArrayList(u64).init(allocator);
    var new_operators = ArrayList(u8).init(allocator);

    new_arguments.append(arguments[0]) catch unreachable;
    for (operators, 0..) |operator, i| {
        if (operator == '|') {
            glueArgument(new_arguments.items, arguments[i + 1]);
            continue;
        }

        new_arguments.append(arguments[i + 1]) catch unreachable;
        new_operators.append(operator) catch unreachable;
    }

    return .{ new_arguments, new_operators };
}

test "glueArguments" {
    var arguments = [_]u64{ 6, 8, 6, 15 };
    var operators = [_]u8{ '*', '|', '*' };

    var new_arguments, var new_operators = glueArguments(
        arguments[0..],
        operators[0..],
        std.heap.page_allocator,
    );
    defer new_arguments.deinit();
    defer new_operators.deinit();

    try std.testing.expect(std.mem.eql(u64, new_arguments.items, &[_]u64{ 6, 86, 15 }));
    try std.testing.expect(std.mem.eql(u8, new_operators.items, "**"));
}

fn applyOperators2(arguments: []u64, operators: []u8) u64 {
    var new_arguments, var new_operators = glueArguments(
        arguments,
        operators,
        std.heap.page_allocator,
    );
    defer new_arguments.deinit();
    defer new_operators.deinit();

    // if (new_arguments.items.len < arguments.len) {
    //     print("arguments: {any}\n", .{arguments});
    //     print("operators: {s}\n", .{operators});
    //     print("new_arguments: {any}\n", .{new_arguments.items});
    //     print("new_operators: {s}\n", .{new_operators.items});
    //     print("\n", .{});
    // }

    var result = new_arguments.items[0];

    for (new_operators.items, 1..) |op, i| {
        const argument = new_arguments.items[i];
        if (op == '+') {
            result += argument;
        } else {
            result *= argument;
        }
    }
    return result;
}

test "applyOperators2" {
    var arguments = [_]u64{ 6, 8, 6, 15 };
    var operators = [_]u8{ '*', '|', '*' };

    const result = applyOperators2(arguments[0..], operators[0..]);
    try std.testing.expectEqual(6 * 86 * 15, result);
}

fn solvable2(row: *DataRow, allocator: Allocator) bool {
    var op_iterator = OperatorIterator.init(
        "*+|",
        row.arguments.items.len - 1,
        allocator,
    );
    defer op_iterator.deinit();
    while (op_iterator.next()) |operators| {
        if (applyOperators2(row.arguments.items, operators) == row.result) {
            printSolution(row, operators);
            return true;
        }
    }
    return false;
}

fn part2(data: ArrayList(*DataRow), allocator: std.mem.Allocator) !void {
    var sum: u64 = 0;
    for (data.items) |row| {
        // printRow(row);
        if (solvable2(row, allocator)) {
            sum += row.result;
        }
    }
    print("Part 2: {d}\n", .{sum});
}

pub fn run() !void {
    print("Day 07\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer freeData(data, allocator);

    try part1(data, allocator);
    print("\n", .{});
    try part2(data, allocator);

    print("\n", .{});
}
