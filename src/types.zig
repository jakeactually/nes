pub const CPU = struct {
    memory: [0xFFFF]u8 = @splat(0),
    bus: Bus = Bus{},
    program_counter: u16 = 0,
    stack_pointer: u8 = 0xFD,
    accumulator: u8 = 0,
    register_x: u8 = 0,
    register_y: u8 = 0,
    status: ProcessorStatus = ProcessorStatus{},
};

pub const Bus = struct {
    cpu_vram: [2048]u8 = @splat(0),
};

pub const ProcessorStatus = struct {
    negative: bool = false,
    overflow: bool = false,
    ignored: bool = false,
    break_: bool = false,
    decimal: bool = false,
    interrupt: bool = false,
    zero: bool = false,
    carry: bool = false,
};

pub fn status_to_byte(status: ProcessorStatus) u8 {
    const b1 = @as(u8, if (status.negative) 1 else 0) << 7;
    const b2 = @as(u8, if (status.overflow) 1 else 0) << 6;
    const b3 = @as(u8, if (status.ignored) 1 else 0) << 5;
    const b4 = @as(u8, if (status.break_) 1 else 0) << 4;
    const b5 = @as(u8, if (status.decimal) 1 else 0) << 3;
    const b6 = @as(u8, if (status.interrupt) 1 else 0) << 2;
    const b7 = @as(u8, if (status.zero) 1 else 0) << 1;
    const b8 = @as(u8, if (status.carry) 1 else 0) << 0;
    return b1 | b2 | b3 | b4 | b5 | b6 | b7 | b8;
}

pub fn byte_to_status(byte: u8) ProcessorStatus {
    return ProcessorStatus{
        .negative = (byte & 0b1000_0000) != 0,
        .overflow = (byte & 0b0100_0000) != 0,
        .ignored = (byte & 0b0010_0000) != 0,
        .break_ = (byte & 0b0001_0000) != 0,
        .decimal = (byte & 0b0000_1000) != 0,
        .interrupt = (byte & 0b0000_0100) != 0,
        .zero = (byte & 0b0000_0010) != 0,
        .carry = (byte & 0b0000_0001) != 0,
    };
}

pub const OpcodeInfo = struct {
    instruction: Instruction,
    mode: AddressingMode,
};

pub const Instruction = enum {
    adc,
    and_,
    asl,
    bcc,
    bcs,
    beq,
    bit,
    bmi,
    bne,
    bpl,
    brk,
    bvc,
    bvs,
    clc,
    cld,
    cli,
    clv,
    cmp,
    cpx,
    cpy,
    dec,
    dex,
    dey,
    eor,
    inc,
    inx,
    iny,
    jmp,
    jsr,
    lda,
    ldx,
    ldy,
    lsr,
    nop,
    ora,
    pha,
    php,
    pla,
    plp,
    rol,
    ror,
    rti,
    rts,
    sbc,
    sec,
    sed,
    sei,
    sta,
    stx,
    sty,
    tax,
    tay,
    tsx,
    txa,
    txs,
    tya,
};

pub const AddressingMode = enum {
    implied,
    accumulator,
    immediate,
    zero_page,
    zero_page_x,
    zero_page_y,
    absolute,
    absolute_x,
    absolute_y,
    indirect,
    indirect_x,
    indirect_y,
    relative,
};

pub fn color(byte: u8) u32 {
    return switch (byte) {
        0 => 0x000000, // BLACK
        1 => 0xFFFFFF, // WHITE
        2, 9 => 0x808080, // GREY
        3, 10 => 0x0000FF, // RED
        4, 11 => 0x00FF00, // GREEN
        5, 12 => 0xFF0000, // BLUE
        6, 13 => 0xFF00FF, // MAGENTA
        7, 14 => 0x00FFFF, // YELLOW
        else => 0xFFFF00, // CYAN
    };
}
