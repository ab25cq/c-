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
struct Child {
    int* value;
};

static void Child_finalize(struct Child* self)
{
    if (self == NULL) {
        return;
    }
    if (self->value != NULL) {
        free(self->value);
    }

}


static __attribute__((unused)) struct Child* Child_clone(struct Child* self)
{
    struct Child* copy = calloc(1, sizeof(struct Child));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    if (self->value != NULL) {
        copy->value = calloc(1, sizeof(int));
        *copy->value = *self->value;
    }
    return copy;
}


struct Holder {
    struct Child* child;
};

static void Holder_finalize(struct Holder* self)
{
    if (self == NULL) {
        return;
    }
    if (self->child != NULL) {
        Child_finalize(self->child);
        free(self->child);
    }

}


static __attribute__((unused)) struct Holder* Holder_clone(struct Holder* self)
{
    struct Holder* copy = calloc(1, sizeof(struct Holder));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    if (self->child != NULL) {
        copy->child = Child_clone(self->child);
    }
    return copy;
}


int main(void)
{
    struct Holder holder = {0};
    memset(&holder, 0, sizeof(holder));
    void* __owned_old0 = holder.child;


    holder.child = calloc(1, sizeof(struct Child));
    if (__owned_old0 != NULL) {
        Child_finalize(__owned_old0);
        free(__owned_old0);
    }

    void* __owned_old1 = holder.child->value;

    holder.child->value = calloc(1, sizeof(int));
    if (__owned_old1 != NULL) {
        free(__owned_old1);
    }

    void* __owned_old2 = holder.child;

    holder.child = calloc(1, sizeof(struct Child));
    if (__owned_old2 != NULL) {
        Child_finalize(__owned_old2);
        free(__owned_old2);
    }



    if (holder.child == NULL) {
        Holder_finalize(&holder);
        return 1;
    }
    Holder_finalize(&holder);
    return 0;
}