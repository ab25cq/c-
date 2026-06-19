#include <stdlib.h>

struct Pair {
    int x;
    int y;
};

int main(void)
{
    int value;
    struct Pair pair;
    int* ptr;
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
