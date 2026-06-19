#include <stdlib.h>

int main(void)
{
    int*% a = malloc(sizeof(int));
    *a = 123;
    return 0;
}
