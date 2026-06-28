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
char* x(void)
{
    return strdup("aaa");
}

int main(void)
{
    char* __right_value0 = x();

    char* p = __right_value0 + 1;
    if (__right_value0 != NULL) {
        free(__right_value0);
    }

    (void)p;
    char* __right_value1 = x();

    (void)__right_value1;
    if (__right_value1 != NULL) {
        free(__right_value1);
    }

    if (({ char* __right_value2 = x(); int __right_value_cond3 = (__right_value2) != 0; if (__right_value2 != NULL) {
    free(__right_value2);
}
__right_value_cond3; })) {
        (void)0;
    }
    return 0;
}