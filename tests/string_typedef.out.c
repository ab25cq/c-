#include <string.h>
#include <stdlib.h>
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
    struct Person* person = calloc(1, sizeof(struct Person));
    (void)person;
    if (person != NULL) {
        Person_finalize(person);
        free(person);
    }

    return 0;
}