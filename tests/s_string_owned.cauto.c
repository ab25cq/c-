#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
    char*% text = s"aaa \{1+1}";
    int ok = strcmp(text, "aaa 2");
    return ok;
}
