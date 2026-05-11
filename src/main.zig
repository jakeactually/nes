const std = @import("std");
const types = @import("types.zig");

pub fn main() !void {}

pub fn update_zero_and_negative_flags(cpu: *types.CPU, value: u8) void {
    cpu.status.zero = value == 0;
    cpu.status.negative = value & 0b1000_0000 != 0;
}

pub fn interpret(cpu: *types.CPU, T: type, program: T) void {
    while (true) {
        const opscode = program[cpu.program_counter];
        cpu.program_counter += 1;

        switch (opscode) {
            0xA9 => {
                const param = program[cpu.program_counter];
                cpu.program_counter += 1;
                cpu.accumulator = param;
                update_zero_and_negative_flags(cpu, cpu.accumulator);
            },
            0xAA => {
                cpu.register_x = cpu.accumulator;
                update_zero_and_negative_flags(cpu, cpu.register_x);
            },
            0xE8 => {
                cpu.register_x +%= 1;
                update_zero_and_negative_flags(cpu, cpu.register_x);
            },
            0x00 => {
                return;
            },
            else => {
                return;
            },
        }
    }
}
