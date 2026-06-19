#include <stdlib.h>

struct Item {
    int value;
};

int main(void)
{
    int*% owned = new int;
    int* unbound = new int;
    struct Item*% item = new struct Item;

    if (owned == NULL || item == NULL) {
        return 1;
    }
    *owned = 3;
    if (*owned != 3 || item->value != 0) {
        return 2;
    }
    return 0;
}
