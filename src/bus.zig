const std = @import("std");
const Bus = @import("types.zig").Bus;

pub const RAM: u16 = 0x0000;
pub const RAM_MIRRORS_END: u16 = 0x1FFF;
pub const PPU_REGISTERS: u16 = 0x2000;
pub const PPU_REGISTERS_MIRRORS_END: u16 = 0x3FFF;

pub fn mem_read(bus: *const Bus, addr: u16) u8 {
    if (addr >= RAM and addr <= RAM_MIRRORS_END) {
        const mirror_down_addr = addr & 0b00000111_11111111;
        return bus.cpu_vram[mirror_down_addr];
    } else if (addr >= PPU_REGISTERS and addr <= PPU_REGISTERS_MIRRORS_END) {
        // const _mirror_down_addr = addr & 0b00100000_00000111;
        std.debug.print("PPU is not supported yet\n", .{});
        unreachable;
    } else {
        std.debug.print("Ignoring mem access at {}\n", .{addr});
        return 0;
    }
}

pub fn mem_write(bus: *Bus, addr: u16, data: u8) void {
    if (addr >= RAM and addr <= RAM_MIRRORS_END) {
        const mirror_down_addr = addr & 0b11111111111;
        bus.cpu_vram[mirror_down_addr] = data;
    } else if (addr >= PPU_REGISTERS and addr <= PPU_REGISTERS_MIRRORS_END) {
        // const _mirror_down_addr = addr & 0b00100000_00000111;
        std.debug.print("PPU is not supported yet\n", .{});
        unreachable;
    } else {
        std.debug.print("Ignoring mem write-access at {}\n", .{addr});
    }
}

pub fn mem_read_u16(bus: *const Bus, pos: u16) u16 {
    const lo = mem_read(bus, pos);
    const hi = mem_read(bus, pos + 1);
    return @as(u16, hi) << 8 | lo;
}

pub fn mem_write_u16(bus: *Bus, pos: u16, data: u16) void {
    const lo: u8 = @truncate(data);
    const hi: u8 = @truncate(data >> 8);
    mem_write(bus, pos, lo);
    mem_write(bus, pos + 1, hi);
}
