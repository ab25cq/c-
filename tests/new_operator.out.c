#include <stdlib.h>

struct Item {
    int value;
};

static __attribute__((unused)) struct Item* Item_clone(struct Item* self)
{
    struct Item* copy = calloc(1, sizeof(struct Item));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->value = self->value;
    return copy;
}


int main(void)
{
    int* owned = calloc(1, sizeof(int));
    struct Item* item = calloc(1, sizeof(struct Item));

    if (owned == NULL || item == NULL) {
        if (item != NULL) {
            free(item);
        }

        if (owned != NULL) {
            free(owned);
        }

        return 1;
    }
    *owned = 3;
    if (*owned != 3 || item->value != 0) {
        if (item != NULL) {
            free(item);
        }

        if (owned != NULL) {
            free(owned);
        }

        return 2;
    }
    if (item != NULL) {
        free(item);
    }

    if (owned != NULL) {
        free(owned);
    }

    return 0;
}