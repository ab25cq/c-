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


union Cell {
    int i;
    char c;
};

enum Kind {
    KIND_A = 0,
    KIND_B = 1,
};

int main(void)
{
    struct Pair* p = calloc(1, sizeof(struct Pair));
    union Cell cell = {0};
    memset(&cell, 0, sizeof(cell));

    enum Kind kind = KIND_A;
    cell.i = 7;
    p->x = kind;
    if (p != NULL) {
        free(p);
    }

    return cell.i - 7;
}