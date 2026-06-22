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
void* raw_alloc(size_t size) ;

void* raw_alloc(size_t size)
{
    return malloc(size);
}

int main(void)
{
    int* p = raw_alloc(sizeof(int));
    (void)p;
    return 0;
}