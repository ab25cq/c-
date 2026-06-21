#include <stdlib.h>

struct Pair {
    int* left;
    int* right;
};

static void Pair_finalize(struct Pair* self)
{
    if (self == NULL) {
        return;
    }
    if (self->left != NULL) {
        free(self->left);
    }

    if (self->right != NULL) {
        free(self->right);
    }

}


static __attribute__((unused)) struct Pair* Pair_clone(struct Pair* self)
{
    struct Pair* copy = calloc(1, sizeof(struct Pair));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    if (self->left != NULL) {
        copy->left = calloc(1, sizeof(int));
        *copy->left = *self->left;
    }
    if (self->right != NULL) {
        copy->right = calloc(1, sizeof(int));
        *copy->right = *self->right;
    }
    return copy;
}


int main(void)
{
    struct Pair* p = calloc(1, sizeof(struct Pair));
    int* left_copy = calloc(1, sizeof(int));
    int* right_copy = calloc(1, sizeof(int));    void* __owned_old0 = p->left;


    p->left = calloc(1, sizeof(int));
    if (__owned_old0 != NULL) {
        free(__owned_old0);
    }


    *p->left = 7;    void* __owned_old1 = p->right;

    p->right = calloc(1, sizeof(int));
    if (__owned_old1 != NULL) {
        free(__owned_old1);
    }


    *p->right = 9;    void* __owned_old4 = left_copy;


    left_copy =({ int* __right_value_src2 = p->left; int* __right_value3 = NULL; if (__right_value_src2 != NULL) { __right_value3 = calloc(1, sizeof(int)); *__right_value3 = *__right_value_src2; } __right_value3; });
    if (__owned_old4 != NULL) {
        free(__owned_old4);
    }

    void* __owned_old7 = right_copy;

    right_copy =({ int* __right_value_src5 = p->right; int* __right_value6 = NULL; if (__right_value_src5 != NULL) { __right_value6 = calloc(1, sizeof(int)); *__right_value6 = *__right_value_src5; } __right_value6; });
    if (__owned_old7 != NULL) {
        free(__owned_old7);
    }


    struct Pair* q =({ struct Pair* __right_value_src8 = p; struct Pair* __right_value9 = NULL; if (__right_value_src8 != NULL) { __right_value9 = Pair_clone(__right_value_src8); } __right_value9; });

    if (left_copy == NULL || right_copy == NULL || q == NULL) {
        if (q != NULL) {
            Pair_finalize(q);
            free(q);
        }

        if (right_copy != NULL) {
            free(right_copy);
        }

        if (left_copy != NULL) {
            free(left_copy);
        }

        if (p != NULL) {
            Pair_finalize(p);
            free(p);
        }

        return 1;
    }
    if (*left_copy != 7 || *right_copy != 9) {
        if (q != NULL) {
            Pair_finalize(q);
            free(q);
        }

        if (right_copy != NULL) {
            free(right_copy);
        }

        if (left_copy != NULL) {
            free(left_copy);
        }

        if (p != NULL) {
            Pair_finalize(p);
            free(p);
        }

        return 2;
    }
    if (q->left == NULL || q->right == NULL) {
        if (q != NULL) {
            Pair_finalize(q);
            free(q);
        }

        if (right_copy != NULL) {
            free(right_copy);
        }

        if (left_copy != NULL) {
            free(left_copy);
        }

        if (p != NULL) {
            Pair_finalize(p);
            free(p);
        }

        return 3;
    }
    if (q->left == p->left || q->right == p->right) {
        if (q != NULL) {
            Pair_finalize(q);
            free(q);
        }

        if (right_copy != NULL) {
            free(right_copy);
        }

        if (left_copy != NULL) {
            free(left_copy);
        }

        if (p != NULL) {
            Pair_finalize(p);
            free(p);
        }

        return 4;
    }
    if (*q->left != 7 || *q->right != 9) {
        if (q != NULL) {
            Pair_finalize(q);
            free(q);
        }

        if (right_copy != NULL) {
            free(right_copy);
        }

        if (left_copy != NULL) {
            free(left_copy);
        }

        if (p != NULL) {
            Pair_finalize(p);
            free(p);
        }

        return 5;
    }
    if (q != NULL) {
        Pair_finalize(q);
        free(q);
    }

    if (right_copy != NULL) {
        free(right_copy);
    }

    if (left_copy != NULL) {
        free(left_copy);
    }

    if (p != NULL) {
        Pair_finalize(p);
        free(p);
    }

    return 0;
}