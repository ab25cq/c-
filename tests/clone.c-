#include <stdlib.h>

struct Pair {
    int*% left;
    int*% right;
};

int main(void)
{
    struct Pair*% p = new struct Pair;
    int*% left_copy = new int;
    int*% right_copy = new int;

    p->left = new int;
    *p->left = 7;
    p->right = new int;
    *p->right = 9;

    left_copy = clone p->left;
    right_copy = clone p->right;
    struct Pair*% q = clone p;

    if (left_copy == NULL || right_copy == NULL || q == NULL) {
        return 1;
    }
    if (*left_copy != 7 || *right_copy != 9) {
        return 2;
    }
    if (q->left == NULL || q->right == NULL) {
        return 3;
    }
    if (q->left == p->left || q->right == p->right) {
        return 4;
    }
    if (*q->left != 7 || *q->right != 9) {
        return 5;
    }
    return 0;
}
