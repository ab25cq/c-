#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(void)
{
    char* text;
    asprintf(&text, "aaa %d", 1+1);
    int ok = strcmp(text, "aaa 2");
    if (text != NULL) {
        free(text);
    }

    return ok;
}