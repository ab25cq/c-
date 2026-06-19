#include <stdlib.h>

struct Pair {
    int x;
    int y;
};

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
    struct Pair*% p = malloc(sizeof(struct Pair));
    union Cell cell;
    enum Kind kind = KIND_A;
    cell.i = 7;
    p->x = kind;
    return cell.i - 7;
}
