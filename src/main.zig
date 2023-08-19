const std = @import("std");
const tetris = @import("tetrix.zig");
const c = @cImport(@cInclude("stdio.h"));

const WIDTH = 20;
const HEIGHT = 24;

pub fn main() !void {
    const time_stamp: u64 = @intCast(std.time.timestamp());
    var rand_impl = std.rand.DefaultPrng.init(time_stamp);
    var game = tetris.init("Tetris", WIDTH, HEIGHT){.rand_impl = &rand_impl};
    while (true) {
        game.start() catch break;
        _ = std.c.printf("if once again(\"n\" to quit):");
        if (c.getchar() == 'n') {
            break;
        } else game.reinit();
    }
}
