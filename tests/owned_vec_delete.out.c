#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
struct OwnedVec_int_ptr{
    int** data;
    int len;
    int cap;
};
struct OwnedVec_int_ptr* OwnedVec_new_int_ptr(void){
    return calloc(1, sizeof(struct OwnedVec_int_ptr));
}
void OwnedVec_push_int_ptr(struct OwnedVec_int_ptr* self, int* value){
    int** next;
    int next_cap = self->cap == 0 ? 4 : self->cap * 2;

    if (self->len >= self->cap) {
        next = realloc(self->data, sizeof(int*) * next_cap);
        if (next == NULL) {
            abort();
        }
        self->data = next;
        self->cap = next_cap;
    }
    self->data[self->len++] = value;
}
int OwnedVec_len_int_ptr(struct OwnedVec_int_ptr* self){
    return self == NULL ? 0 : self->len;
}
void OwnedVec_clear_int_ptr(struct OwnedVec_int_ptr* self){
    int i;

    if (self == NULL) {
        return;
    }
    i = 0;
    while (i < self->len) {
        free(self->data[i]);
        i++;
    }
    self->len = 0;
}
void OwnedVec_delete_int_ptr(struct OwnedVec_int_ptr* self){
    if (self != NULL) {
        OwnedVec_clear_int_ptr(self);
        free(self->data);
    }
}

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

int main(void)
{
    struct OwnedVec_int_ptr* a = OwnedVec_new_int_ptr();
    int* value = calloc(1, sizeof(int));

    *value = 42;
    OwnedVec_push_int_ptr(a, value);
    printf("%d\n", OwnedVec_len_int_ptr(a));

    if (a != NULL) {
        OwnedVec_delete_int_ptr(a);
        free(a);
    }

    return 0;
}