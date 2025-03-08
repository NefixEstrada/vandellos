const std = @import("std");
const helpers = @import("../helpers.zig");
const HARDWARE_INTERRUPTS_OFFSET = @import("../descriptors/interrupt.zig").CPU_DESCRIPTORS;

// A PIC chip has 8 IRQ
pub const PIC_IRQ_NUMBER = 8;
// There are 2 PIC chips in almost all computers
pub const PIC_NUMBER = 2;
// The secondary PIC is nested in the IRQ 2 on the primary PIC
const PIC_NESTED_IRQ_PRIMARY = 2;

const PIC_PRIMARY_COMMAND = 0x20;
const PIC_PRIMARY_DATA = 0x21;
const PIC_SECONDARY_COMMAND = 0xa0;
const PIC_SECONDARY_DATA = 0xa1;

const PicInterrupts = enum(u8) {
    primary_timer,
    primary_keyboard,
    _primary_secondary_pic,
    primary_serial_port_2,
    primary_serial_port_1,
    primary_parallel_port_2_3,
    primary_floppy_disk,
    primary_parallel_port_1,
    secondary_real_time_clock,
    secondary_acpi,
    secondary_available_1,
    secondary_available_2,
    secondary_mouse,
    secondary_co_processor,
    secondary_primary_ata,
    secondary_secondary_ata,
};

const PicPrimaryMask = packed struct {
    disable_timer: bool = true,
    disable_keyboard: bool = true,
    _disable_secondary_pic: bool = true,
    disable_serial_port_2: bool = true,
    disable_serial_port_1: bool = true,
    disable_parallel_port_2_3: bool = true,
    disable_floppy_disk: bool = true,
    disable_parallel_port_1: bool = true,
};

const PicSecondaryMask = packed struct {
    disable_real_time_clock: bool = true,
    disable_acpi: bool = true,
    disable_available_1: bool = true,
    disable_available_2: bool = true,
    disable_mouse: bool = true,
    disable_co_processor: bool = true,
    disable_primary_ata: bool = true,
    disable_secondary_ata: bool = true,
};

const InitializationControlWord1 = packed struct {
    // This needs to be set if a ICW4 will be sent
    icw4: bool,
    // This needs to be set if there's only one PIC chip in the system
    // if false, ICW3 will be need to be sent
    single: bool,
    // If set, the call address interval is 4, otherwise 8. Ignored by x86
    call_address_interval: bool,
    // Whether the PIC will operate in Level Triggered Mode (true) or
    // in Edge Triggered Mode (false)
    level_triggered_mode: bool,
    // This needs to be set to true if the PIC needs to be initialized
    initialize: bool,
    // _reserved needs to be set to 0 in x86
    _reserved: u3 = 0,
};

const InitializationControlWord2 = packed struct {
    // This sets the base IRQ for the PIC. So, for example,
    // if 32 is set, the IRQ 0 would be 32, IRQ 1 would be 33, etc
    base_irq: u8,
};

const InitializationControlWord3Primary = packed struct {
    // Specifies at which IRQ the secondary PIC is connected to
    // This needs to be in binary form, starting from the right
    // e.g. 0b00000100 => IRQ 2 => 0x4
    secondary_irq: u8,
};

const InitializationControlWord3Secondary = packed struct {
    // Specifies at which IRQ the seconadry PIC is connected to in the primary PIC
    secondary_irq: u2,
    // _reserved needs to be set to 0 in x86
    _reserved: u6 = 0,
};

const InitializationControlWord4 = packed struct {
    // This sets the PIC to work in the 80x86 mode
    @"80x86_mode": bool,
    // If this is set, the PIC automatically performs a EOI. Rarely used
    acknowledge_pulse: bool,
    // This selects the buffer as primary. Only to be set if buffered_mode = true
    buffer_primary: bool,
    // This needs to be set if the PIC needs to operate in buffered mode
    buffered_mode: bool,
    // This needs to be set in systems with a large number of nested PICs
    specially_nested: bool,
    // _reserved needs to be set to 0 in x86
    _reserved: u3 = 0,
};

const PicCommands = enum(u8) {
    // eoi (end of interrupt) is a PIC command that notifies that the
    // IRQ routine has finished. If the IRQ comes from the primary PIC,
    // needs to be sent to only the primary, but if it comes from the secondary,
    // both chips need to be notified
    eoi = 0x20,
};

pub fn init() void {
    // Send ICW1
    const icw1 = InitializationControlWord1{
        .icw4 = true,
        .single = false,
        .call_address_interval = false,
        .level_triggered_mode = false,
        .initialize = true,
    };

    helpers.outb(PIC_PRIMARY_COMMAND, helpers.structAsByte(icw1));
    helpers.ioWait();
    helpers.outb(PIC_SECONDARY_COMMAND, helpers.structAsByte(icw1));
    helpers.ioWait();

    // Send ICW2
    const icw2_primary = InitializationControlWord2{
        // We set the base IRQ as CPU_DESCRIPTORS, which specifies how many
        // exception interrupts the CPU has
        .base_irq = HARDWARE_INTERRUPTS_OFFSET,
    };

    const icw2_secondary = InitializationControlWord2{
        // We set the base IRQ as CPU_DESCRIPTORS, which specifies how many
        // exception interrupts the CPU has. Since this is the secondary PIC,
        // we
        .base_irq = HARDWARE_INTERRUPTS_OFFSET + PIC_IRQ_NUMBER,
    };

    helpers.outb(PIC_PRIMARY_DATA, helpers.structAsByte(icw2_primary));
    helpers.ioWait();
    helpers.outb(PIC_SECONDARY_DATA, helpers.structAsByte(icw2_secondary));
    helpers.ioWait();

    // Send ICW3
    const icw3_primary = InitializationControlWord3Primary{
        // Here we set the secondary PIC to IRQ2
        .secondary_irq = 1 << PIC_NESTED_IRQ_PRIMARY,
    };

    const icw3_secondary = InitializationControlWord3Secondary{
        // Here we set the secondary PIC to IRQ2
        .secondary_irq = PIC_NESTED_IRQ_PRIMARY,
    };

    helpers.outb(PIC_PRIMARY_DATA, helpers.structAsByte(icw3_primary));
    helpers.ioWait();
    helpers.outb(PIC_SECONDARY_DATA, helpers.structAsByte(icw3_secondary));
    helpers.ioWait();

    const icw4 = InitializationControlWord4{
        .@"80x86_mode" = true,
        .acknowledge_pulse = false,
        .buffer_primary = false,
        .buffered_mode = false,
        .specially_nested = false,
    };

    helpers.outb(PIC_PRIMARY_DATA, helpers.structAsByte(icw4));
    helpers.ioWait();
    helpers.outb(PIC_SECONDARY_DATA, helpers.structAsByte(icw4));
    helpers.ioWait();

    // Set the PIC masks
    helpers.outb(PIC_PRIMARY_DATA, helpers.structAsByte(PicPrimaryMask{
        .disable_keyboard = false,
    }));
    helpers.outb(PIC_SECONDARY_DATA, helpers.structAsByte(PicSecondaryMask{}));

    // Enable hardware interrupts
    asm volatile ("sti");
}

pub const HANDLER_NAME = "handleHardwareInterruption";
pub export fn handleHardwareInterruption(interrupt: u32) void {
    const irq = interrupt - HARDWARE_INTERRUPTS_OFFSET;

    std.log.scoped(.interrupt_hardware).info("Received interrupt #{d} (0x{x})", .{ interrupt, interrupt });

    if (irq == @intFromEnum(PicInterrupts.primary_keyboard)) {
        const scan_code = helpers.inb(0x60);
        std.log.info("Received keyboard interrupt code 0x{x}", .{scan_code});
    }

    // Notify the PICs that the interrupt handling has finished
    // If the IRQ came from the secondary PIC, notify both
    if (irq >= PIC_IRQ_NUMBER) {
        helpers.outb(PIC_SECONDARY_COMMAND, @intFromEnum(PicCommands.eoi));
    }
    helpers.outb(PIC_PRIMARY_COMMAND, @intFromEnum(PicCommands.eoi));
}
