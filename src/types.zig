pub const CPU = struct {
    memory: [0xFFFF]u8 = @splat(0),
    program_counter: u16 = 0,
    stack_pointer: u8 = 0xFD,
    accumulator: u8 = 0,
    register_x: u8 = 0,
    register_y: u8 = 0,
    status: ProcessorStatus = ProcessorStatus{},
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

pub const OpcodeInfo = struct {
    instruction: Instruction,
    mode: AddressingMode,
};

/// All 56 official instructions on the MOS 6502 CPU.
/// Sorted alphabetically by mnemonic.
pub const Instruction = enum {
    adc, // Add with Carry
    and_, // And (with Accumulator) — `and` is a Zig keyword
    asl, // Arithmetic Shift Left
    bcc, // Branch on Carry Clear
    bcs, // Branch on Carry Set
    beq, // Branch on Equal (Zero Set)
    bit, // Bit Test
    bmi, // Branch on Minus (Negative Set)
    bne, // Branch on Not Equal (Zero Clear)
    bpl, // Branch on Plus (Negative Clear)
    brk, // Break / Interrupt
    bvc, // Branch on Overflow Clear
    bvs, // Branch on Overflow Set
    clc, // Clear Carry
    cld, // Clear Decimal
    cli, // Clear Interrupt Disable
    clv, // Clear Overflow
    cmp, // Compare (with Accumulator)
    cpx, // Compare with X
    cpy, // Compare with Y
    dec, // Decrement (memory)
    dex, // Decrement X
    dey, // Decrement Y
    eor, // Exclusive Or (with Accumulator)
    inc, // Increment (memory)
    inx, // Increment X
    iny, // Increment Y
    jmp, // Jump
    jsr, // Jump Subroutine
    lda, // Load Accumulator
    ldx, // Load X
    ldy, // Load Y
    lsr, // Logical Shift Right
    nop, // No Operation
    ora, // Or with Accumulator
    pha, // Push Accumulator
    php, // Push Processor Status
    pla, // Pull Accumulator
    plp, // Pull Processor Status
    rol, // Rotate Left
    ror, // Rotate Right
    rti, // Return from Interrupt
    rts, // Return from Subroutine
    sbc, // Subtract with Carry
    sec, // Set Carry
    sed, // Set Decimal
    sei, // Set Interrupt Disable
    sta, // Store Accumulator
    stx, // Store X
    sty, // Store Y
    tax, // Transfer Accumulator to X
    tay, // Transfer Accumulator to Y
    tsx, // Transfer Stack Pointer to X
    txa, // Transfer X to Accumulator
    txs, // Transfer X to Stack Pointer
    tya, // Transfer Y to Accumulator
};

/// The 13 addressing modes of the 6502 CPU.
pub const AddressingMode = enum {
    implied, // No operand (e.g., INX, BRK)
    accumulator, // Operates on A register (e.g., ASL A)
    immediate, // Operand is the byte after opcode (e.g., LDA #$FF)
    zero_page, // Single-byte address in $0000-$00FF (e.g., LDA $42)
    zero_page_x, // Zero page address + X register (e.g., LDA $42,X)
    zero_page_y, // Zero page address + Y register (e.g., LDX $42,Y)
    absolute, // Full 16-bit address (e.g., LDA $C000)
    absolute_x, // Absolute address + X register (e.g., LDA $C000,X)
    absolute_y, // Absolute address + Y register (e.g., LDA $C000,Y)
    indirect, // JMP only; 16-bit pointer to target address (e.g., JMP ($1234))
    indirect_x, // Zero-page pointer + X, then dereference (e.g., LDA ($42,X))
    indirect_y, // Zero-page pointer, then + Y (e.g., LDA ($42),Y)
    relative, // Branch only; signed 8-bit offset from PC (e.g., BCC $05)
};
