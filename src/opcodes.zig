const types = @import("types.zig");

pub fn opcode_info(opcode: u8) types.OpcodeInfo {
    return switch (opcode) {
        0xA9 => types.OpcodeInfo{ .instruction = .lda, .mode = .immediate },
        0xAA => types.OpcodeInfo{ .instruction = .tax, .mode = .implied },
        0xE8 => types.OpcodeInfo{ .instruction = .inx, .mode = .implied },
        else => types.OpcodeInfo{ .instruction = .brk, .mode = .implied },
    };
}
