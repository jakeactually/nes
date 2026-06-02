const std = @import("std");

pub const HWND = ?*anyopaque;
pub const HINSTANCE = ?*anyopaque;
pub const HICON = ?*anyopaque;
pub const HCURSOR = ?*anyopaque;
pub const HBRUSH = ?*anyopaque;
pub const HDC = ?*anyopaque;
pub const HPEN = ?*anyopaque;
pub const HGDIOBJ = ?*anyopaque;
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
pub extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) HDC;
pub extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *const PAINTSTRUCT) i32;

pub extern "gdi32" fn Rectangle(hdc: HDC, left: i32, top: i32, right: i32, bottom: i32) i32;
pub extern "gdi32" fn CreatePen(iStyle: i32, cWidth: i32, color: u32) HPEN;
pub extern "gdi32" fn SelectObject(hdc: HDC, h: HGDIOBJ) HGDIOBJ;
pub extern "gdi32" fn DeleteObject(ho: HGDIOBJ) i32;
pub extern "gdi32" fn GetStockObject(i: i32) HGDIOBJ;
pub extern "gdi32" fn CreateSolidBrush(color: u32) HBRUSH;

pub extern "user32" fn FillRect(hdc: HDC, lprc: *const RECT, hbr: HBRUSH) i32;
pub extern "user32" fn InvalidateRect(hWnd: HWND, lpRect: ?*const RECT, bErase: i32) i32;
pub extern "user32" fn SetTimer(
    hWnd: HWND,
    nIDEvent: usize,
    uElapse: UINT,
    lpTimerFunc: ?*anyopaque,
) usize;
pub extern "user32" fn KillTimer(hWnd: HWND, uIDEvent: usize) i32;

pub const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

pub const PAINTSTRUCT = extern struct {
    hdc: HDC,
    fErase: i32,
    rcPaint: RECT,
    fRestore: i32,
    fIncUpdate: i32,
    rgbReserved: [32]u8,
};

pub const PS_SOLID: i32 = 0;
pub const HOLLOW_BRUSH: i32 = 5;

pub const WM_DESTROY = 0x0002;
pub const WM_PAINT = 0x000F;
pub const WM_KEYDOWN = 0x0100;
pub const WM_KEYUP = 0x0101;
pub const WM_TIMER = 0x0113;
pub const WS_OVERLAPPEDWINDOW = 0x00CF0000;
pub const CW_USEDEFAULT = -2147483648;
