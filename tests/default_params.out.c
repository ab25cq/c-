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
static int last_a;
static int last_b;
static int last_c;

void fun(int a, int b, int c);

void fun(int a, int b, int c)
{
    last_a = a;
    last_b = b;
    last_c = c;
}

int main(void)
{
    int b = 111;

    fun(b + 1, 22, 33);
    if (last_a != 112 || last_b != 22 || last_c != 33) {
        return 1;
    }

    fun(7, 22, 9);
    if (last_a != 7 || last_b != 22 || last_c != 9) {
        return 2;
    }

    fun(1, 22, 3);
    if (last_a != 1 || last_b != 22 || last_c != 3) {
        return 3;
    }

    return 0;
}