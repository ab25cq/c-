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
    int* owned = calloc(1, sizeof(int));
    struct Holder holder = {0};
    memset(&holder, 0, sizeof(holder));
    void* __owned_old0 = owned;


    owned = calloc(1, sizeof(int));
    if (__owned_old0 != NULL) {
        free(__owned_old0);
    }

    void* __owned_old1 = holder.value;

    holder.value = calloc(1, sizeof(int));
    if (__owned_old1 != NULL) {
        free(__owned_old1);
    }

    void* __owned_old2 = holder.value;

    holder.value = calloc(1, sizeof(int));
    if (__owned_old2 != NULL) {
        free(__owned_old2);
    }



    if (owned == NULL || holder.value == NULL) {
        Holder_finalize(&holder);
        if (owned != NULL) {
            free(owned);
        }

        return 1;
    }
    Holder_finalize(&holder);
    if (owned != NULL) {
        free(owned);
    }

    return 0;
}