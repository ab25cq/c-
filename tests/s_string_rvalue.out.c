
#define _GNU_SOURCE
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>

void cminus_panic(const char* message, const char* file, int line)
{
    void* frames[64] = {0};
    memset(&frames, 0, sizeof(frames));

    int count = {0};
    memset(&count, 0, sizeof(count));


    fprintf(stderr, "panic: %s at %s:%d\n", message, file, line);
    count = backtrace(frames, 64);
    backtrace_symbols_fd(frames, count, 2);
    abort();
}
int main(void)
{
    char* __right_value0 = NULL;
    asprintf(&__right_value0, "abc");
    int ok = strcmp(__right_value0, "abc") == 0;
    free(__right_value0);
    return ok ? 0 : 1;
}