pub const Position = struct { x: isize, y: isize };

pub const Direction = enum {
    north,
    south,
    east,
    west,

    pub fn turnRight(self: Direction) Direction {
        return switch (self) {
            .north => .east,
            .east => .south,
            .south => .west,
            .west => .north,
        };
    }

    pub fn step(self: Direction, position: Position) Position {
        return switch (self) {
            .north => .{ .x = position.x, .y = position.y - 1 },
            .south => .{ .x = position.x, .y = position.y + 1 },
            .west => .{ .x = position.x - 1, .y = position.y },
            .east => .{ .x = position.x + 1, .y = position.y },
        };
    }
};

pub fn outOfBounds(position: Position, data: []const []const u8) bool {
    return position.y < 0 or
        position.y >= data.len or
        position.x < 0 or
        position.x >= data[@intCast(position.y)].len;
}
