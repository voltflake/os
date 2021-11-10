void puts(char* string) {
    char *vidmem = (char *) 0xB8000;
    char *next_char = string;
    while (*string) {
        *vidmem = *next_char;
        next_char++;
        vidmem += 2;
    }
}

void kmain(void) {
    puts("0123456789");
    return;
}