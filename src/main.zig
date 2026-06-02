const std = @import("std");
const types = @import("types.zig");
const cpu_mod = @import("cpu.zig");
const windows = @import("windows.zig");

const PIXEL_SIZE = 10;
const TIMER_ID: usize = 1;
const TICK_MS: windows.UINT = 32;
const MEMORY_BASE: usize = 0x0200;
const MEMORY_END: usize = 0x0600;
const GRID_SIZE: usize = 32;

var cpu = types.CPU{};
var prng = std.Random.DefaultPrng.init(0x1234_5678_9ABC_DEF0);

fn renderMemory(hdc: windows.HDC) void {
    var y: usize = 0;
    while (y < GRID_SIZE) : (y += 1) {
        var x: usize = 0;
        while (x < GRID_SIZE) : (x += 1) {
            const byte = cpu.memory[MEMORY_BASE + y * GRID_SIZE + x];
            const brush = windows.CreateSolidBrush(types.color(byte));
            var rect = windows.RECT{
                .left = @intCast(x * PIXEL_SIZE),
                .top = @intCast(y * PIXEL_SIZE),
                .right = @intCast((x + 1) * PIXEL_SIZE),
                .bottom = @intCast((y + 1) * PIXEL_SIZE),
            };
            _ = windows.FillRect(hdc, &rect, brush);
            _ = windows.DeleteObject(brush);
        }
    }
}

pub fn wndProc(
    hwnd: windows.HWND,
    msg: windows.UINT,
    wparam: windows.WPARAM,
    lparam: windows.LPARAM,
) callconv(.winapi) windows.LRESULT {
    switch (msg) {
        windows.WM_TIMER => {
            if (wparam != TIMER_ID) return 0;
            _ = windows.InvalidateRect(hwnd, null, 0);
            return 0;
        },
        windows.WM_PAINT => {
            var ps: windows.PAINTSTRUCT = undefined;
            const hdc = windows.BeginPaint(hwnd, &ps);
            renderMemory(hdc);
            _ = windows.EndPaint(hwnd, &ps);
            return 0;
        },
        windows.WM_DESTROY => {
            _ = windows.KillTimer(hwnd, TIMER_ID);
            windows.PostQuitMessage(0);
            return 0;
        },
        windows.WM_KEYDOWN => {
            cpu.memory[0xff] = @truncate(wparam + 0x20);
            return 0;
        },
        else => return windows.DefWindowProcW(hwnd, msg, wparam, lparam),
    }
}

pub fn main() !void {
    cpu_mod.load_and_reset(&cpu, &cpu_mod.game_code);

    const class_name = std.unicode.utf8ToUtf16LeStringLiteral("MyWindowClass");
    const title = std.unicode.utf8ToUtf16LeStringLiteral("Hello from Zig");

    var wc = windows.WNDCLASSW{
        .style = 0,
        .lpfnWndProc = wndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = null,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = @ptrFromInt(6), // COLOR_WINDOW + 1
        .lpszMenuName = null,
        .lpszClassName = class_name,
    };

    _ = windows.RegisterClassW(&wc);

    const hwnd = windows.CreateWindowExW(
        0,
        class_name,
        title,
        windows.WS_OVERLAPPEDWINDOW,
        windows.CW_USEDEFAULT,
        windows.CW_USEDEFAULT,
        32 * PIXEL_SIZE,
        32 * PIXEL_SIZE,
        null,
        null,
        null,
        null,
    );

    _ = windows.ShowWindow(hwnd, 1);
    _ = windows.UpdateWindow(hwnd);
    _ = windows.SetTimer(hwnd, TIMER_ID, TICK_MS, null);

    var msg: windows.MSG = undefined;

    while (true) {
        cpu.memory[0xfe] = prng.random().int(u8);

        for (0..60) |_| {
            _ = cpu_mod.step(&cpu);
        }

        if (windows.GetMessageW(&msg, null, 0, 0) > 0) {
            _ = windows.TranslateMessage(&msg);
            _ = windows.DispatchMessageW(&msg);
        }
    }
}
