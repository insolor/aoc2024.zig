const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const input = @embedFile("inputs/07.txt");

const DataRow = struct {
    result: u64 = undefined,
    arguments: ArrayList(u64) = undefined,
};

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

        row.result = try std.fmt.parseUnsigned(u64, result_str[0 .. result_str.len - 1], 10);

        row.arguments = ArrayList(u64).init(allocator);
        while (parts.next()) |part| {
            const argument = try std.fmt.parseUnsigned(u64, part, 10);
            try row.arguments.append(argument);
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
    max: u64,
    state: u64 = 0,
    buffer: []u8 = undefined,

    pub fn init(count: usize, allocator: Allocator) OperatorIterator {
        return OperatorIterator{
            .max = @as(u64, 1) << @truncate(count),
            .buffer = allocator.alloc(u8, count) catch unreachable,
        };
    }

    fn next(self: *OperatorIterator) ?[]u8 {
        if (self.state >= self.max) {
            return null;
        }

        var value = self.state;

        for (self.buffer, 0..) |_, i| {
            if (value & 1 == 1) {
                self.buffer[i] = '+';
            } else {
                self.buffer[i] = '*';
            }
            value >>= 1;
        }
        self.state += 1;
        return self.buffer;
    }
};

fn applyOperators(arguments: []u64, operators: []u8) u64 {
    var result = arguments[0];
    for (operators, 1..) |op, i| {
        if (op == '+') {
            result += arguments[i];
        } else {
            result *= arguments[i];
        }
    }
    return result;
}

fn solvable(row: *DataRow, allocator: Allocator) bool {
    var op_iterator = OperatorIterator.init(row.arguments.items.len - 1, allocator);
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

fn part2(data: ArrayList(*DataRow), allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = data;

    print("Part 2:\n", .{});
}

pub fn run() !void {
    print("Day 07\n", .{});

    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer freeData(data, allocator);

    try part1(data, allocator);
    // try part2(data, allocator);
}
