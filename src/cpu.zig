const types = @import("types.zig");
const opcodes_info = @import("opcodes.zig").opcode_info;

pub const game_code = [_]u8{ 0x20, 0x06, 0x06, 0x20, 0x38, 0x06, 0x20, 0x0d, 0x06, 0x20, 0x2a, 0x06, 0x60, 0xa9, 0x02, 0x85, 0x02, 0xa9, 0x04, 0x85, 0x03, 0xa9, 0x11, 0x85, 0x10, 0xa9, 0x10, 0x85, 0x12, 0xa9, 0x0f, 0x85, 0x14, 0xa9, 0x04, 0x85, 0x11, 0x85, 0x13, 0x85, 0x15, 0x60, 0xa5, 0xfe, 0x85, 0x00, 0xa5, 0xfe, 0x29, 0x03, 0x18, 0x69, 0x02, 0x85, 0x01, 0x60, 0x20, 0x4d, 0x06, 0x20, 0x8d, 0x06, 0x20, 0xc3, 0x06, 0x20, 0x19, 0x07, 0x20, 0x20, 0x07, 0x20, 0x2d, 0x07, 0x4c, 0x38, 0x06, 0xa5, 0xff, 0xc9, 0x77, 0xf0, 0x0d, 0xc9, 0x64, 0xf0, 0x14, 0xc9, 0x73, 0xf0, 0x1b, 0xc9, 0x61, 0xf0, 0x22, 0x60, 0xa9, 0x04, 0x24, 0x02, 0xd0, 0x26, 0xa9, 0x01, 0x85, 0x02, 0x60, 0xa9, 0x08, 0x24, 0x02, 0xd0, 0x1b, 0xa9, 0x02, 0x85, 0x02, 0x60, 0xa9, 0x01, 0x24, 0x02, 0xd0, 0x10, 0xa9, 0x04, 0x85, 0x02, 0x60, 0xa9, 0x02, 0x24, 0x02, 0xd0, 0x05, 0xa9, 0x08, 0x85, 0x02, 0x60, 0x60, 0x20, 0x94, 0x06, 0x20, 0xa8, 0x06, 0x60, 0xa5, 0x00, 0xc5, 0x10, 0xd0, 0x0d, 0xa5, 0x01, 0xc5, 0x11, 0xd0, 0x07, 0xe6, 0x03, 0xe6, 0x03, 0x20, 0x2a, 0x06, 0x60, 0xa2, 0x02, 0xb5, 0x10, 0xc5, 0x10, 0xd0, 0x06, 0xb5, 0x11, 0xc5, 0x11, 0xf0, 0x09, 0xe8, 0xe8, 0xe4, 0x03, 0xf0, 0x06, 0x4c, 0xaa, 0x06, 0x4c, 0x35, 0x07, 0x60, 0xa6, 0x03, 0xca, 0x8a, 0xb5, 0x10, 0x95, 0x12, 0xca, 0x10, 0xf9, 0xa5, 0x02, 0x4a, 0xb0, 0x09, 0x4a, 0xb0, 0x19, 0x4a, 0xb0, 0x1f, 0x4a, 0xb0, 0x2f, 0xa5, 0x10, 0x38, 0xe9, 0x20, 0x85, 0x10, 0x90, 0x01, 0x60, 0xc6, 0x11, 0xa9, 0x01, 0xc5, 0x11, 0xf0, 0x28, 0x60, 0xe6, 0x10, 0xa9, 0x1f, 0x24, 0x10, 0xf0, 0x1f, 0x60, 0xa5, 0x10, 0x18, 0x69, 0x20, 0x85, 0x10, 0xb0, 0x01, 0x60, 0xe6, 0x11, 0xa9, 0x06, 0xc5, 0x11, 0xf0, 0x0c, 0x60, 0xc6, 0x10, 0xa5, 0x10, 0x29, 0x1f, 0xc9, 0x1f, 0xf0, 0x01, 0x60, 0x4c, 0x35, 0x07, 0xa0, 0x00, 0xa5, 0xfe, 0x91, 0x00, 0x60, 0xa6, 0x03, 0xa9, 0x00, 0x81, 0x10, 0xa2, 0x00, 0xa9, 0x01, 0x81, 0x10, 0x60, 0xa2, 0x00, 0xea, 0xea, 0xca, 0xd0, 0xfb, 0x60 };

/// Test ROM at $0600: copy $FE -> $0200, then loop.
///   LDA $FE      ; A5 FE
///   STA $0200    ; 8D 00 02
///   JMP $0600    ; 4C 00 06
pub const test_game_code = [_]u8{
    0xA5, 0xFE,
    0x8D, 0x00,
    0x02, 0x4C,
    0x00, 0x06,
};

fn reset(cpu: *types.CPU) void {
    cpu.program_counter = @as(u16, cpu.memory[0xFFFC + 1]) << 8 | cpu.memory[0xFFFC];
}

fn load(cpu: *types.CPU, program: []const u8) void {
    @memcpy(cpu.memory[0x0600 .. 0x0600 + program.len], program);
    cpu.memory[0xFFFC + 1] = 0x06;
}

pub fn load_and_reset(cpu: *types.CPU, program: []const u8) void {
    load(cpu, program);
    reset(cpu);
}

fn update_zero_and_negative_flags(cpu: *types.CPU, value: u8) void {
    cpu.status.zero = value == 0;
    cpu.status.negative = value >> 7 == 1;
}

fn get_operand_address(cpu: *types.CPU, mode: types.AddressingMode) u16 {
    const current = cpu.memory[cpu.program_counter];

    return switch (mode) {
        .immediate => cpu.program_counter,
        .zero_page => current,
        .zero_page_x => current +% cpu.register_x,
        .zero_page_y => current +% cpu.register_y,
        .absolute => @as(u16, cpu.memory[cpu.program_counter + 1]) << 8 | current,
        .absolute_x => get_operand_address(cpu, .absolute) +% cpu.register_x,
        .absolute_y => get_operand_address(cpu, .absolute) +% cpu.register_y,
        .indirect => {
            const ptr = get_operand_address(cpu, .absolute);
            return @as(u16, cpu.memory[ptr +% 1]) << 8 | cpu.memory[ptr];
        },
        .indirect_x => {
            const ptr = get_operand_address(cpu, .zero_page_x);
            return @as(u16, cpu.memory[ptr +% 1]) << 8 | cpu.memory[ptr];
        },
        .indirect_y => {
            const base = @as(u16, cpu.memory[current +% 1]) << 8 | cpu.memory[current];
            return base +% cpu.register_y;
        },
        .relative => current,
        else => 0,
    };
}

fn instruction_offset(mode: types.AddressingMode) u16 {
    return switch (mode) {
        .absolute => 2,
        .absolute_x => 2,
        .absolute_y => 2,
        .implied => 0,
        .accumulator => 0,
        .relative => 0,
        else => 1,
    };
}

fn branch(cpu: *types.CPU, condition: bool) void {
    if (condition) {
        const jump: i8 = @bitCast(cpu.memory[cpu.program_counter]);
        const jump_addr = cpu.program_counter +% 1 +% @as(u16, @bitCast(@as(i16, jump)));
        cpu.program_counter = jump_addr;
    } else {
        cpu.program_counter += 1;
    }
}

fn stack_push(cpu: *types.CPU, value: u8) void {
    const stack_addr = 0x100 + @as(u16, cpu.stack_pointer);
    cpu.memory[stack_addr] = value;
    cpu.stack_pointer -%= 1;
}

fn stack_pop(cpu: *types.CPU) u8 {
    cpu.stack_pointer +%= 1;
    const stack_addr = 0x100 + @as(u16, cpu.stack_pointer);
    return cpu.memory[stack_addr];
}

fn stack_push_u16(cpu: *types.CPU, value: u16) void {
    stack_push(cpu, @truncate(value >> 8));
    stack_push(cpu, @truncate(value));
}

fn stack_pop_u16(cpu: *types.CPU) u16 {
    const low = stack_pop(cpu);
    const high = stack_pop(cpu);
    return @as(u16, high) << 8 | low;
}

pub fn step(cpu: *types.CPU) bool {
    const opcode = cpu.memory[cpu.program_counter];
    cpu.program_counter += 1;
    const info = opcodes_info(opcode);
    const addr = get_operand_address(cpu, info.mode);

    switch (info.instruction) {
        .adc => {
            const data = cpu.memory[addr];
            const sum = @as(u16, cpu.accumulator) + data + @intFromBool(cpu.status.carry);
            const result: u8 = @truncate(sum);
            cpu.status.carry = sum > 0xff;
            cpu.status.overflow = (data ^ result) & (result ^ cpu.accumulator) & 0x80 != 0;
            cpu.accumulator = result;
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
        .and_ => {
            cpu.accumulator &= cpu.memory[addr];
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
        .asl => {
            const target = if (info.mode == .accumulator) &cpu.accumulator else &cpu.memory[addr];
            cpu.status.carry = target.* >> 7 == 1;
            target.* <<= 1;
            update_zero_and_negative_flags(cpu, target.*);
        },
        .bcc => {
            branch(cpu, !cpu.status.carry);
        },
        .bcs => {
            branch(cpu, cpu.status.carry);
        },
        .beq => {
            branch(cpu, cpu.status.zero);
        },
        .bit => {
            const value = cpu.memory[addr];
            cpu.status.zero = cpu.accumulator & value == 0;
            cpu.status.overflow = value >> 6 & 1 == 1;
            cpu.status.negative = value >> 7 == 1;
        },
        .bmi => {
            branch(cpu, cpu.status.negative);
        },
        .bne => {
            branch(cpu, !cpu.status.zero);
        },
        .bpl => {
            branch(cpu, !cpu.status.negative);
        },
        .brk => {
            return false;
        },
        .bvc => {
            branch(cpu, !cpu.status.overflow);
        },
        .bvs => {
            branch(cpu, cpu.status.overflow);
        },
        .clc => {
            cpu.status.carry = false;
        },
        .cld => {
            cpu.status.decimal = false;
        },
        .cli => {
            cpu.status.interrupt = false;
        },
        .clv => {
            cpu.status.overflow = false;
        },
        .cmp => {
            const value = cpu.memory[addr];
            cpu.status.carry = cpu.accumulator <= value;
            update_zero_and_negative_flags(cpu, cpu.accumulator -% value);
        },
        .cpx => {
            const value = cpu.memory[addr];
            cpu.status.carry = cpu.register_x <= value;
            update_zero_and_negative_flags(cpu, cpu.register_x -% value);
        },
        .cpy => {
            const value = cpu.memory[addr];
            cpu.status.carry = cpu.register_y <= value;
            update_zero_and_negative_flags(cpu, cpu.register_y -% value);
        },
        .dec => {
            cpu.memory[addr] -%= 1;
            update_zero_and_negative_flags(cpu, cpu.memory[addr]);
        },
        .dex => {
            cpu.register_x -%= 1;
            update_zero_and_negative_flags(cpu, cpu.register_x);
        },
        .dey => {
            cpu.register_y -%= 1;
            update_zero_and_negative_flags(cpu, cpu.register_y);
        },
        .eor => {
            cpu.accumulator ^= cpu.memory[addr];
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
        .inc => {
            cpu.memory[addr] +%= 1;
            update_zero_and_negative_flags(cpu, cpu.memory[addr]);
        },
        .inx => {
            cpu.register_x +%= 1;
            update_zero_and_negative_flags(cpu, cpu.register_x);
        },
        .iny => {
            cpu.register_y +%= 1;
            update_zero_and_negative_flags(cpu, cpu.register_y);
        },
        .jmp => {
            cpu.program_counter = addr;
            return true;
        },
        .jsr => {
            stack_push_u16(cpu, cpu.program_counter + 2 - 1);
            cpu.program_counter = addr;
            return true;
        },
        .lda => {
            cpu.accumulator = cpu.memory[addr];
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
        .ldx => {
            cpu.register_x = cpu.memory[addr];
            update_zero_and_negative_flags(cpu, cpu.register_x);
        },
        .ldy => {
            cpu.register_y = cpu.memory[addr];
            update_zero_and_negative_flags(cpu, cpu.register_y);
        },
        .lsr => {
            const target = if (info.mode == .accumulator) &cpu.accumulator else &cpu.memory[addr];
            cpu.status.carry = target.* & 1 == 1;
            target.* >>= 1;
            update_zero_and_negative_flags(cpu, target.*);
        },
        .nop => {
            // Do nothing
        },
        .ora => {
            cpu.accumulator |= cpu.memory[addr];
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
        .pha => {
            stack_push(cpu, cpu.accumulator);
        },
        .php => {
            var status_copy = cpu.status;
            status_copy.break_ = true;
            status_copy.ignored = true;
            stack_push(cpu, types.status_to_byte(status_copy));
        },
        .pla => {
            cpu.accumulator = stack_pop(cpu);
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
        .plp => {
            cpu.status = types.byte_to_status(stack_pop(cpu));
            cpu.status.break_ = false;
            cpu.status.ignored = true;
        },
        .rol => {
            const target = if (info.mode == .accumulator) &cpu.accumulator else &cpu.memory[addr];
            const next_carry = target.* >> 7 == 1;
            target.* = target.* << 1 | @intFromBool(cpu.status.carry);
            cpu.status.carry = next_carry;
            update_zero_and_negative_flags(cpu, target.*);
        },
        .ror => {
            const target = if (info.mode == .accumulator) &cpu.accumulator else &cpu.memory[addr];
            const next_carry = target.* & 1 == 1;
            target.* = target.* >> 1 | @as(u8, if (cpu.status.carry) 0x80 else 0);
            cpu.status.carry = next_carry;
            update_zero_and_negative_flags(cpu, target.*);
        },
        .rti => {
            cpu.status = types.byte_to_status(stack_pop(cpu));
            cpu.program_counter = stack_pop_u16(cpu);
            cpu.status.break_ = false;
            cpu.status.ignored = true;
        },
        .rts => {
            cpu.program_counter = stack_pop_u16(cpu) + 1;
        },
        .sbc => {
            const complement: i8 = @bitCast(cpu.memory[addr]);
            const data: u8 = @bitCast(-%complement -% 1);

            const sum = @as(u16, cpu.accumulator) + data + @intFromBool(cpu.status.carry);
            const result: u8 = @truncate(sum);
            cpu.status.carry = sum > 0xff;
            cpu.status.overflow = (data ^ result) & (result ^ cpu.accumulator) & 0x80 != 0;
            cpu.accumulator = result;
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
        .sec => {
            cpu.status.carry = true;
        },
        .sed => {
            cpu.status.decimal = true;
        },
        .sei => {
            cpu.status.interrupt = true;
        },
        .sta => {
            cpu.memory[addr] = cpu.accumulator;
        },
        .stx => {
            cpu.memory[addr] = cpu.register_x;
        },
        .sty => {
            cpu.memory[addr] = cpu.register_y;
        },
        .tax => {
            cpu.register_x = cpu.accumulator;
            update_zero_and_negative_flags(cpu, cpu.register_x);
        },
        .tay => {
            cpu.register_y = cpu.accumulator;
            update_zero_and_negative_flags(cpu, cpu.register_y);
        },
        .tsx => {
            cpu.register_x = cpu.stack_pointer;
            update_zero_and_negative_flags(cpu, cpu.register_x);
        },
        .txa => {
            cpu.accumulator = cpu.register_x;
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
        .txs => {
            cpu.stack_pointer = cpu.register_x;
        },
        .tya => {
            cpu.accumulator = cpu.register_y;
            update_zero_and_negative_flags(cpu, cpu.accumulator);
        },
    }

    cpu.program_counter += instruction_offset(info.mode);
    return true;
}

pub fn interpret(cpu: *types.CPU, program: []const u8) void {
    load_and_reset(cpu, program);
    while (step(cpu)) {}
}
