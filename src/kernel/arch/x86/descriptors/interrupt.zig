///
/// Interrupts are signals from a device (CPU, keyboard, etc)
/// When an interrupt happens, everything stops and the CPU executes another part of
/// the program. Afterwards, the program goes back to what was happening before
///
/// There are 3 types of interrupts:
/// 1. Exceptions: those are generated by the CPU itself and are generally errors
/// 2. Interrupt ReQuests (IRQ) / Hardware Interrupts: those are generated by the chipset, for example, a keypress event in the keyboard
/// 3. Software Interrupts: Those interrupts are generated by software running on the CPU signaling the kernel to do something. Usually, those are system calls
///
/// In order to know what to do when an interrupt happens, we use the IDT (Interrupt Descriptor Table)
/// This table is responsible to map the handler for each interrupt
///
/// Exceptions:
/// The exceptions are CPU "errors". Some of those halt the whole OS, some of those
/// only print an error and the execution can continue. The Exceptions have the first
/// 32 entries in the table reserved [0-31]. Each entry represents a different exception
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

// An ISR Stub is the Interrupt Service Routine (interrupt handler) that is called
// directly by the CPU when an interrupt happens
const IsrStub = fn () callconv(.Naked) noreturn;

// This generates the ISR stubs for the exceptions
fn generateIsrExceptionStub(interrupt: u32) IsrStub {
    return struct {
        fn _() callconv(.Naked) noreturn {
            asm volatile (
            // Set the interrupt number as the first argument to the function call
                \\ pushl %[itrpt]

                // Call the handler
                \\ call handleException

                // Clear the first argument of the function call (push 4 bytes to the stack)
                \\ addl $4, %esp

                // Return to the program execution afterwards
                \\ iret
                :
                : [itrpt] "r" (interrupt),
            );
        }
    }._;
}
fn exceptionName(interrupt: u32) []const u8 {
    return switch (interrupt) {
        0 => "Division Error",
        1 => "Debug",
        2 => "Non-maskable Interrupt",
        3 => "Breakpoint",
        4 => "Overflow",
        5 => "Bound Range Exceeded",
        6 => "Invalid Opcode",
        7 => "Device Not Available",
        8 => "Double Fault",
        9 => "Coprocessor Segment Overrun",
        10 => "Invalid TSS",
        11 => "Segment Not Present",
        12 => "Stack-Segment Fault",
        13 => "General Protection Fault",
        14 => "Page Fault",
        15 => "Reserved",
        16 => "x87 Floating-Point Exception",
        17 => "Alignment Check",
        18 => "Machine Check",
        19 => "SIMD Floating-Point Exception",
        20 => "Virtualization Exception",
        21 => "Control Protection Exception",
        22...27 => "Reserved",
        28 => "Hypervisor Injection Exception",
        29 => "VMM Communication Exception",
        30 => "Security Exception",
        31 => "Reserved",
        else => "Unknown",
    };
}

pub export fn handleException(interrupt: u32) void {
    std.log.scoped(.interrupt_exception).err("Exception #{d} (0x{x}): {s}", .{ interrupt, interrupt, exceptionName(interrupt) });
}

pub fn init() void {
    // Generate the IDT entries for the Exception interrupts (CPU errors)
    inline for (0..CPU_DESCRIPTORS) |i| {
        const stub = generateIsrExceptionStub(@intCast(i));

        // Generate the table entry
        table[i] = .{
            // Set the isr lower bits of the address of the handler
            .isr_low = @truncate(@intFromPtr(&stub)),
            // Set the isr high bits of the address of the handler
            .isr_high = @truncate(@intFromPtr(&stub) >> 16),
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
