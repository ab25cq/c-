#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
    int count = 0;

    if (strcmp(s"if", "if") == 0) {
        count++;
    } else if (strcmp(s"else", "else") == 0) {
        count = 100;
    }

    while (count < 2 && strcmp(s"while", "while") == 0) {
        count++;
    }

    do {
        count++;
    } while (count < 4 && strcmp(s"do", "do") == 0);

    return count == 4 ? 0 : 1;
}
