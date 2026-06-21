#include <stdlib.h>

void fill(void)
{
    int* a = calloc(1, sizeof(int));
    *a = 456;
    if (a != NULL) {
        free(a);
    }


}