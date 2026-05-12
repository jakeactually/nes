const types = @import("types.zig");

pub fn opcode_info(opcode: u8) types.OpcodeInfo {
    return switch (opcode) {
        0x00 => types.OpcodeInfo{ .instruction = .brk, .mode = .implied },
        0xA9 => types.OpcodeInfo{ .instruction = .lda, .mode = .immediate },
        0xA5 => types.OpcodeInfo{ .instruction = .lda, .mode = .zero_page },
        0xE8 => types.OpcodeInfo{ .instruction = .inx, .mode = .implied },
        0x85 => types.OpcodeInfo{ .instruction = .sta, .mode = .zero_page },
        0x95 => types.OpcodeInfo{ .instruction = .sta, .mode = .zero_page_x },
        0xAA => types.OpcodeInfo{ .instruction = .tax, .mode = .implied },
        else => unreachable,
    };
}
