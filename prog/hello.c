/* prog/hello.c */

/* UART base address -- write a byte here to transmit it */
#define UART_BASE (*(volatile unsigned int *)0x10000000)

void uart_putchar(char c) {
    UART_BASE = (unsigned int)c;
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putchar(*s++);
    }
}

int main() {
    uart_puts("Hello from my RISC-V CPU!\n");
    return 0;
}