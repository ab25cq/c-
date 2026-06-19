#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
    int ok = strcmp(s"abc", "abc") == 0;
    return ok ? 0 : 1;
}
