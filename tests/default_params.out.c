#include <stdio.h>

static int last_a;
static int last_b;
static int last_c;

void fun(int a, int b, int c);

void fun(int a, int b, int c)
{
    last_a = a;
    last_b = b;
    last_c = c;
}

int main(void)
{
    int b = 111;

    fun(b + 1, 22, 33);
    if (last_a != 112 || last_b != 22 || last_c != 33) {
        return 1;
    }

    fun(7, 22, 9);
    if (last_a != 7 || last_b != 22 || last_c != 9) {
        return 2;
    }

    fun(1, 22, 3);
    if (last_a != 1 || last_b != 22 || last_c != 3) {
        return 3;
    }

    return 0;
}