#define _GNU_SOURCE
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
typedef char* string;
#include <string.h>

struct Person {
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
    string source;
    asprintf(&source, "Alice");
    struct Person* person = calloc(1, sizeof(struct Person));    void* __owned_old2 = person->name;


    person->name =({ char* __right_value_src0 = source; char* __right_value1 = NULL; if (__right_value_src0 != NULL) { __right_value1 = calloc(strlen(__right_value_src0) + 1, sizeof(char)); strncpy(__right_value1, __right_value_src0, strlen(__right_value_src0) + 1); } __right_value1; });
    if (__owned_old2 != NULL) {
        free(__owned_old2);
    }


    person->age = 42;
    struct Person* copy =({ struct Person* __right_value_src3 = person; struct Person* __right_value4 = NULL; if (__right_value_src3 != NULL) { __right_value4 = Person_clone(__right_value_src3); } __right_value4; });

    if (person->name == NULL || copy == NULL || copy->name == NULL) {
        if (copy != NULL) {
            Person_finalize(copy);
            free(copy);
        }

        if (person != NULL) {
            Person_finalize(person);
            free(person);
        }

        if (source != NULL) {
            free(source);
        }

        return 1;
    }
    if (copy->name == person->name) {
        if (copy != NULL) {
            Person_finalize(copy);
            free(copy);
        }

        if (person != NULL) {
            Person_finalize(person);
            free(person);
        }

        if (source != NULL) {
            free(source);
        }

        return 2;
    }
    if (strcmp(copy->name, "Alice") != 0 || copy->age != 42) {
        if (copy != NULL) {
            Person_finalize(copy);
            free(copy);
        }

        if (person != NULL) {
            Person_finalize(person);
            free(person);
        }

        if (source != NULL) {
            free(source);
        }

        return 3;
    }
    if (copy != NULL) {
        Person_finalize(copy);
        free(copy);
    }

    if (person != NULL) {
        Person_finalize(person);
        free(person);
    }

    if (source != NULL) {
        free(source);
    }

    return 0;
}