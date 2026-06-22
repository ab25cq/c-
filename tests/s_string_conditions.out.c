
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
    int count = 0;

    if (({ char* __right_value0 = NULL; asprintf(&__right_value0, "if"); int __right_value_cond1 = strcmp(__right_value0, "if") == 0; free(__right_value0); __right_value_cond1; })) {
        count++;
    } else if (({ char* __right_value2 = NULL; asprintf(&__right_value2, "else"); int __right_value_cond3 = strcmp(__right_value2, "else") == 0; free(__right_value2); __right_value_cond3; })) {
        count = 100;
    }

    while (({ char* __right_value4 = NULL; asprintf(&__right_value4, "while"); int __right_value_cond5 = count < 2 && strcmp(__right_value4, "while") == 0; free(__right_value4); __right_value_cond5; })) {
        count++;
    }

    do {
        count++;
    } while (({ char* __right_value6 = NULL; asprintf(&__right_value6, "do"); int __right_value_cond7 = count < 4 && strcmp(__right_value6, "do") == 0; free(__right_value6); __right_value_cond7; }));

    return count == 4 ? 0 : 1;
}