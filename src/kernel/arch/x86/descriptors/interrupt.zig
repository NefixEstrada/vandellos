///
/// Interrupts are "exceptions"
/// There are are CPU "exceptions" that break crash the whole OS (the first 32)
/// In order to avoid this, we need to:
///   1. Create a table that maps each "exception" with the handler for it
///   2. Tell the CPU to load that table instead of the default behaviour (crashing)
///
/// TODO: Fix this documentation
/// InterruptDescriptorTable is the actual table in memory
/// Using the initInterruptDescriptorTable we'll:
/// 1. Map each "exception to the table
/// 2. Tell the CPU to load the InterruptDescriptorTable as the actual IDT
///
const std = @import("std");
const global = @import("global.zig");

const MAX_DESCRIPTORS = 256;
const CPU_DESCRIPTORS = 32;

// Entry is an entry of the Interrupt Descriptor Table
// It basically contains the pointer to the handler (isr_low + isr_high)
// and some extra information
const Entry = packed struct {
    isr_low: u16,
    selector: u16,
    // _reserved needs to always be 0
    _reserved: u8 = 0,
    // TODO: Document why the attribites needs to be 0x8e
    type_attributes: u8 = 0x8e,
    isr_high: u16,
};

const TableRegistry = packed struct {
    limit: u16,
    base: u32,
};

var table = std.mem.zeroes([MAX_DESCRIPTORS]Entry);

// TODO: Document this
fn isrStub() callconv(.Naked) noreturn {
    asm volatile (
    // Clear the interrupt
        \\     cli

        // TODO: Push the interrupt number + memory
        // Call the handler
        \\     call handleException

        // Return to the program execution afterwards
        \\     iret
    );
}

pub export fn handleException() void {
    std.log.err("CPU exception!!!", .{});
    // fn exceptionName() []const u8 {
    //     const vec = 0;

    //     return switch (vec) {
    //         0 => "Division Error",
    //         1 => "Debug",
    //         2 => "Non-maskable Interrupt",
    //         3 => "Breakpoint",
    //         4 => "Overflow",
    //         5 => "Bound Range Exceeded",
    //         6 => "Invalid Opcode",
    //         7 => "Device Not Available",
    //         8 => "Double Fault",
    //         9 => "Coprocessor Segment Overrun",
    //         10 => "Invalid TSS",
    //         11 => "Segment Not Present",
    //         12 => "Stack-Segment Fault",
    //         13 => "General Protection Fault",
    //         14 => "Page Fault",
    //         15 => "Reserved",
    //         16 => "x87 Floating-Point Exception",
    //         17 => "Alignment Check",
    //         18 => "Machine Check",
    //         19 => "SIMD Floating-Point Exception",
    //         20 => "Virtualization Exception",
    //         21 => "Control Protection Exception",
    //         22...27 => "Reserved",
    //         28 => "Hypervisor Injection Exception",
    //         29 => "VMM Communication Exception",
    //         30 => "Security Exception",
    //         31 => "Reserved",
    //         else => "Unknown",
    //     };
    // }

    // pub fn handleException() void {
    //     // std.log.err("Exception #{d} ({x}): {s}", .{ vec, vec, exceptionName() });
    // }
}

pub fn init() void {
    for (0..CPU_DESCRIPTORS) |i| {
        // Generate the table entry
        table[i] = .{
            // Set the isr lower bits of the address of the handler
            .isr_low = @truncate(@intFromPtr(&isrStub)),
            // Set the isr high bits of the address of the handler
            .isr_high = @truncate(@intFromPtr(&isrStub) >> 16),
            // Set this value to the kernel code selector of the GDT
            .selector = global.KERNEL_MODE_CODE_SELECTOR_OFFSET,
        };
    }

    const table_registry = TableRegistry{
        .limit = @sizeOf(Entry) * MAX_DESCRIPTORS - 1,
        .base = @intFromPtr(&table[0]),
    };

    // Load the interrupt descriptor table register
    asm volatile (
        \\ lidt %[tbl_reg]
        :
        : [tbl_reg] "*p" (&table_registry),
    );
}
