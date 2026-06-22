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
struct Holder {
    int* value;
};

static void Holder_finalize(struct Holder* self)
{
    if (self == NULL) {
        return;
    }
    if (self->value != NULL) {
        free(self->value);
    }

}


static __attribute__((unused)) struct Holder* Holder_clone(struct Holder* self)
{
    struct Holder* copy = calloc(1, sizeof(struct Holder));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    if (self->value != NULL) {
        copy->value = calloc(1, sizeof(int));
        *copy->value = *self->value;
    }
    return copy;
}


int main(void)
{
    struct Holder stack = {0};
    memset(&stack, 0, sizeof(stack));
    void* __owned_old0 = stack.value;

    stack.value = calloc(1, sizeof(int));
    if (__owned_old0 != NULL) {
        free(__owned_old0);
    }


    *stack.value = 10;

    struct Holder* heap = calloc(1, sizeof(struct Holder));    void* __owned_old1 = heap->value;

    heap->value = calloc(1, sizeof(int));
    if (__owned_old1 != NULL) {
        free(__owned_old1);
    }


    *heap->value = 20;

    Holder_finalize(&stack);
    if (heap != NULL) {
        Holder_finalize(heap);
        free(heap);
    }

    return 0;
}