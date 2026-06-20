#include <stdlib.h>

struct Holder {
    int*% value;
};

int main(void)
{
    int*% owned = new int;
    struct Holder holder;

    owned = new int;
    holder.value = new int;
    holder.value = new int;

    if (owned == NULL || holder.value == NULL) {
        return 1;
    }
    return 0;
}
