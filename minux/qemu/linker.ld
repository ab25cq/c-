ENTRY(_start)

PHDRS
{
    text PT_LOAD FLAGS(5);
    data PT_LOAD FLAGS(6);
}

SECTIONS
{
    . = 0x8000;

    .text : {
        KEEP(*(.text.boot))
        *(.text*)
    } :text

    .rodata : {
        *(.rodata*)
    } :text

    .data : {
        *(.data*)
    } :data

    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } :data

    . = ALIGN(16);
    . = . + 0x1000;
    __irq_stack_top = .;
    . = ALIGN(16);
    . = . + 0x1000;
    __user_probe_stack_top = .;
    . = ALIGN(16);
    . = . + 0x4000;
    __stack_top = .;
}
