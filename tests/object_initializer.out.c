#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
typedef char* string;

void cminus_panic(const char* message, const char* file, int line)
{
    void* frames[64] = {0};
    memset(&frames, 0, sizeof(frames));

    int count = {0};
    memset(&count, 0, sizeof(count));


    fprintf(stderr, "panic: %s at %s:%d\n", message, file, line);
    count = backtrace(frames, 64);
    backtrace_symbols_fd(frames, count, 2);
    abort();
}

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
    struct Person* person = ({ struct Person* __right_value0 = calloc(1, sizeof(struct Person)); if (__right_value0 != NULL) { __right_value0->name = strdup("aaa"); __right_value0->age = 48; } __right_value0; });

    if (strcmp(person->name, "aaa") != 0) {
        if (person != NULL) {
            Person_finalize(person);
            free(person);
        }

        return 1;
    }
    if (person->age != 48) {
        if (person != NULL) {
            Person_finalize(person);
            free(person);
        }

        return 2;
    }
    if (person != NULL) {
        Person_finalize(person);
        free(person);
    }

    return 0;
}