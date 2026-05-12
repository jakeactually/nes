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
    cpu.status.negative = value & 0b1000_0000 != 0;
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
        .indirect_x => {
            const ptr = get_operand_address(cpu, .zero_page_x);
            return @as(u16, cpu.memory[ptr +% 1]) << 8 | cpu.memory[ptr];
        },
        .indirect_y => {
            const base = @as(u16, cpu.memory[current +% 1]) << 8 | cpu.memory[current];
            return base +% cpu.register_y;
        },
        else => 0,
    };
}

fn instruction_offset(mode: types.AddressingMode) u16 {
    return switch (mode) {
        .absolute => 2,
        .absolute_x => 2,
        .absolute_y => 2,
        .implied => 0,
        else => 1,
    };
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
            .lda => {
                cpu.accumulator = cpu.memory[addr];
                update_zero_and_negative_flags(cpu, cpu.accumulator);
            },
            .tax => {
                cpu.register_x = cpu.accumulator;
                update_zero_and_negative_flags(cpu, cpu.register_x);
            },
            .inx => {
                cpu.register_x +%= 1;
                update_zero_and_negative_flags(cpu, cpu.register_x);
            },
            .brk => {
                return;
            },
            else => {
                return;
            },
        }

        cpu.program_counter += instruction_offset(info.mode);
    }
}
