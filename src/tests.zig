const std = @import("std");
const interpret = @import("main.zig").interpret;
const CPU = @import("types.zig").CPU;

test "test_load_and_reset" {
    var cpu = CPU{};
    interpret(&cpu, &[_]u8{0x00});
    try std.testing.expectEqual(cpu.program_counter, 0x8000 + 1);
}

test "test_0xa9_lda_immediate_load_data" {
    var cpu = CPU{};
    interpret(&cpu, &[_]u8{ 0xa9, 0x05, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0x05);
    try std.testing.expect(!cpu.status.zero);
    try std.testing.expect(!cpu.status.negative);
}

test "test_0xa9_lda_zero_flag" {
    var cpu = CPU{};
    interpret(&cpu, &[_]u8{ 0xa9, 0x00 });
    try std.testing.expect(cpu.status.zero);
}

test "test_0xa9_lda_negative_flag" {
    var cpu = CPU{};
    interpret(&cpu, &[_]u8{ 0xa9, 0xff, 0x00 });
    try std.testing.expect(cpu.status.negative);
}

test "test_0xaa_tax_move_a_to_x" {
    var cpu = CPU{};
    cpu.accumulator = 10;
    interpret(&cpu, &[_]u8{ 0xaa, 0x00 });
    try std.testing.expectEqual(cpu.register_x, 10);
}

test "test_5_ops_working_together" {
    var cpu = CPU{};
    interpret(&cpu, &[_]u8{ 0xa9, 0xc0, 0xaa, 0xe8, 0x00 });
    try std.testing.expectEqual(cpu.register_x, 0xc1);
}

test "test_inx_overflow" {
    var cpu = CPU{};
    cpu.register_x = 0xff;
    interpret(&cpu, &[_]u8{ 0xe8, 0xe8, 0x00 });
    try std.testing.expectEqual(cpu.register_x, 1);
}

test "test_lda_from_memory" {
    var cpu = CPU{};
    cpu.memory[0x10] = 0x55;
    interpret(&cpu, &[_]u8{ 0xa5, 0x10, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0x55);
}

test "test_sta_zero_page" {
    var cpu = CPU{};
    cpu.accumulator = 0x02;
    interpret(&cpu, &[_]u8{ 0x85, 0x10, 0x00 });
    try std.testing.expectEqual(cpu.memory[0x10], 0x02);
}

test "test_sta_zero_page_x" {
    var cpu = CPU{};
    cpu.accumulator = 0x02;
    cpu.register_x = 0x04;
    interpret(&cpu, &[_]u8{ 0x95, 0x10, 0x00 });
    try std.testing.expectEqual(cpu.memory[0x14], 0x02);
}

test "test_adc_immediate" {
    var cpu = CPU{};
    cpu.accumulator = 0x10;
    interpret(&cpu, &[_]u8{ 0x69, 0x20, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0x30);
    try std.testing.expect(!cpu.status.carry);
    try std.testing.expect(!cpu.status.overflow);
}

test "test_adc_immediate_carry" {
    var cpu = CPU{};
    cpu.accumulator = 0x10;
    interpret(&cpu, &[_]u8{ 0x69, 0xFF, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0x0F);
    try std.testing.expect(cpu.status.carry);
    try std.testing.expect(!cpu.status.overflow);
}

test "test_adc_immediate_overflow" {
    var cpu = CPU{};
    cpu.accumulator = 80;
    interpret(&cpu, &[_]u8{ 0x69, 80, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 160);
    try std.testing.expect(!cpu.status.carry);
    try std.testing.expect(cpu.status.overflow);
}

test "test_and_immediate" {
    var cpu = CPU{};
    cpu.accumulator = 0x10;
    interpret(&cpu, &[_]u8{ 0x29, 0x10, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0x10);
}
