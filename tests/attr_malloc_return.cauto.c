#include <stdlib.h>

void* raw_alloc(size_t size) __attribute__((malloc));

void* raw_alloc(size_t size)
{
    return malloc(size);
}

int main(void)
{
    int* p = raw_alloc(sizeof(int));
    return 0;
}
