#include <string.h>
#include <stdlib.h>

struct Pair {
    int x;
    int y;
};

static __attribute__((unused)) struct Pair* Pair_clone(struct Pair* self)
{
    struct Pair* copy = calloc(1, sizeof(struct Pair));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->x = self->x;
    copy->y = self->y;
    return copy;
}


int main(void)
{
    int value = {0};
    memset(&value, 0, sizeof(value));

    struct Pair pair = {0};
    memset(&pair, 0, sizeof(pair));

    int* ptr = {0};
    memset(&ptr, 0, sizeof(ptr));

    int initialized = 7;

    if (value != 0) {
        return 1;
    }
    if (pair.x != 0 || pair.y != 0) {
        return 2;
    }
    if (ptr != NULL) {
        return 3;
    }
    if (initialized != 7) {
        return 4;
    }
    return 0;
}