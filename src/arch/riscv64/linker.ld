/* Linker file */

/* Apply memory mapping to adapt to riscv OpenSBI */

/* Architecture */
OUTPUT_ARCH(riscv)

/* Entry Point */
ENTRY(_start)

/* OpenSBI transfer control to this address */
BASE_ADDRESS = 0x80200000;

SECTIONS
{
    . = BASE_ADDRESS;
    kernel_start = .;

    . = ALIGN(4K); /* alignment  for page size 4k */
    text_start = .;


    .text : {
        *(.text.entry)

        /* All text section off object file */
        *(.text .text.*)
    }

    . = ALIGN(4K); /* alignment  for page size 4k */
    rodata_start = .;
    .rodata : {
        *(.rodata .rodata.*)
        __debug_info_start = .;
        KEEP(*(.debug_info))
        __debug_info_end = .;
        __debug_abbrev_start = .;
        KEEP(*(.debug_abbrev))
        __debug_abbrev_end = .;
        __debug_str_start = .;
        KEEP(*(.debug_str))
        __debug_str_end = .;
        __debug_line_start = .;
        KEEP(*(.debug_line))
        __debug_line_end = .;
        __debug_ranges_start = .;
        KEEP(*(.debug_ranges))
        __debug_ranges_end = .;
    }

    . = ALIGN(4K); /* alignment  for page size 4k */
    data_start = .;
    .data : {
        *(.data .data.*)
        *(.sdata .sdata.*)
    }

    . = ALIGN(4K); /* alignment  for page size 4k */
    .stack : {
        *(.bss.stack)
    }

    . = ALIGN(4K); /* alignment  for page size 4k */
    bss_start = .;
    .bss : {
        *(.bss .bss.*)
        *(.sbss .sbss.*)
    }

    . = ALIGN(4K); /* alignment  for page size 4k */
    PROVIDE(kernel_end = .);


}