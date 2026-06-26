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
struct Pair {
    int x;
};

static __attribute__((unused)) struct Pair* Pair_clone(struct Pair* self)
{
    struct Pair* copy = calloc(1, sizeof(struct Pair));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->x = self->x;
    return copy;
}


struct Pair* make_pair(void);

struct Pair* make_pair(void)
{
    struct Pair* p = malloc(sizeof(struct Pair));
    return p;
}

int main(void)
{
    struct Pair* p = make_pair();
    if (p != NULL) {
        free(p);
    }

    return 0;
}