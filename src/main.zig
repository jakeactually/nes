const std = @import("std");
const types = @import("types.zig");
const opcodes_info = @import("opcodes.zig").opcode_info;

pub fn main() !void {}

fn reset(cpu: *types.CPU) void {
    cpu.program_counter = @as(u16, cpu.memory[0xFFFC + 1]) << 8 | cpu.memory[0xFFFC];
}

fn load(cpu: *types.CPU, program: []const u8) void {
    @memcpy(cpu.memory[0x8000 .. 0x8000 + program.len], program);
    cpu.memory[0xFFFC + 1] = 0x80;
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

fn branch(cpu: *types.CPU, condition: bool, addr: u16) void {
    if (condition) {
        const jump: i8 = @bitCast(@as(u8, @truncate(addr)));
        if (condition) cpu.program_counter +%= 1 +% @as(u16, @bitCast(@as(i16, jump)));
    }
}

pub fn interpret(cpu: *types.CPU, program: []const u8) void {
    load(cpu, program);
    reset(cpu);

    while (true) {
        const opcode = cpu.memory[cpu.program_counter];
        cpu.program_counter += 1;
        const info = opcodes_info(opcode);
        const addr = get_operand_address(cpu, info.mode);

        switch (info.instruction) {
            .adc => {
                const data = @as(u16, cpu.memory[addr]);
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
                branch(cpu, !cpu.status.carry, addr);
            },
            .bcs => {
                branch(cpu, cpu.status.carry, addr);
            },
            .beq => {
                branch(cpu, cpu.status.zero, addr);
            },
            .bit => {
                const value = cpu.memory[addr];
                cpu.status.zero = cpu.accumulator & value == 0;
                cpu.status.overflow = value >> 6 & 1 == 1;
                cpu.status.negative = value >> 7 == 1;
            },
            .bmi => {
                branch(cpu, cpu.status.negative, addr);
            },
            .bne => {
                branch(cpu, !cpu.status.zero, addr);
            },
            .bpl => {
                branch(cpu, !cpu.status.negative, addr);
            },
            .brk => {
                return;
            },
            .bvc => {
                branch(cpu, !cpu.status.overflow, addr);
            },
            .bvs => {
                branch(cpu, cpu.status.overflow, addr);
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
                cpu.status.carry = cpu.accumulator >= value;
                cpu.status.zero = cpu.accumulator == value;
                cpu.status.negative = value >> 7 == 1;
            },
            .cpx => {
                const value = cpu.memory[addr];
                cpu.status.carry = cpu.register_x >= value;
                cpu.status.zero = cpu.register_x == value;
                cpu.status.negative = value >> 7 == 1;
            },
            .cpy => {
                const value = cpu.memory[addr];
                cpu.status.carry = cpu.register_y >= value;
                cpu.status.zero = cpu.register_y == value;
                cpu.status.negative = value >> 7 == 1;
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
                continue;
            },
            .jsr => {
                const stack_addr = 0x100 + @as(u16, cpu.stack_pointer);
                const return_addr = cpu.program_counter + 1;
                cpu.memory[stack_addr] = @truncate(return_addr >> 8);
                cpu.memory[stack_addr -% 1] = @truncate(return_addr);
                cpu.stack_pointer -%= 2;
                cpu.program_counter = addr;
                continue;
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
                const stack_addr = 0x100 + @as(u16, cpu.stack_pointer);
                cpu.memory[stack_addr] = cpu.accumulator;
                cpu.stack_pointer -%= 1;
            },
            .php => {
                const stack_addr = 0x100 + @as(u16, cpu.stack_pointer);
                cpu.memory[stack_addr] = types.status_to_byte(cpu.status);
                cpu.stack_pointer -%= 1;
            },
            .pla => {
                const stack_addr = 0x100 + @as(u16, cpu.stack_pointer);
                cpu.accumulator = cpu.memory[stack_addr];
                cpu.stack_pointer +%= 1;
                update_zero_and_negative_flags(cpu, cpu.accumulator);
            },
            .plp => {
                const stack_addr = 0x100 + @as(u16, cpu.stack_pointer);
                cpu.status = types.byte_to_status(cpu.memory[stack_addr]);
                cpu.stack_pointer +%= 1;
            },
            .rol => {
                const target = if (info.mode == .accumulator) &cpu.accumulator else &cpu.memory[addr];
                const next_carry = target.* >> 7 == 1;
                target.* = target.* << 1 | @as(u8, if (cpu.status.carry) 1 else 0);
                cpu.status.carry = next_carry;
                update_zero_and_negative_flags(cpu, target.*);
            },
            .ror => {
                const target = if (info.mode == .accumulator) &cpu.accumulator else &cpu.memory[addr];
                const next_carry = target.* & 1 == 1;
                target.* = target.* >> 1 | @as(u8, if (cpu.status.carry) 1 else 0) << 7;
                cpu.status.carry = next_carry;
                update_zero_and_negative_flags(cpu, target.*);
            },
            .sta => {
                cpu.memory[addr] = cpu.accumulator;
            },
            .tax => {
                cpu.register_x = cpu.accumulator;
                update_zero_and_negative_flags(cpu, cpu.register_x);
            },
            else => {
                return;
            },
        }

        cpu.program_counter += instruction_offset(info.mode);
    }
}
