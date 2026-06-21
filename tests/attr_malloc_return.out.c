#include <stdlib.h>

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