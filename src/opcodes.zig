const types = @import("types.zig");

pub fn opcode_info(opcode: u8) types.OpcodeInfo {
    return switch (opcode) {
        0x69 => types.OpcodeInfo{ .instruction = .adc, .mode = .immediate },
        0x65 => types.OpcodeInfo{ .instruction = .adc, .mode = .zero_page },
        0x75 => types.OpcodeInfo{ .instruction = .adc, .mode = .zero_page_x },
        0x6D => types.OpcodeInfo{ .instruction = .adc, .mode = .absolute },
        0x7D => types.OpcodeInfo{ .instruction = .adc, .mode = .absolute_x },
        0x79 => types.OpcodeInfo{ .instruction = .adc, .mode = .absolute_y },
        0x61 => types.OpcodeInfo{ .instruction = .adc, .mode = .indirect_x },
        0x71 => types.OpcodeInfo{ .instruction = .adc, .mode = .indirect_y },

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
