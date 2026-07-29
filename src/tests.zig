const std = @import("std");
const interpret = @import("cpu.zig").interpret;
const mem_read = @import("cpu.zig").mem_read;
const mem_read_u16 = @import("cpu.zig").mem_read_u16;
const mem_write = @import("cpu.zig").mem_write;
const mem_write_u16 = @import("cpu.zig").mem_write_u16;
const CPU = @import("types.zig").CPU;

test "test_load_and_reset" {
    var cpu = CPU{};
    interpret(&cpu, &[_]u8{0x00});
    try std.testing.expectEqual(cpu.program_counter, 0x8000 + 1);
    try std.testing.expectEqual(cpu.stack_pointer, 0xFD);
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
    mem_write(&cpu, 0x10, 0x55);
    interpret(&cpu, &[_]u8{ 0xa5, 0x10, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0x55);
}

test "test_sta_zero_page" {
    var cpu = CPU{};
    cpu.accumulator = 0x02;
    interpret(&cpu, &[_]u8{ 0x85, 0x10, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x10), 0x02);
}

test "test_sta_zero_page_x" {
    var cpu = CPU{};
    cpu.accumulator = 0x02;
    cpu.register_x = 0x04;
    interpret(&cpu, &[_]u8{ 0x95, 0x10, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x14), 0x02);
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

test "test_asl_accumulator" {
    var cpu = CPU{};
    cpu.accumulator = 0xFF;
    interpret(&cpu, &[_]u8{ 0x0A, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0b1111_1110);
    try std.testing.expect(cpu.status.carry);
}

test "test_asl_zero_page" {
    var cpu = CPU{};
    mem_write(&cpu, 0x10, 0b0111_1111);
    interpret(&cpu, &[_]u8{ 0x06, 0x10, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x10), 0b1111_1110);
    try std.testing.expect(!cpu.status.carry);
}

test "test_bcc" {
    var cpu = CPU{};
    cpu.status.carry = false;
    interpret(&cpu, &[_]u8{ 0x90, 10 });
    try std.testing.expectEqual(cpu.program_counter, 0x8000 + 10 + 3);
}

test "test_bcc_negative" {
    var cpu = CPU{};
    cpu.status.carry = false;
    interpret(&cpu, &[_]u8{ 0x90, 1, 0x00, 0xEA, 0xEA, 0xEA, 0xEA, 0x90, @bitCast(@as(i8, -7)) });
    try std.testing.expectEqual(cpu.program_counter, 0x8003);
}

test "test_bcs" {
    var cpu = CPU{};
    cpu.status.carry = true;
    interpret(&cpu, &[_]u8{ 0xB0, 10 });
    try std.testing.expectEqual(cpu.program_counter, 0x8000 + 10 + 3);
}

test "test_beq" {
    var cpu = CPU{};
    cpu.status.zero = true;
    interpret(&cpu, &[_]u8{ 0xF0, 10 });
    try std.testing.expectEqual(cpu.program_counter, 0x8000 + 10 + 3);
}

test "test_bit_zero_page" {
    var cpu = CPU{};
    cpu.accumulator = 0b0000_1000;
    mem_write(&cpu, 0x10, 0b1000_0110);
    interpret(&cpu, &[_]u8{ 0x24, 0x10, 0x00 });
    try std.testing.expect(cpu.status.zero);
    try std.testing.expect(!cpu.status.overflow);
    try std.testing.expect(cpu.status.negative);
}

test "test_bit_absolute" {
    var cpu = CPU{};
    cpu.accumulator = 0b0000_1000;
    mem_write(&cpu, 0x0245, 0b1000_0110);
    interpret(&cpu, &[_]u8{ 0x2C, 0x45, 0x02, 0x00 });
    try std.testing.expect(cpu.status.zero);
    try std.testing.expect(!cpu.status.overflow);
    try std.testing.expect(cpu.status.negative);
}

test "test_cmp" {
    var cpu = CPU{};
    cpu.accumulator = 15;
    interpret(&cpu, &[_]u8{ 0xC9, 14, 0x00 });
    try std.testing.expect(cpu.status.carry);
    try std.testing.expect(!cpu.status.zero);
    try std.testing.expect(!cpu.status.negative);
}

test "test_cmp_less" {
    var cpu = CPU{};
    cpu.accumulator = 14;
    interpret(&cpu, &[_]u8{ 0xC9, 15, 0x00 });
    try std.testing.expect(!cpu.status.carry);
    try std.testing.expect(!cpu.status.zero);
    try std.testing.expect(cpu.status.negative);
}

test "test_cmp_equal" {
    var cpu = CPU{};
    cpu.accumulator = 129;
    interpret(&cpu, &[_]u8{ 0xC9, 129, 0x00 });
    try std.testing.expect(cpu.status.carry);
    try std.testing.expect(cpu.status.zero);
    try std.testing.expect(!cpu.status.negative);
}

test "test_lda_indirect_x" {
    var cpu = CPU{};
    cpu.register_x = 1;
    mem_write_u16(&cpu, 0x11, 0x0100);
    mem_write(&cpu, 0x0100, 123);
    interpret(&cpu, &[_]u8{ 0xA1, 0x10, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 123);
}

test "test_lda_indirect_y" {
    var cpu = CPU{};
    cpu.register_y = 1;
    mem_write_u16(&cpu, 0x10, 0x0100);
    mem_write(&cpu, 0x0101, 123);
    interpret(&cpu, &[_]u8{ 0xB1, 0x10, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 123);
}

test "test_dec" {
    var cpu = CPU{};
    mem_write(&cpu, 0x10, 0x55);
    interpret(&cpu, &[_]u8{ 0xC6, 0x10, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x10), 0x54);
}

test "test_eor_immediate" {
    var cpu = CPU{};
    cpu.accumulator = 0x10;
    interpret(&cpu, &[_]u8{ 0x49, 0x10, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0x00);
}

test "test_inc" {
    var cpu = CPU{};
    mem_write(&cpu, 0x10, 0x55);
    interpret(&cpu, &[_]u8{ 0xE6, 0x10, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x10), 0x56);
}

test "test_jmp" {
    var cpu = CPU{};
    interpret(&cpu, &[_]u8{ 0x4C, 0x23, 0x81 });
    try std.testing.expectEqual(cpu.program_counter, 0x8123 + 1);
}

test "test_jmp_indirect" {
    var cpu = CPU{};
    mem_write_u16(&cpu, 0x1234, 0x8123);
    interpret(&cpu, &[_]u8{ 0x6C, 0x34, 0x12 });
    try std.testing.expectEqual(cpu.program_counter, 0x8123 + 1);
}

test "test_jsr" {
    var cpu = CPU{};
    interpret(&cpu, &[_]u8{ 0x20, 0x23, 0x81 });
    try std.testing.expectEqual(cpu.program_counter, 0x8123 + 1);
    try std.testing.expectEqual(cpu.stack_pointer, 0xFD - 2);
    try std.testing.expectEqual(mem_read_u16(&cpu, 0x100 + 0xFC), 0x8002);
}

test "test_lsr_accumulator" {
    var cpu = CPU{};
    cpu.accumulator = 2;
    interpret(&cpu, &[_]u8{ 0x4A, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 1);
    try std.testing.expect(!cpu.status.carry);
    try std.testing.expect(!cpu.status.negative);
}

test "test_lsr_zero_page" {
    var cpu = CPU{};
    mem_write(&cpu, 0x10, 1);
    interpret(&cpu, &[_]u8{ 0x46, 0x10, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x10), 0);
    try std.testing.expect(cpu.status.carry);
    try std.testing.expect(cpu.status.zero);
}

test "test_pha" {
    var cpu = CPU{};
    cpu.accumulator = 123;
    interpret(&cpu, &[_]u8{ 0x48, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x100 + @as(u16, cpu.stack_pointer) + 1), 123);
}

test "test_php" {
    var cpu = CPU{};
    cpu.status.negative = true;
    cpu.status.overflow = true;
    cpu.status.zero = true;
    interpret(&cpu, &[_]u8{ 0x08, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x100 + @as(u16, cpu.stack_pointer) + 1), 0b11110110);
    try std.testing.expect(!cpu.status.break_);
    try std.testing.expect(cpu.status.ignored);
}

test "test_pla" {
    var cpu = CPU{};
    mem_write(&cpu, 0x100 + 0xFE, 123);
    interpret(&cpu, &[_]u8{ 0x68, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 123);
    try std.testing.expectEqual(cpu.stack_pointer, 0xFD + 1);
}

test "test_plp" {
    var cpu = CPU{};
    mem_write(&cpu, 0x100 + 0xFE, 0b1100_0010);
    interpret(&cpu, &[_]u8{ 0x28, 0x00 });
    try std.testing.expect(cpu.status.negative);
    try std.testing.expect(cpu.status.overflow);
    try std.testing.expect(cpu.status.zero);
    try std.testing.expect(cpu.status.ignored);
    try std.testing.expectEqual(cpu.stack_pointer, 0xFD + 1);
}

test "test_rol_accumulator" {
    var cpu = CPU{};
    cpu.status.carry = true;
    cpu.accumulator = 0b0100_1001;
    interpret(&cpu, &[_]u8{ 0x2A, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0b1001_0011);
    try std.testing.expect(!cpu.status.carry);
}

test "test_ror_accumulator" {
    var cpu = CPU{};
    cpu.status.carry = true;
    cpu.accumulator = 0b0100_1000;
    interpret(&cpu, &[_]u8{ 0x6A, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 0b1010_0100);
    try std.testing.expect(!cpu.status.carry);
}

test "test_rti" {
    var cpu = CPU{};
    mem_write(&cpu, 0x100 + 0xFE, 0b1100_0010);
    mem_write(&cpu, 0x100 + 0xFF, 0x34);
    mem_write(&cpu, 0x100 + 0, 0x02);
    interpret(&cpu, &[_]u8{ 0x40, 0x00 });
    try std.testing.expect(cpu.status.negative);
    try std.testing.expect(cpu.status.overflow);
    try std.testing.expect(cpu.status.zero);
    try std.testing.expect(cpu.status.ignored);
    try std.testing.expectEqual(cpu.program_counter, 0x0234 + 1);
    try std.testing.expectEqual(cpu.stack_pointer, 0);
}

test "test_rts" {
    var cpu = CPU{};
    mem_write_u16(&cpu, 0x100 + 0xFE, 0x0200);
    interpret(&cpu, &[_]u8{ 0x60, 0x00 });
    try std.testing.expectEqual(cpu.program_counter, 0x0200 + 2);
    try std.testing.expectEqual(cpu.stack_pointer, 0xFD + 2);
}

test "test_sbc_immediate" {
    var cpu = CPU{};
    cpu.accumulator = 7;
    interpret(&cpu, &[_]u8{ 0xE9, 2, 0x00 });
    try std.testing.expectEqual(cpu.accumulator, 5 - 1);
    try std.testing.expect(cpu.status.carry);
    try std.testing.expect(!cpu.status.overflow);
}

test "test_stx_zero_page" {
    var cpu = CPU{};
    cpu.register_x = 0x02;
    interpret(&cpu, &[_]u8{ 0x86, 0x10, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x10), 0x02);
}

test "test_sty_zero_page" {
    var cpu = CPU{};
    cpu.register_y = 0x02;
    interpret(&cpu, &[_]u8{ 0x84, 0x10, 0x00 });
    try std.testing.expectEqual(mem_read(&cpu, 0x10), 0x02);
}
