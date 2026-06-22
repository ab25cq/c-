#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>

uniq void cminus_panic(const char* message, const char* file, int line)
{
    void* frames[64];
    int count;

    fprintf(stderr, "panic: %s at %s:%d\n", message, file, line);
    count = backtrace(frames, 64);
    backtrace_symbols_fd(frames, count, 2);
    abort();
}

enum __CMinusIndex<T> {
    Some(T),
    None,
};

generic<T>
struct Vec {
    T* data;
    int len;
    int cap;
};

generic<T>
struct Vec<T>*% Vec_new(void)
{
    return calloc(1, sizeof(struct Vec<T>));
}

generic<T>
void Vec_push(struct Vec<T>* self, T value)
{
    T* next;
    int next_cap = self->cap == 0 ? 4 : self->cap * 2;

    if (self->len >= self->cap) {
        next = realloc(self->data, sizeof(T) * next_cap);
        if (next == NULL) {
            abort();
        }
        self->data = next;
        self->cap = next_cap;
    }
    self->data[self->len++] = value;
}

generic<T>
void Vec_delete(struct Vec<T>* self)
{
    if (self != NULL) {
        free(self->data);
    }
}

generic<T>
T Vec_first(struct Vec<T>* self)
{
    return self->data[0];
}

generic<T>
struct __CMinusIndex<T> Vec_get_opt(struct Vec<T>* self, int index)
{
    if (self == NULL || index < 0 || index >= self->len) {
        return new __CMinusIndex<T>.None();
    }
    return new __CMinusIndex<T>.Some(self->data[index]);
}

generic<T>
struct ListNode {
    T value;
    struct ListNode<T>* next;
};

generic<T>
struct List {
    struct ListNode<T>* head;
    struct ListNode<T>* tail;
    int len;
};

generic<T>
struct List<T>*% List_new(void)
{
    return calloc(1, sizeof(struct List<T>));
}

generic<T>
void List_push(struct List<T>* self, T value)
{
    struct ListNode<T>* node = calloc(1, sizeof(struct ListNode<T>));

    if (node == NULL) {
        abort();
    }
    node->value = value;
    if (self->tail == NULL) {
        self->head = node;
        self->tail = node;
    } else {
        self->tail->next = node;
        self->tail = node;
    }
    self->len++;
}

generic<T>
void List_delete(struct List<T>* self)
{
    struct ListNode<T>* node;

    if (self == NULL) {
        return;
    }
    node = self->head;
    while (node != NULL) {
        struct ListNode<T>* next = node->next;
        free(node);
        node = next;
    }
}

generic<T>
T List_first(struct List<T>* self)
{
    return self->head->value;
}

generic<T>
struct __CMinusIndex<T> List_get_opt(struct List<T>* self, int index)
{
    struct ListNode<T>* node;
    int i;

    if (self == NULL || index < 0 || index >= self->len) {
        return new __CMinusIndex<T>.None();
    }
    node = self->head;
    i = 0;
    while (i < index) {
        node = node->next;
        i++;
    }
    return new __CMinusIndex<T>.Some(node->value);
}
