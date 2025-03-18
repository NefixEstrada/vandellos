# VandellOS

![VandellOS Artwork](./artwork.png)

Simple OS

## Tasks

- Language
  - std.mem.zeroes([ARRAY]) => var a: [ARRAY] = undefined
- Architecture agnostic
  - [ ] ACPI
    - [x] RSDP (v1)
    - [ ] RSDP (v2+)
    - [x] RSDT (v1)
    - [ ] RSDT (v2+)
- x86 (i386) architecture
  - [x] Multiboot
  - [x] VGA driver
  - [x] Interrupts & Descriptors
    - [ ] GDT
      - [x] Kernel Mode Segment
      - [ ] User Mode Segment
      - [ ] Tasks Mode Segment
    - [x] IDT
      - [x] CPU Interrupts
      - [x] Hardware interrupts
      - [ ] Software interrupts
    - [x] PIC
    - [ ] APIC
    - [ ] PIT
    - [ ] Improve CPU interrupts tracebacks
    - [ ] Serial
    - [ ] Get VGA / Serial / PIC ports from BDA
- [ ] VandellOS Kernel
  - [ ] Improve panic tracebacks

Original artwork from:

> Nicolas Vigier from Paris, France, CC BY 2.0 <https://creativecommons.org/licenses/by/2.0>, via Wikimedia Commons
