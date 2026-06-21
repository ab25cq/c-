#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef char*% string;

struct Person
{
    string name;
    int age;
};

int main(void)
{
    struct Person*% person = new struct Person;
    struct Person*% p2 = clone person;
    return 0;
}
