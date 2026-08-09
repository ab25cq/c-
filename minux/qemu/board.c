#define UART0_BASE 0x20201000u
#define UART0_DR   (*(volatile unsigned int*)(UART0_BASE + 0x00u))
#define UART0_FR   (*(volatile unsigned int*)(UART0_BASE + 0x18u))
#define UART_FR_TXFF (1u << 5)

static void uart_putc(int c)
{
    if (c == '\n') {
        uart_putc('\r');
    }
    while ((UART0_FR & UART_FR_TXFF) != 0u) {
    }
    UART0_DR = (unsigned int)c;
}

int putchar(int c)
{
    uart_putc(c);
    return c;
}
