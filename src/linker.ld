/* Entrypoint of the bootloader */
ENTRY(_main)
 
SECTIONS {
	/* With EFI and Multiboot2 it's recommended to use 2M as offset */
	. = 1M;
 
	/* First, add the multiboot header, and the .text section afterwards*/
	.text : ALIGN(4K) {
		KEEP(*(.multiboot))
		*(.text)
	}
 
	/* Read only data */
	.rodata : ALIGN(4K) {
		*(.rodata*)
	}
 
	/* Read-write data (initialized) */
	.data : ALIGN(4K) {
		*(.data)
	}
 
	/* Read-write data and stack (uninitialized) */
	.bss : ALIGN(4K) {
		*(COMMON)
		*(.bss)
	}
}
