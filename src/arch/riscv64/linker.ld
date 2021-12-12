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
    text_start = .;


    .text : {
        *(.text.entry)

        /* All text section off object file */
        *(.text .text.*)
    }


    rodata_start = .;
    .rodata : {
        *(.rodata .rodata.*)
    }

    data_start = .;
    .data : {
        *(.data .data.*)
    }

    bss_start = .;
    .bss : {
        *(.bss .bss.*)
    }

    kernel_end = .;


}