const std = @import("std");
const ArrayList = std.ArrayList;
const input = @embedFile("inputs/05.txt");

const Rule = struct { usize, usize };

const SourceData = struct {
    rules: ArrayList(*Rule),
    pages: ArrayList(ArrayList(usize)),

    fn debug_print(self: SourceData) void {
        std.debug.print("Rules: {any}\n", .{self.rules.items});
        std.debug.print("Pages:\n", .{});
        for (self.pages.items) |value| {
            std.debug.print("{any}\n", .{value.items});
        }
    }
};

fn loadData(allocator: std.mem.Allocator) !SourceData {
    var line_iter = std.mem.splitSequence(u8, input, "\n");

    var rules = ArrayList(*Rule).init(allocator);
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var parts = std.mem.splitSequence(u8, line, "|");
        const first_str = parts.next() orelse unreachable;
        const first = try std.fmt.parseInt(usize, first_str, 10);
        const second_str = parts.next() orelse unreachable;
        const second = try std.fmt.parseInt(usize, second_str, 10);

        const rule = allocator.create(Rule) catch unreachable;
        rule.* = .{ first, second };
        try rules.append(rule);
    }

    var pages = ArrayList(ArrayList(usize)).init(allocator);
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var page = ArrayList(usize).init(allocator);
        var parts = std.mem.splitSequence(u8, line, ",");
        while (parts.next()) |part| {
            if (part.len == 0) {
                continue;
            }

            try page.append(try std.fmt.parseInt(usize, part, 10));
        }

        try pages.append(page);
    }

    return SourceData{ .rules = rules, .pages = pages };
}

fn part1(source_data: SourceData, allocator: std.mem.Allocator) !void {
    var sum: usize = 0;

    var map = std.AutoHashMap(usize, usize).init(allocator);
    defer map.deinit();

    for (source_data.pages.items) |page| {
        map.clearRetainingCapacity();
        for (page.items, 0..) |item, i| {
            map.put(item, i) catch unreachable;
        }

        for (source_data.rules.items) |rule| {
            const first_index = map.get(rule[0]) orelse continue;
            const second_index = map.get(rule[1]) orelse continue;
            if (first_index > second_index) {
                break;
            }
        } else {
            // std.debug.print("Correct: {any}\n", .{page.items});
            const middle_item = page.items[(page.items.len - 1) / 2];
            // std.debug.print("Middle: {}\n", .{middle_item});
            sum += middle_item;
        }
    }

    std.debug.print("Part 1: {}\n", .{sum});
}

const Comparator = struct {
    rule_map: std.AutoHashMap(Rule, void),

    fn less_then(self: Comparator, a: usize, b: usize) bool {
        return !self.rule_map.contains(.{ b, a });
    }
};

fn part2(source_data: SourceData, allocator: std.mem.Allocator) !void {
    var sum: usize = 0;

    var map = std.AutoHashMap(usize, usize).init(allocator);
    defer map.deinit();

    var rule_map = std.AutoHashMap(Rule, void).init(allocator);
    defer rule_map.deinit();
    for (source_data.rules.items) |rule| {
        rule_map.put(rule.*, {}) catch unreachable;
    }

    for (source_data.pages.items) |page| {
        map.clearRetainingCapacity();
        for (page.items, 0..) |item, i| {
            map.put(item, i) catch unreachable;
        }

        for (source_data.rules.items) |rule| {
            const first_index = map.get(rule[0]) orelse continue;
            const second_index = map.get(rule[1]) orelse continue;
            if (first_index > second_index) {
                break;
            }
        } else {
            continue;
        }

        // std.debug.print("Incorrect: {any}\n", .{page.items});

        const context = Comparator{ .rule_map = rule_map };
        std.mem.sort(usize, page.items, context, Comparator.less_then);

        // std.debug.print("Sorted: {any}\n", .{page.items});

        const middle_item = page.items[(page.items.len - 1) / 2];
        // std.debug.print("Middle: {}\n", .{middle_item});
        sum += middle_item;
    }

    std.debug.print("Part 2: {}\n", .{sum});
}

pub fn main() !void {
    std.debug.print("Day 05\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const data = try loadData(allocator);
    defer {
        for (data.rules.items) |rule| {
            allocator.destroy(rule);
        }
        data.rules.deinit();

        for (data.pages.items) |page| {
            page.deinit();
        }
        data.pages.deinit();
    }

    // data.debug_print();

    try part1(data, allocator);
    try part2(data, allocator);
    std.debug.print("\n", .{});
}
