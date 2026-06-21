#include <stdlib.h>

int main(void)
{
    int* a = calloc(1, sizeof(int));
    *a = 123;
    if (a != NULL) {
        free(a);
    }

    return 0;
}