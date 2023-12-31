const std = @import("std");
const builtin = @import("builtin");
const console = @import("console.zig");
const conio = switch (builtin.target.os.tag) {
    .windows => @cImport(@cInclude("conio.h")),
    else => @compileError("unsupport platform"),
};

const ESC = 27;
const SPACE = 32;
const UP = 72;
const LEFT = 75;
const RIGHT = 77;
const DOWN = 80;

const Direction = enum {
    UP,
    DOWN,
    LEFT,
    RIGHT,
};

const _Shape = [3]console.Coordinate;
const Shape = struct {
    const available_shapes: [7][]const _Shape = blk: {
        const O_shape: _Shape = .{
            .{0, 1},
            .{1, 0},
            .{1, 1},
        };
        const I_shape: _Shape = .{
            .{0, -2},
            .{0, -1},
            .{0, 1},
        };
        const S_shape: _Shape = .{
            .{-1, 1},
            .{0, 1},
            .{1, 0},
        };
        const Z_shape: _Shape = .{
            .{-1, 0},
            .{0, 1},
            .{1, 1},
        };
        const L_shape: _Shape = .{
            .{-1, 0},
            .{-1, 1},
            .{1, 0},
        };
        const J_shape: _Shape = .{
            .{-1, 0},
            .{1, 0},
            .{1, 1},
        };
        const T_shape: _Shape = .{
            .{-1, 0},
            .{0, 1},
            .{1, 0},
        };
        break:blk .{
            &[_]_Shape{O_shape},
            &[_]_Shape{I_shape, rotate_90(&I_shape)},
            &[_]_Shape{S_shape, rotate_90(&S_shape)},
            &[_]_Shape{Z_shape, rotate_90(&Z_shape)},
            &[_]_Shape{L_shape, rotate_90(&L_shape), rotate_180(&L_shape), rotate_270(&L_shape)},
            &[_]_Shape{J_shape, rotate_90(&J_shape), rotate_180(&J_shape), rotate_270(&J_shape)},
            &[_]_Shape{T_shape, rotate_90(&T_shape), rotate_180(&T_shape), rotate_270(&T_shape)},
        };
    };

    i: u3,
    j: u2,
    color: console.Color,

    pub fn random(rand_impl: *std.rand.Xoshiro256) Shape {
        const i = rand_impl.random().intRangeAtMost(u3, 0, 6);
        const max: u2 = @intCast(available_shapes[i].len - 1);
        const j = rand_impl.random().intRangeAtMost(u2, 0, max);
        return .{
            .i = i,
            .j = j,
            .color = @enumFromInt(@as(u16, i)),
        };
    }

    pub fn get(self: *const Shape) *const _Shape {
        return &available_shapes[self.i][self.j];
    }

    pub fn rotate(self: *Shape, option: struct {reverse: bool = false}) void {
        if (option.reverse) {
            if (self.j > 0) {
                self.j -= 1;
            } else {
                self.j = @intCast(available_shapes[self.i].len - 1);
            }
        } else {
            if (self.j < available_shapes[self.i].len - 1) {
                self.j += 1;
            } else {
                self.j = 0;
            }
        }
    }
};

const Block = struct {

    coordinate: console.Coordinate,
    shape: Shape,

    pub fn init(x: i16, rand_impl: *std.rand.Xoshiro256) Block {
        return .{
            .coordinate = .{x, -1},
            .shape = Shape.random(rand_impl),
        };
    }

    pub fn move(self: *Block, direction: Direction) void {
        switch (direction) {
            .UP => self.coordinate[1] -= 1,
            .DOWN => self.coordinate[1] += 1,
            .LEFT => self.coordinate[0] -= 1,
            .RIGHT => self.coordinate[0] += 1,
        }
    }
};

fn rotate_90(shape: *const _Shape) _Shape {
    return .{
        .{-shape[0][1], shape[0][0]},
        .{-shape[1][1], shape[1][0]},
        .{-shape[2][1], shape[2][0]},
    };
}

fn rotate_180(shape: *const _Shape) _Shape {
    return .{
        .{-shape[0][0], -shape[0][1]},
        .{-shape[1][0], -shape[1][1]},
        .{-shape[2][0], -shape[2][1]},
    };
}

fn rotate_270(shape: *const _Shape) _Shape {
    return .{
        .{shape[0][1], -shape[0][0]},
        .{shape[1][1], -shape[1][0]},
        .{shape[2][1], -shape[2][0]},
    };
}

pub fn init(
    comptime title: [*:0]const u8,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    const cs = console.init(title, width, height);
    return struct {
        const GameError = error {
            StopError,
            OverflowError,
            UserExit,
        };
        var data = [1]console.Point{null} ** (width * height);

        // data: [width * height]console.Point = [1]console.Point{null} ** (width * height),
        rand_impl: *std.rand.Xoshiro256,
        init_interval: i64 = 15000,

        fn get(coord: *const console.Coordinate) console.Point {
            const x: u16 = @intCast(coord[0]);
            const y: u16 = @intCast(coord[1]);
            return data[x + y * width];
        }

        fn set(coord: *const console.Coordinate, p: console.Point) void {
            const x: u16 = @intCast(coord[0]);
            const y: u16 = @intCast(coord[1]);
            data[x + y * width] = p;
        }

        fn draw_block(b: *const Block) void {
            cs.set_color(b.shape.color);
            if (!(b.coordinate[1] < 0)) {
                set(&b.coordinate, b.shape.color);
                cs.cursor_jump(&b.coordinate);
                cs.draw_one();
            }
            var coord: console.Coordinate = undefined;
            for (b.shape.get()) |c| {
                coord = b.coordinate + c;
                if (coord[1] < 0) continue;
                set(&coord, b.shape.color);
                cs.cursor_jump(&coord);
                cs.draw_one();
            }
        }

        fn clear_block(b: *const Block) void {
            if (!(b.coordinate[1] < 0)) {
                set(&b.coordinate, null);
                cs.cursor_jump(&b.coordinate);
                cs.clear_one();
            }
            var coord: console.Coordinate = undefined;
            for (b.shape.get()) |c| {
                coord = b.coordinate + c;
                if (coord[1] < 0) continue;
                set(&coord, null);
                cs.cursor_jump(&coord);
                cs.clear_one();
            }
        }

        fn preview_block(b: *const Block) void {
            const S = struct {
                const coord: console.Coordinate = .{width + 12, 2};
                var last_block: ?*const Block = null;
            };
            var coord: console.Coordinate = undefined;
            if (S.last_block) |bb| {
                cs.cursor_jump(&S.coord);
                cs.clear_one();
                for (bb.shape.get()) |c| {
                    coord = S.coord + c;
                    cs.cursor_jump(&coord);
                    cs.clear_one();
                }
            }
            cs.set_color(b.shape.color);
            cs.cursor_jump(&S.coord);
            cs.draw_one();
            for (b.shape.get()) |c| {
                coord = S.coord + c;
                cs.cursor_jump(&coord);
                cs.draw_one();
            }
            S.last_block = b;
        }

        fn should_stop_block(b: *const Block) bool {
            if (!(b.coordinate[1] < 0)) {
                if (get(&b.coordinate) != null) {
                    return true;
                }
            }
            var coord: console.Coordinate = undefined;
            for (b.shape.get()) |c| {
                coord = b.coordinate + c;
                if (coord[1] < 0) continue;
                if (coord[0] < 0 or coord[0] > width - 1) return true;
                if (get(&coord) != null) {
                    return true;
                }
            }
            return false;
        }

        fn arrive_bottom(b: *const Block) bool {
            var max_y: i16 = 0;
            for (b.shape.get()) |coord| {
                max_y = @max(coord[1], max_y);
            }
            if (max_y + b.coordinate[1] == height - 1) {
                return true;
            }
            return false;
        }

        fn overflow(b: *const Block) bool {
            var min_y: i16 = 0;
            for (b.shape.get()) |coord| {
                min_y = @min(coord[1], min_y);
            }
            if (!(min_y + b.coordinate[1] > 0)) {
                return true;
            }
            return false;
        }

        fn touch_side(b: *const Block, direction: Direction) bool {
            return switch (direction) {
                .LEFT => blk: {
                    var min_x: i16 = 0;
                    for (b.shape.get()) |coord| {
                        min_x = @min(coord[0], min_x);
                    }
                    break:blk min_x + b.coordinate[0] == 0;
                },
                .RIGHT => blk: {
                    var max_x: i16 = 0;
                    for (b.shape.get()) |coord| {
                        max_x = @max(coord[0], max_x);
                    }
                    break:blk max_x + b.coordinate[0] == width - 1;
                },
                else => unreachable,
            };
        }

        fn out_of_range(b: *const Block) bool {
            var max_y: i16 = 0;
            var min_x: i16 = 0;
            var max_x: i16 = 0;
            for (b.shape.get()) |coord| {
                max_y = @max(coord[1], max_y);
                min_x = @min(coord[0], min_x);
                max_x = @max(coord[0], max_x);
            }
            return (min_x + b.coordinate[0] < 0
                or max_x + b.coordinate[0] > width - 1
                or max_y + b.coordinate[1] > height - 1);
        }

        fn show_score(score: u32) void {
            const S = struct {
                const coord: console.Coordinate = .{width + 6, height - 3};
            };
            cs.cursor_jump(&S.coord);
            _ = std.c.printf("   ");
            _ = std.c.printf("%d", score);
        }

        fn try_eliminate() u32 {
            var need_eliminate: bool = undefined;
            var empty: bool = undefined;
            var row: u32 = height - 1;
            var redraw_row = row;
            defer while (redraw_row != row): (redraw_row -= 1) {
                const y: i16 = @intCast(redraw_row);
                var x: i16 = undefined;
                for (0..width) |col| {
                    x = @intCast(col);
                    cs.cursor_jump(&console.Coordinate{x, y});
                    cs.clear_one();
                    data[redraw_row * width + col] = null;
                }
            };
            while (row > 0): (row -= 1) {
                need_eliminate = true;
                empty = true;
                for (0..width) |col| {
                    if (data[row * width + col] == null) {
                        need_eliminate = false;
                    } else {
                        empty = false;
                    }
                }
                if (empty) break;
                if (!need_eliminate) {
                    if (row != redraw_row) {
                        const y: i16 = @intCast(redraw_row);
                        var x: i16 = undefined;
                        var point: console.Point = undefined;
                        for (0..width) |col| {
                            x = @intCast(col);
                            point = data[row * width + col];
                            cs.cursor_jump(&console.Coordinate{x, y});
                            if (point) |p| {
                                cs.set_color(p);
                                cs.draw_one();
                            } else {
                                cs.clear_one();
                            }
                            data[redraw_row * width + col] = point;
                        }
                    }
                    redraw_row -= 1;
                }
            }
            return redraw_row - row;
        }

        fn try_move_down(b: *Block) GameError!void {
            if (arrive_bottom(b)) {
                return GameError.StopError;
            } else {
                clear_block(b);
                b.move(.DOWN);
                if (should_stop_block(b)) {
                    b.move(.UP);
                    draw_block(b);
                    if (overflow(b)) {
                        return GameError.OverflowError;
                    }
                    return GameError.StopError;
                }
            }
            draw_block(b);
        }

        fn switch_current_block(
            self: *const @This(),
        ) *Block {
            const S = struct {
                var block1: Block = undefined;
                var block2: Block = undefined;
                var current_block: ?*Block = null;
            };
            if (S.current_block == null) {
                S.block1 = Block.init(width / 2, self.rand_impl);
                S.block2 = Block.init(width / 2, self.rand_impl);
                S.current_block = &S.block1;
                preview_block(&S.block2);
            } else {
                if (S.current_block == &S.block1) {
                    S.current_block = &S.block2;
                    S.block1 = Block.init(width / 2, self.rand_impl);
                    preview_block(&S.block1);
                } else {
                    S.current_block = &S.block1;
                    S.block2 = Block.init(width / 2, self.rand_impl);
                    preview_block(&S.block2);
                }
            }
            return S.current_block.?;
        }

        pub fn start(self: *@This()) GameError!void {
            cs.draw_ui();
            cs.hide_cursor();
            defer {
                cs.cursor_jump(&console.Coordinate{0, height + 1});
                data = [1]console.Point{null} ** (width * height);
            }

            var current_block: *Block = self.switch_current_block();
            draw_block(current_block);
            var score: u32 = 0;
            show_score(score);
            var i: i64 = undefined;
            return game_loop: while (true) {
                i = self.init_interval - score;
                while (i > 0): (i -= 1) {
                    if (conio.kbhit() != 0) {
                        switch (conio.getch()) {
                            ESC => break:game_loop GameError.UserExit,
                            SPACE => while (
                                conio.kbhit() == 0 or blk: {
                                    const k = conio.getch();
                                    if (k == ESC) break:game_loop GameError.UserExit;
                                    break:blk k != 32;
                                }
                            ) std.time.sleep(1e8),
                            UP => {
                                clear_block(current_block);
                                current_block.shape.rotate(.{});
                                if (should_stop_block(current_block) or out_of_range(current_block)) {
                                    current_block.shape.rotate(.{.reverse = true});
                                }
                                draw_block(current_block);
                            },
                            LEFT, RIGHT => |k| {
                                const direction: [2]Direction = switch (k) {
                                    LEFT => .{.LEFT, .RIGHT},
                                    RIGHT => .{.RIGHT, .LEFT},
                                    else => unreachable,
                                };
                                if (!touch_side(current_block, direction[0])) {
                                    clear_block(current_block);
                                    current_block.move(direction[0]);
                                    if (should_stop_block(current_block)) {
                                        current_block.move(direction[1]);
                                    }
                                    draw_block(current_block);
                                }
                            },
                            DOWN => {
                                try_move_down(current_block) catch |err| switch (err) {
                                    GameError.StopError => {
                                        current_block = self.switch_current_block();
                                        score += 10 * std.math.pow(u32, try_eliminate(), 2);
                                        show_score(score);
                                    },
                                    GameError.OverflowError => break:game_loop,
                                    else => unreachable,
                                };
                            },
                            else => {},
                        }
                    }
                }

                try_move_down(current_block) catch |err| switch (err) {
                    GameError.StopError => {
                        current_block = self.switch_current_block();
                        score += 10 * std.math.pow(u32, try_eliminate(), 2);
                        show_score(score);
                    },
                    GameError.OverflowError => break:game_loop,
                    else => unreachable,
                };
            };
        }
    };
}
