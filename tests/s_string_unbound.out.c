#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(void)
{
    char* text;
    asprintf(&text, "abc");
    if (text != NULL) {
        free(text);
    }

    return 0;
}