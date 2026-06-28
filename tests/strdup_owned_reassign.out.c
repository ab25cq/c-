#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>

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
struct Data {
    char* text;
};

static void Data_finalize(struct Data* self)
{
    if (self == NULL) {
        return;
    }
    if (self->text != NULL) {
        free(self->text);
    }

}


static __attribute__((unused)) struct Data* Data_clone(struct Data* self)
{
    struct Data* copy = calloc(1, sizeof(struct Data));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    if (self->text != NULL) {
        copy->text = calloc(strlen(self->text) + 1, sizeof(char));
        strncpy(copy->text, self->text, strlen(self->text) + 1);
    }
    return copy;
}


int main(void)
{
    struct Data data = {0};
    memset(&data, 0, sizeof(data));
    void* __owned_old0 = data.text;


    data.text = strdup("aaa");
    if (__owned_old0 != NULL) {
        free(__owned_old0);
    }

    void* __owned_old1 = data.text;

    data.text = strdup("bbb");
    if (__owned_old1 != NULL) {
        free(__owned_old1);
    }


    if (strcmp(data.text, "bbb") != 0) {
        Data_finalize(&data);
        return 1;
    }
    Data_finalize(&data);
    return 0;
}