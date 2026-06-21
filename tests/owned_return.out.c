#include <stdlib.h>

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
    return malloc(sizeof(struct Pair));
}

int main(void)
{
    struct Pair* p = make_pair();
    if (p != NULL) {
        free(p);
    }

    return 0;
}