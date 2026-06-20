#define _GNU_SOURCE
#include <string.h>
typedef char* string;
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


struct Person
{
    string name;
    int age;
};

static void Person_finalize(struct Person* self)
{
    if (self == NULL) {
        return;
    }
    if (self->name != NULL) {
        free(self->name);
    }

}


static __attribute__((unused)) struct Person* Person_clone(struct Person* self)
{
    struct Person* copy = calloc(1, sizeof(struct Person));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    if (self->name != NULL) {
        copy->name = calloc(strlen(self->name) + 1, sizeof(char));
        strncpy(copy->name, self->name, strlen(self->name) + 1);
    }
    copy->age = self->age;
    return copy;
}


int main(void)
{
    struct Person* person = calloc(1, sizeof(struct Person));
    struct Person* p2 =({ struct Person* __right_value_src0 = person; struct Person* __right_value1 = NULL; if (__right_value_src0 != NULL) { __right_value1 = Person_clone(__right_value_src0); } __right_value1; });
    if (p2 != NULL) {
        Person_finalize(p2);
        free(p2);
    }

    if (person != NULL) {
        Person_finalize(person);
        free(person);
    }

    return 0;
}