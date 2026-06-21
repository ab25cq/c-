#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

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