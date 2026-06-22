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
struct data {
    int value;
};

static __attribute__((unused)) struct data* data_clone(struct data* self)
{
    struct data* copy = calloc(1, sizeof(struct data));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->value = self->value;
    return copy;
}


void data_show(struct data* self)
{
    self->value = 42;
}

int main(void)
{
    struct data d = {0};
    memset(&d, 0, sizeof(d));

    struct data* p = calloc(1, sizeof(struct data));

    data_show(&d);
    data_show(p);

    if (d.value != 42 || p->value != 42) {
        if (p != NULL) {
            free(p);
        }

        return 1;
    }
    if (strcmp("aaa", "aaa") != 0) {
        if (p != NULL) {
            free(p);
        }

        return 2;
    }
    if (p != NULL) {
        free(p);
    }

    return strcmp("aaa", "aaa");
}