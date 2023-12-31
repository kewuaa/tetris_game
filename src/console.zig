const std = @import("std");
const builtin = @import("builtin");
const console = switch (builtin.target.os.tag) {
    .windows => struct {
        const windows = @cImport(@cInclude("windows.h"));

        pub fn init(
            comptime title: [*:0]const u8,
            comptime width: comptime_int,
            comptime height: comptime_int,
        ) void {
            // set console encoding to utf-8
            _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
            // set console title
            _ = windows.system(std.fmt.comptimePrint("title {s}", .{title}));
            // set console size
            _ = windows.system(std.fmt.comptimePrint("mode con lines={d} cols={d}", .{height + 3, width + 20}));
        }

        /// hide console cursor
        pub fn hide_cursor() void {
            const cursor_info: windows.CONSOLE_CURSOR_INFO = .{
                .dwSize = 1,
                .bVisible = 0,
            };
            const handle = windows.GetStdHandle(windows.STD_OUTPUT_HANDLE);
            _ = windows.SetConsoleCursorInfo(handle, &cursor_info);
        }

        /// set the position of console cursor
        pub fn cursor_jump(x: i16, y: i16) void {
            const pos: windows.COORD = .{
                .X = x,
                .Y = y,
            };
            const handle = windows.GetStdHandle(windows.STD_OUTPUT_HANDLE);
            _ = windows.SetConsoleCursorPosition(handle, pos);
        }

        /// set color
        pub fn set_color(color: Color) void {
            const c: c_ushort = @intFromEnum(color) + 8;
            const handle = windows.GetStdHandle(windows.STD_OUTPUT_HANDLE);
            _ = windows.SetConsoleTextAttribute(handle, c);
        }
    },
    else => @compileError("unsupport platform"),
};

pub const Coordinate = @Vector(2, i16);

pub const Color = enum(u16) {
    GRAY,
    BLUE,
    GREEN,
    SKY,
    RED,
    PURPER,
    YELLOW,
    WHITE,
};

pub const Point = ?Color;

/// initialize console
pub fn init(
    comptime title: [*:0]const u8,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    const offset: Coordinate = .{1, 1};
    return struct {
        /// draw ui in console
        pub fn draw_ui() void {
            if (builtin.target.os.tag == .windows) {
                console.init(title, width, height);
            }

            // draw ui
            const ui = comptime blk: {
                const line = "━" ** width;
                const middle = "┃" ++ " " ** width ++ "┃";
                const ui = "┏" ++ line ++ "┓\n"
                    ++ middle ++ " 下一个：\n"
                    ++ (middle ++ "\n") ** 9
                    ++ middle ++ " ↑ -> 旋转\n"
                    ++ middle ++ " ↓ -> 加速\n"
                    ++ middle ++ " ← -> 左移\n"
                    ++ middle ++ " → -> 右移\n"
                    ++ middle ++ " ESC -> 退出\n"
                    ++ middle ++ " 空格 -> 暂停\n"
                    ++ (middle ++ "\n") ** (height - 20)
                    ++ middle ++ " score:\n"
                    ++ (middle ++ "\n") ** 3
                    ++ "┗" ++ line ++ "┛\n";
                break:blk ui;
            };
            set_color(.WHITE);
            _ = std.c.printf(ui);
        }

        /// hide console cursor
        pub fn hide_cursor() void {
            console.hide_cursor();
        }

        /// set the position of console cursor
        pub fn cursor_jump(relative_coord: *const Coordinate) void {
            const real_coord = relative_coord.* + offset;
            console.cursor_jump(real_coord[0], real_coord[1]);
        }

        /// set color
        pub fn set_color(color: Color) void {
            console.set_color(color);
        }

        pub fn draw_one() void {
            _ = std.c.printf("■");
        }

        pub fn clear_one() void {
            _ = std.c.printf(" ");
        }
    };
}
