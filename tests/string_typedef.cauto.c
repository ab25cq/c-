#include <stdlib.h>
#include <string.h>

typedef char*% string;

struct Person {
    string name;
    int age;
};

int main(void)
{
    struct Person*% person = new struct Person;
    (void)person;
    return 0;
}

