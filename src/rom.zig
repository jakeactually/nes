const std = @import("std");
const types = @import("types.zig");

pub const NES_TAG = [_]u8{ 'N', 'E', 'S', 0x1A };
pub const PRG_ROM_PAGE_SIZE: usize = 16 * 1024;
pub const CHR_ROM_PAGE_SIZE: usize = 8 * 1024;

pub const ParseError = error{
    invalid_format,
    unsupported_format,
    truncated_rom,
};

pub fn parse_rom(raw: []const u8) !types.Rom {
    if (raw.len < 16) return ParseError.invalid_format;
    if (!std.mem.eql(u8, raw[0..4], &NES_TAG)) return ParseError.invalid_format;

    const mapper = (raw[7] & 0b1111_0000) | (raw[6] >> 4);
    const ines_ver = (raw[7] >> 2) & 0b11;
    if (ines_ver != 0) return ParseError.unsupported_format;

    const four_screen = (raw[6] & 0b1000) != 0;
    const vertical_mirroring = (raw[6] & 0b1) != 0;
    const screen_mirroring = if (four_screen)
        types.Mirroring.four_screen
    else if (vertical_mirroring)
        types.Mirroring.vertical
    else
        types.Mirroring.horizontal;

    const prg_rom_size = @as(usize, raw[4]) * PRG_ROM_PAGE_SIZE;
    const chr_rom_size = @as(usize, raw[5]) * CHR_ROM_PAGE_SIZE;
    const skip_trainer = (raw[6] & 0b100) != 0;

    const prg_rom_start = 16 + @as(usize, if (skip_trainer) 512 else 0);
    const chr_rom_start = prg_rom_start + prg_rom_size;

    if (raw.len < chr_rom_start + chr_rom_size) return ParseError.truncated_rom;

    if (prg_rom_size > 0xFFFFF) return ParseError.truncated_rom;

    var rom = types.Rom{
        .chr_rom = raw[chr_rom_start .. chr_rom_start + chr_rom_size],
        .mapper = mapper,
        .screen_mirroring = screen_mirroring,
    };
    @memcpy(rom.prg_rom[0..prg_rom_size], raw[prg_rom_start .. prg_rom_start + prg_rom_size]);
    return rom;
}
