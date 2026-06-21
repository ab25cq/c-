#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(void)
{
    char* __right_value0 = NULL;
    asprintf(&__right_value0, "abc");
    int ok = strcmp(__right_value0, "abc") == 0;
    free(__right_value0);
    return ok ? 0 : 1;
}