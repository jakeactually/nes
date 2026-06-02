const std = @import("std");
const types = @import("types.zig");
const cpu = @import("cpu.zig");
const windows = @import("windows.zig");

pub fn wndProc(
    hwnd: windows.HWND,
    msg: windows.UINT,
    wparam: windows.WPARAM,
    lparam: windows.LPARAM,
) callconv(.winapi) windows.LRESULT {
    switch (msg) {
        windows.WM_DESTROY => {
            windows.PostQuitMessage(0);
            return 0;
        },
        windows.WM_KEYDOWN, windows.WM_KEYUP => {
            const action: []const u8 = if (msg == windows.WM_KEYDOWN) "down" else "up";
            std.debug.print("key {s}: vk=0x{X}\n", .{ action, wparam });
            return 0;
        },
        else => return windows.DefWindowProcW(hwnd, msg, wparam, lparam),
    }
}

pub fn main() !void {
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
        800,
        600,
        null,
        null,
        null,
        null,
    );

    _ = windows.ShowWindow(hwnd, 1);
    _ = windows.UpdateWindow(hwnd);

    var msg: windows.MSG = undefined;
    while (windows.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = windows.TranslateMessage(&msg);
        _ = windows.DispatchMessageW(&msg);
    }
}
