#include <stdlib.h>

struct Holder {
    int*% value;
};

int main(void)
{
    struct Holder stack;
    stack.value = new int;
    *stack.value = 10;

    struct Holder*% heap = new struct Holder;
    heap->value = new int;
    *heap->value = 20;

    return 0;
}
