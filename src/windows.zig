const std = @import("std");

pub const HWND = ?*anyopaque;
pub const HINSTANCE = ?*anyopaque;
pub const HICON = ?*anyopaque;
pub const HCURSOR = ?*anyopaque;
pub const HBRUSH = ?*anyopaque;
pub const LPCWSTR = [*:0]const u16;
pub const UINT = u32;
pub const WPARAM = usize;
pub const LPARAM = isize;
pub const LRESULT = isize;

pub const MSG = extern struct {
    hwnd: HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: u32,
    pt_x: i32,
    pt_y: i32,
};

pub const WNDCLASSW = extern struct {
    style: u32,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(.winapi) LRESULT,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: HINSTANCE,
    hIcon: HICON,
    hCursor: HCURSOR,
    hbrBackground: HBRUSH,
    lpszMenuName: ?LPCWSTR,
    lpszClassName: LPCWSTR,
};

pub extern "user32" fn RegisterClassW(lpWndClass: *const WNDCLASSW) u16;

pub extern "user32" fn CreateWindowExW(
    dwExStyle: u32,
    lpClassName: LPCWSTR,
    lpWindowName: LPCWSTR,
    dwStyle: u32,
    X: i32,
    Y: i32,
    nWidth: i32,
    nHeight: i32,
    hWndParent: HWND,
    hMenu: ?*anyopaque,
    hInstance: HINSTANCE,
    lpParam: ?*anyopaque,
) HWND;

pub extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) i32;
pub extern "user32" fn UpdateWindow(hWnd: HWND) i32;
pub extern "user32" fn GetMessageW(
    lpMsg: *MSG,
    hWnd: HWND,
    wMsgFilterMin: UINT,
    wMsgFilterMax: UINT,
) i32;
pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) i32;
pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) LRESULT;
pub extern "user32" fn DefWindowProcW(
    hWnd: HWND,
    Msg: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
) LRESULT;
pub extern "user32" fn PostQuitMessage(exit_code: i32) void;

pub extern "kernel32" fn WriteFile(
    hFile: ?*anyopaque,
    lpBuffer: [*]const u8,
    nNumberOfBytesToWrite: u32,
    lpNumberOfBytesWritten: ?*u32,
    lpOverlapped: ?*anyopaque,
) callconv(.winapi) i32;

pub const WM_DESTROY = 0x0002;
pub const WM_KEYDOWN = 0x0100;
pub const WM_KEYUP = 0x0101;
pub const WS_OVERLAPPEDWINDOW = 0x00CF0000;
pub const CW_USEDEFAULT = -2147483648;

pub fn wndProc(
    hwnd: HWND,
    msg: UINT,
    wparam: WPARAM,
    lparam: LPARAM,
) callconv(.winapi) LRESULT {
    switch (msg) {
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        WM_KEYDOWN, WM_KEYUP => {
            var buf: [64]u8 = undefined;
            const action: []const u8 = if (msg == WM_KEYDOWN) "down" else "up";
            const text = std.fmt.bufPrint(&buf, "key {s}: vk=0x{X}\n", .{ action, wparam }) catch return 0;
            var written: u32 = undefined;
            _ = WriteFile(std.Io.File.stdout().handle, text.ptr, @intCast(text.len), &written, null);
            return 0;
        },
        else => return DefWindowProcW(hwnd, msg, wparam, lparam),
    }
}
