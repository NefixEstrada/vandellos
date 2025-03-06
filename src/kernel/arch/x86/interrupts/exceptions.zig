const std = @import("std");

// An ISR Stub is the Interrupt Service Routine (interrupt handler) that is called
// directly by the CPU when an interrupt happens
// This generates the ISR stubs for the exceptions
pub fn generateIsrStub(interrupt: u32) fn () callconv(.Naked) noreturn {
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

pub export fn handleException(interrupt: u32) void {
    const name = switch (interrupt) {
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

    std.log.scoped(.interrupt_exception).err("Exception #{d} (0x{x}): {s}", .{
        interrupt,
        interrupt,
        name,
    });
}
