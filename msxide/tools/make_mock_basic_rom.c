#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#define ROM_SIZE 0x8000

static void put16(unsigned char *rom, int pos, unsigned short value)
{
    rom[pos] = (unsigned char)(value & 255);
    rom[pos + 1] = (unsigned char)(value >> 8);
}

int main(int argc, char **argv)
{
    const char *path = argc > 1 ? argv[1] : "roms/msx.rom";
    unsigned char rom[ROM_SIZE];
    const char *msg =
        "C- BASIC 0.1\r\n"
        "COPYRIGHT FREE CLEAN-ROOM ROM\r\n"
        "OK\r\n";
    FILE *fp;
    int p = 0;

    memset(rom, 0, sizeof(rom));
    mkdir("roms", 0777);

    rom[p++] = 0x31;
    put16(rom, p, 0xf380);
    p += 2;
    rom[p++] = 0x21;
    put16(rom, p, 0x0010);
    p += 2;
    rom[p++] = 0x7e;
    rom[p++] = 0xb7;
    rom[p++] = 0x28;
    rom[p++] = 0x05;
    rom[p++] = 0xd3;
    rom[p++] = 0x2f;
    rom[p++] = 0x23;
    rom[p++] = 0x18;
    rom[p++] = 0xf7;
    rom[p++] = 0x76;

    memcpy(rom + 0x0010, msg, strlen(msg) + 1);

    fp = fopen(path, "wb");
    if (fp == NULL) {
        perror(path);
        return 1;
    }
    if (fwrite(rom, 1, sizeof(rom), fp) != sizeof(rom)) {
        perror(path);
        fclose(fp);
        return 1;
    }
    fclose(fp);
    printf("wrote %s (%d bytes)\n", path, ROM_SIZE);
    return 0;
}
