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

        0x29 => types.OpcodeInfo{ .instruction = .and_, .mode = .immediate },
        0x25 => types.OpcodeInfo{ .instruction = .and_, .mode = .zero_page },
        0x35 => types.OpcodeInfo{ .instruction = .and_, .mode = .zero_page_x },
        0x2D => types.OpcodeInfo{ .instruction = .and_, .mode = .absolute },
        0x3D => types.OpcodeInfo{ .instruction = .and_, .mode = .absolute_x },
        0x39 => types.OpcodeInfo{ .instruction = .and_, .mode = .absolute_y },
        0x21 => types.OpcodeInfo{ .instruction = .and_, .mode = .indirect_x },
        0x31 => types.OpcodeInfo{ .instruction = .and_, .mode = .indirect_y },

        0x0A => types.OpcodeInfo{ .instruction = .asl, .mode = .accumulator },
        0x06 => types.OpcodeInfo{ .instruction = .asl, .mode = .zero_page },
        0x16 => types.OpcodeInfo{ .instruction = .asl, .mode = .zero_page_x },
        0x0E => types.OpcodeInfo{ .instruction = .asl, .mode = .absolute },
        0x1E => types.OpcodeInfo{ .instruction = .asl, .mode = .absolute_x },

        0x90 => types.OpcodeInfo{ .instruction = .bcc, .mode = .relative },

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
