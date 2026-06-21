#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
    char* __right_value0 = NULL;
    asprintf(&__right_value0, "aaaa %d", 1+1);
    puts(__right_value0);
    free(__right_value0);
    return 0;

