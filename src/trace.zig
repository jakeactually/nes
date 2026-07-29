const std = @import("std");
const types = @import("types.zig");
const cpu_mod = @import("cpu.zig");
const opcodes = @import("opcodes.zig");

fn instructionLen(mode: types.AddressingMode) u2 {
    return switch (mode) {
        .implied, .accumulator => 1,
        .immediate, .zero_page, .zero_page_x, .zero_page_y, .relative, .indirect_x, .indirect_y => 2,
        .absolute, .absolute_x, .absolute_y, .indirect => 3,
    };
}

fn mnemonic(instruction: types.Instruction) []const u8 {
    return switch (instruction) {
        .adc => "ADC",
        .and_ => "AND",
        .asl => "ASL",
        .bcc => "BCC",
        .bcs => "BCS",
        .beq => "BEQ",
        .bit => "BIT",
        .bmi => "BMI",
        .bne => "BNE",
        .bpl => "BPL",
        .brk => "BRK",
        .bvc => "BVC",
        .bvs => "BVS",
        .clc => "CLC",
        .cld => "CLD",
        .cli => "CLI",
        .clv => "CLV",
        .cmp => "CMP",
        .cpx => "CPX",
        .cpy => "CPY",
        .dec => "DEC",
        .dex => "DEX",
        .dey => "DEY",
        .eor => "EOR",
        .inc => "INC",
        .inx => "INX",
        .iny => "INY",
        .jmp => "JMP",
        .jsr => "JSR",
        .lda => "LDA",
        .ldx => "LDX",
        .ldy => "LDY",
        .lsr => "LSR",
        .nop => "NOP",
        .ora => "ORA",
        .pha => "PHA",
        .php => "PHP",
        .pla => "PLA",
        .plp => "PLP",
        .rol => "ROL",
        .ror => "ROR",
        .rti => "RTI",
        .rts => "RTS",
        .sbc => "SBC",
        .sec => "SEC",
        .sed => "SED",
        .sei => "SEI",
        .sta => "STA",
        .stx => "STX",
        .sty => "STY",
        .tax => "TAX",
        .tay => "TAY",
        .tsx => "TSX",
        .txa => "TXA",
        .txs => "TXS",
        .tya => "TYA",
    };
}

fn getAbsoluteAddress(cpu: *const types.CPU, mode: types.AddressingMode, addr: u16) u16 {
    return switch (mode) {
        .zero_page => cpu_mod.mem_read(cpu, addr),
        .absolute => cpu_mod.mem_read_u16(cpu, addr),
        .zero_page_x => blk: {
            const pos = cpu_mod.mem_read(cpu, addr);
            break :blk @as(u16, pos +% cpu.register_x);
        },
        .zero_page_y => blk: {
            const pos = cpu_mod.mem_read(cpu, addr);
            break :blk @as(u16, pos +% cpu.register_y);
        },
        .absolute_x => blk: {
            const base = cpu_mod.mem_read_u16(cpu, addr);
            break :blk base +% @as(u16, cpu.register_x);
        },
        .absolute_y => blk: {
            const base = cpu_mod.mem_read_u16(cpu, addr);
            break :blk base +% @as(u16, cpu.register_y);
        },
        .indirect_x => blk: {
            const base = cpu_mod.mem_read(cpu, addr);
            const ptr = base +% cpu.register_x;
            const lo = cpu_mod.mem_read(cpu, ptr);
            const hi = cpu_mod.mem_read(cpu, @as(u16, ptr +% 1));
            break :blk @as(u16, hi) << 8 | lo;
        },
        .indirect_y => blk: {
            const base = cpu_mod.mem_read(cpu, addr);
            const lo = cpu_mod.mem_read(cpu, base);
            const hi = cpu_mod.mem_read(cpu, @as(u16, base +% 1));
            const deref_base = @as(u16, hi) << 8 | lo;
            break :blk deref_base +% @as(u16, cpu.register_y);
        },
        else => std.debug.panic("mode {s} is not supported", .{@tagName(mode)}),
    };
}

pub fn trace(allocator: std.mem.Allocator, cpu: *const types.CPU) ![]u8 {
    const code = cpu_mod.mem_read(cpu, cpu.program_counter);
    const ops = opcodes.opcode_info(code);

    const begin = cpu.program_counter;
    var hex_dump: [3]u8 = undefined;
    hex_dump[0] = code;
    var hex_len: usize = 1;

    const mem_addr, const stored_value = switch (ops.mode) {
        .immediate, .implied, .accumulator => .{ @as(u16, 0), @as(u8, 0) },
        else => addr_blk: {
            const addr = getAbsoluteAddress(cpu, ops.mode, begin + 1);
            break :addr_blk .{ addr, cpu_mod.mem_read(cpu, addr) };
        },
    };

    var tmp_buf: [64]u8 = undefined;
    const tmp = tmp_buf[0..tmp_blk: {
        const len = instructionLen(ops.mode);
        switch (len) {
            1 => {
                switch (code) {
                    0x0a, 0x4a, 0x2a, 0x6a => break :tmp_blk (std.fmt.bufPrint(&tmp_buf, "A ", .{}) catch unreachable).len,
                    else => break :tmp_blk 0,
                }
            },
            2 => {
                const address = cpu_mod.mem_read(cpu, begin + 1);
                hex_dump[1] = address;
                hex_len = 2;

                break :tmp_blk switch (ops.mode) {
                    .immediate => (std.fmt.bufPrint(&tmp_buf, "#${X:0>2}", .{address}) catch unreachable).len,
                    .zero_page => (std.fmt.bufPrint(&tmp_buf, "${X:0>2} = {X:0>2}", .{ mem_addr, stored_value }) catch unreachable).len,
                    .zero_page_x => (std.fmt.bufPrint(
                        &tmp_buf,
                        "${X:0>2},X @ {X:0>4} = {X:0>2}",
                        .{ address, mem_addr, stored_value },
                    ) catch unreachable).len,
                    .zero_page_y => (std.fmt.bufPrint(
                        &tmp_buf,
                        "${X:0>2},Y @ {X:0>4} = {X:0>2}",
                        .{ address, mem_addr, stored_value },
                    ) catch unreachable).len,
                    .indirect_x => (std.fmt.bufPrint(
                        &tmp_buf,
                        "(${X:0>2},X) @ {X:0>4} = {X:0>4} = {X:0>2}",
                        .{ address, address +% cpu.register_x, mem_addr, stored_value },
                    ) catch unreachable).len,
                    .indirect_y => (std.fmt.bufPrint(
                        &tmp_buf,
                        "(${X:0>2}),Y = {X:0>4} @ {X:0>4} = {X:0>2}",
                        .{ address, mem_addr -% @as(u16, cpu.register_y), mem_addr, stored_value },
                    ) catch unreachable).len,
                    .relative => {
                        const offset: i8 = @bitCast(address);
                        const target = begin + 2 +% @as(u16, @bitCast(@as(i16, offset)));
                        break :tmp_blk (std.fmt.bufPrint(&tmp_buf, "${X:0>4}", .{target}) catch unreachable).len;
                    },
                    else => std.debug.panic("unexpected addressing mode {s} has ops-len 2. code {X:0>2}", .{ @tagName(ops.mode), code }),
                };
            },
            3 => {
                const address_lo = cpu_mod.mem_read(cpu, begin + 1);
                const address_hi = cpu_mod.mem_read(cpu, begin + 2);
                hex_dump[1] = address_lo;
                hex_dump[2] = address_hi;
                hex_len = 3;

                const address = cpu_mod.mem_read_u16(cpu, begin + 1);

                break :tmp_blk switch (ops.mode) {
                    .indirect => {
                        const jmp_addr = if (address & 0x00FF == 0x00FF) jmp_blk: {
                            const lo = cpu_mod.mem_read(cpu, address);
                            const hi = cpu_mod.mem_read(cpu, address & 0xFF00);
                            break :jmp_blk @as(u16, hi) << 8 | lo;
                        } else cpu_mod.mem_read_u16(cpu, address);
                        break :tmp_blk (std.fmt.bufPrint(&tmp_buf, "(${X:0>4}) = {X:0>4}", .{ address, jmp_addr }) catch unreachable).len;
                    },
                    .absolute => if (ops.instruction == .jmp or ops.instruction == .jsr)
                        (std.fmt.bufPrint(&tmp_buf, "${X:0>4}", .{address}) catch unreachable).len
                    else
                        (std.fmt.bufPrint(&tmp_buf, "${X:0>4} = {X:0>2}", .{ mem_addr, stored_value }) catch unreachable).len,
                    .absolute_x => (std.fmt.bufPrint(
                        &tmp_buf,
                        "${X:0>4},X @ {X:0>4} = {X:0>2}",
                        .{ address, mem_addr, stored_value },
                    ) catch unreachable).len,
                    .absolute_y => (std.fmt.bufPrint(
                        &tmp_buf,
                        "${X:0>4},Y @ {X:0>4} = {X:0>2}",
                        .{ address, mem_addr, stored_value },
                    ) catch unreachable).len,
                    else => std.debug.panic("unexpected addressing mode {s} has ops-len 3. code {X:0>2}", .{ @tagName(ops.mode), code }),
                };
            },
            else => break :tmp_blk 0,
        }
    }];

    var hex_str_buf: [16]u8 = undefined;
    var hex_len_str: usize = 0;
    for (hex_dump[0..hex_len], 0..) |byte, i| {
        if (i > 0) {
            hex_str_buf[hex_len_str] = ' ';
            hex_len_str += 1;
        }
        const s = try std.fmt.bufPrint(hex_str_buf[hex_len_str..], "{X:0>2}", .{byte});
        hex_len_str += s.len;
    }
    const hex_str = hex_str_buf[0..hex_len_str];

    var asm_buf: [128]u8 = undefined;
    const asm_str = try std.fmt.bufPrint(
        &asm_buf,
        "{X:0>4}  {s:<8} {s:>4} {s}",
        .{ begin, hex_str, mnemonic(ops.instruction), tmp },
    );

    const status = types.status_to_byte(cpu.status);
    const line = try std.fmt.allocPrint(
        allocator,
        "{s:<47} A:{X:0>2} X:{X:0>2} Y:{X:0>2} P:{X:0>2} SP:{X:0>2}",
        .{ asm_str, cpu.accumulator, cpu.register_x, cpu.register_y, status, cpu.stack_pointer },
    );
    errdefer allocator.free(line);

    for (line) |*c| c.* = std.ascii.toUpper(c.*);
    return line;
}

fn runWithCallback(cpu: *types.CPU, result: *std.ArrayList([]const u8), allocator: std.mem.Allocator) !void {
    while (true) {
        try result.append(allocator, try trace(allocator, cpu));
        if (!cpu_mod.step(cpu)) break;
    }
}

test "test_format_trace" {
    var cpu = types.CPU{};
    cpu_mod.mem_write(&cpu, 100, 0xa2);
    cpu_mod.mem_write(&cpu, 101, 0x01);
    cpu_mod.mem_write(&cpu, 102, 0xca);
    cpu_mod.mem_write(&cpu, 103, 0x88);
    cpu_mod.mem_write(&cpu, 104, 0x00);

    cpu.program_counter = 0x64;
    cpu.accumulator = 1;
    cpu.register_x = 2;
    cpu.register_y = 3;

    var result: std.ArrayList([]const u8) = .empty;
    defer {
        for (result.items) |line| std.testing.allocator.free(line);
        result.deinit(std.testing.allocator);
    }

    try runWithCallback(&cpu, &result, std.testing.allocator);

    try std.testing.expectEqualStrings(
        "0064  A2 01     LDX #$01                        A:01 X:02 Y:03 P:24 SP:FD",
        result.items[0],
    );
    try std.testing.expectEqualStrings(
        "0066  CA        DEX                             A:01 X:01 Y:03 P:24 SP:FD",
        result.items[1],
    );
    try std.testing.expectEqualStrings(
        "0067  88        DEY                             A:01 X:00 Y:03 P:26 SP:FD",
        result.items[2],
    );
}

test "test_format_mem_access" {
    var cpu = types.CPU{};
    cpu_mod.mem_write(&cpu, 100, 0x11);
    cpu_mod.mem_write(&cpu, 101, 0x33);
    cpu_mod.mem_write(&cpu, 0x33, 0x00);
    cpu_mod.mem_write(&cpu, 0x34, 0x04);
    cpu_mod.mem_write(&cpu, 0x400, 0xAA);

    cpu.program_counter = 0x64;
    cpu.register_y = 0;

    var result: std.ArrayList([]const u8) = .empty;
    defer {
        for (result.items) |line| std.testing.allocator.free(line);
        result.deinit(std.testing.allocator);
    }

    try runWithCallback(&cpu, &result, std.testing.allocator);

    try std.testing.expectEqualStrings(
        "0064  11 33     ORA ($33),Y = 0400 @ 0400 = AA  A:00 X:00 Y:00 P:24 SP:FD",
        result.items[0],
    );
}
