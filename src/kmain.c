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
    puts("Hello world!");
    return;
}