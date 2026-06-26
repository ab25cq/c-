#include <stdlib.h>
#include <string.h>
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
struct Vec<T>* Vec_new(void)
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
int Vec_len(struct Vec<T>* self)
{
    return self == NULL ? 0 : self->len;
}

generic<T>
int Vec_capacity(struct Vec<T>* self)
{
    return self == NULL ? 0 : self->cap;
}

generic<T>
int Vec_is_empty(struct Vec<T>* self)
{
    return self == NULL || self->len == 0;
}

generic<T>
void Vec_clear(struct Vec<T>* self)
{
    if (self != NULL) {
        self->len = 0;
    }
}

generic<T>
int Vec_reserve(struct Vec<T>* self, int cap)
{
    T* next;

    if (self == NULL) {
        return 0;
    }
    if (cap <= self->cap) {
        return 1;
    }
    next = realloc(self->data, sizeof(T) * cap);
    if (next == NULL) {
        return 0;
    }
    self->data = next;
    self->cap = cap;
    return 1;
}

generic<T>
struct __CMinusIndex<T> Vec_pop_opt(struct Vec<T>* self)
{
    if (self == NULL || self->len <= 0) {
        return new __CMinusIndex<T>.None();
    }
    self->len--;
    return new __CMinusIndex<T>.Some(self->data[self->len]);
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
T Vec_last(struct Vec<T>* self)
{
    return self->data[self->len - 1];
}

generic<T>
T Vec_get(struct Vec<T>* self, int index)
{
    return self->data[index];
}

generic<T>
int Vec_set(struct Vec<T>* self, int index, T value)
{
    if (self == NULL || index < 0 || index >= self->len) {
        return 0;
    }
    self->data[index] = value;
    return 1;
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
struct List<T>* List_new(void)
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
void List_push_front(struct List<T>* self, T value)
{
    struct ListNode<T>* node = calloc(1, sizeof(struct ListNode<T>));

    if (node == NULL) {
        abort();
    }
    node->value = value;
    node->next = self->head;
    self->head = node;
    if (self->tail == NULL) {
        self->tail = node;
    }
    self->len++;
}

generic<T>
int List_len(struct List<T>* self)
{
    return self == NULL ? 0 : self->len;
}

generic<T>
int List_is_empty(struct List<T>* self)
{
    return self == NULL || self->len == 0;
}

generic<T>
void List_clear(struct List<T>* self)
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
    self->head = NULL;
    self->tail = NULL;
    self->len = 0;
}

generic<T>
struct __CMinusIndex<T> List_pop_front_opt(struct List<T>* self)
{
    struct ListNode<T>* node;
    T value;

    if (self == NULL || self->head == NULL) {
        return new __CMinusIndex<T>.None();
    }
    node = self->head;
    value = node->value;
    self->head = node->next;
    if (self->head == NULL) {
        self->tail = NULL;
    }
    self->len--;
    free(node);
    return new __CMinusIndex<T>.Some(value);
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
T List_last(struct List<T>* self)
{
    return self->tail->value;
}

generic<T>
T List_get(struct List<T>* self, int index)
{
    struct ListNode<T>* node = self->head;
    int i = 0;

    while (i < index) {
        node = node->next;
        i++;
    }
    return node->value;
}

generic<T>
int List_set(struct List<T>* self, int index, T value)
{
    struct ListNode<T>* node;
    int i;

    if (self == NULL || index < 0 || index >= self->len) {
        return 0;
    }
    node = self->head;
    i = 0;
    while (i < index) {
        node = node->next;
        i++;
    }
    node->value = value;
    return 1;
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

generic<K,V>
struct Map {
    K* keys;
    V* values;
    int* states;
    int len;
    int cap;
};

generic<K,V>
struct Map<K,V>* Map_new(void)
{
    return calloc(1, sizeof(struct Map<K,V>));
}

generic<K,V>
int Map_len(struct Map<K,V>* self)
{
    return self == NULL ? 0 : self->len;
}

generic<K,V>
int Map_is_empty(struct Map<K,V>* self)
{
    return self == NULL || self->len == 0;
}

generic<K,V>
int Map_set(struct Map<K,V>* self, K key, V value)
{
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL) {
        return 0;
    }
    if (self->cap == 0 || (self->len + 1) * 3 >= self->cap * 2) {
        K* old_keys = self->keys;
        V* old_values = self->values;
        int* old_states = self->states;
        int old_cap = self->cap;
        int next_cap = old_cap == 0 ? 16 : old_cap * 2;
        K* next_keys = calloc(next_cap, sizeof(K));
        V* next_values = calloc(next_cap, sizeof(V));
        int* next_states = calloc(next_cap, sizeof(int));

        if (next_keys == NULL || next_values == NULL || next_states == NULL) {
            free(next_keys);
            free(next_values);
            free(next_states);
            return 0;
        }
        i = 0;
        while (i < old_cap) {
            if (old_states[i] == 1) {
                unsigned char* old_bytes = (unsigned char*)&old_keys[i];
                unsigned long old_hash = 1469598103934665603UL;
                int j;
                int old_slot;

                j = 0;
                while (j < (int)sizeof(K)) {
                    old_hash ^= old_bytes[j];
                    old_hash *= 1099511628211UL;
                    j++;
                }
                old_slot = old_hash - (old_hash / next_cap) * next_cap;
                while (next_states[old_slot] == 1) {
                    old_slot = old_slot + 1;
                    if (old_slot >= next_cap) {
                        old_slot = 0;
                    }
                }
                next_keys[old_slot] = old_keys[i];
                next_values[old_slot] = old_values[i];
                next_states[old_slot] = 1;
            }
            i++;
        }
        free(old_keys);
        free(old_values);
        free(old_states);
        self->keys = next_keys;
        self->values = next_values;
        self->states = next_states;
        self->cap = next_cap;
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            self->values[slot] = value;
            return 1;
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    self->keys[slot] = key;
    self->values[slot] = value;
    self->states[slot] = 1;
    self->len++;
    return 1;
}

generic<K,V>
struct __CMinusIndex<V> Map_get_opt(struct Map<K,V>* self, K key)
{
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL || self->cap == 0) {
        return new __CMinusIndex<V>.None();
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            return new __CMinusIndex<V>.Some(self->values[slot]);
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return new __CMinusIndex<V>.None();
}

generic<K,V>
int Map_contains(struct Map<K,V>* self, K key)
{
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL || self->cap == 0) {
        return 0;
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            return 1;
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return 0;
}

generic<K,V>
int Map_remove(struct Map<K,V>* self, K key)
{
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL || self->cap == 0) {
        return 0;
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            self->states[slot] = 2;
            self->len--;
            return 1;
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return 0;
}

generic<K,V>
void Map_clear(struct Map<K,V>* self)
{
    if (self == NULL) {
        return;
    }
    free(self->keys);
    free(self->values);
    free(self->states);
    self->keys = NULL;
    self->values = NULL;
    self->states = NULL;
    self->len = 0;
    self->cap = 0;
}

generic<K,V>
void Map_delete(struct Map<K,V>* self)
{
    if (self != NULL) {
        free(self->keys);
        free(self->values);
        free(self->states);
    }
}

generic<T>
struct OwnedVec {
    T* data;
    int len;
    int cap;
};

generic<T>
struct OwnedVec<T>* OwnedVec_new(void)
{
    return calloc(1, sizeof(struct OwnedVec<T>));
}

generic<T>
void OwnedVec_push(struct OwnedVec<T>* self, T value)
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
int OwnedVec_len(struct OwnedVec<T>* self)
{
    return self == NULL ? 0 : self->len;
}

generic<T>
int OwnedVec_is_empty(struct OwnedVec<T>* self)
{
    return self == NULL || self->len == 0;
}

generic<T>
void OwnedVec_clear(struct OwnedVec<T>* self)
{
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

generic<T>
struct __CMinusIndex<T> OwnedVec_pop_opt(struct OwnedVec<T>* self)
{
    if (self == NULL || self->len <= 0) {
        return new __CMinusIndex<T>.None();
    }
    self->len--;
    return new __CMinusIndex<T>.Some(self->data[self->len]);
}

generic<T>
void OwnedVec_delete(struct OwnedVec<T>* self)
{
    if (self != NULL) {
        OwnedVec_clear<T>(self);
        free(self->data);
    }
}

generic<T>
T OwnedVec_get(struct OwnedVec<T>* self, int index)
{
    return self->data[index];
}

generic<T>
int OwnedVec_set(struct OwnedVec<T>* self, int index, T value)
{
    if (self == NULL || index < 0 || index >= self->len) {
        return 0;
    }
    free(self->data[index]);
    self->data[index] = value;
    return 1;
}

generic<T>
struct __CMinusIndex<T> OwnedVec_get_opt(struct OwnedVec<T>* self, int index)
{
    if (self == NULL || index < 0 || index >= self->len) {
        return new __CMinusIndex<T>.None();
    }
    return new __CMinusIndex<T>.Some(self->data[index]);
}

generic<T>
struct OwnedList {
    T* data;
    int len;
    int cap;
};

generic<T>
struct OwnedList<T>* OwnedList_new(void)
{
    return calloc(1, sizeof(struct OwnedList<T>));
}

generic<T>
void OwnedList_push(struct OwnedList<T>* self, T value)
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
void OwnedList_push_front(struct OwnedList<T>* self, T value)
{
    T* next;
    int next_cap = self->cap == 0 ? 4 : self->cap * 2;
    int i;

    if (self->len >= self->cap) {
        next = realloc(self->data, sizeof(T) * next_cap);
        if (next == NULL) {
            abort();
        }
        self->data = next;
        self->cap = next_cap;
    }
    i = self->len;
    while (i > 0) {
        self->data[i] = self->data[i - 1];
        i--;
    }
    self->data[0] = value;
    self->len++;
}

generic<T>
int OwnedList_len(struct OwnedList<T>* self)
{
    return self == NULL ? 0 : self->len;
}

generic<T>
int OwnedList_is_empty(struct OwnedList<T>* self)
{
    return self == NULL || self->len == 0;
}

generic<T>
void OwnedList_clear(struct OwnedList<T>* self)
{
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

generic<T>
struct __CMinusIndex<T> OwnedList_pop_front_opt(struct OwnedList<T>* self)
{
    T value;
    int i;

    if (self == NULL || self->len <= 0) {
        return new __CMinusIndex<T>.None();
    }
    value = self->data[0];
    i = 1;
    while (i < self->len) {
        self->data[i - 1] = self->data[i];
        i++;
    }
    self->len--;
    return new __CMinusIndex<T>.Some(value);
}

generic<T>
void OwnedList_delete(struct OwnedList<T>* self)
{
    if (self != NULL) {
        OwnedList_clear<T>(self);
        free(self->data);
    }
}

generic<T>
T OwnedList_get(struct OwnedList<T>* self, int index)
{
    return self->data[index];
}

generic<T>
int OwnedList_set(struct OwnedList<T>* self, int index, T value)
{
    if (self == NULL || index < 0 || index >= self->len) {
        return 0;
    }
    free(self->data[index]);
    self->data[index] = value;
    return 1;
}

generic<T>
struct __CMinusIndex<T> OwnedList_get_opt(struct OwnedList<T>* self, int index)
{
    if (self == NULL || index < 0 || index >= self->len) {
        return new __CMinusIndex<T>.None();
    }
    return new __CMinusIndex<T>.Some(self->data[index]);
}

generic<K,V>
struct OwnedMap {
    K* keys;
    V* values;
    int* states;
    int len;
    int cap;
};

generic<K,V>
struct OwnedMap<K,V>* OwnedMap_new(void)
{
    return calloc(1, sizeof(struct OwnedMap<K,V>));
}

generic<K,V>
int OwnedMap_len(struct OwnedMap<K,V>* self)
{
    return self == NULL ? 0 : self->len;
}

generic<K,V>
int OwnedMap_is_empty(struct OwnedMap<K,V>* self)
{
    return self == NULL || self->len == 0;
}

generic<K,V>
int OwnedMap_set(struct OwnedMap<K,V>* self, K key, V value)
{
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL) {
        return 0;
    }
    if (self->cap == 0 || (self->len + 1) * 3 >= self->cap * 2) {
        K* old_keys = self->keys;
        V* old_values = self->values;
        int* old_states = self->states;
        int old_cap = self->cap;
        int next_cap = old_cap == 0 ? 16 : old_cap * 2;
        K* next_keys = calloc(next_cap, sizeof(K));
        V* next_values = calloc(next_cap, sizeof(V));
        int* next_states = calloc(next_cap, sizeof(int));

        if (next_keys == NULL || next_values == NULL || next_states == NULL) {
            free(next_keys);
            free(next_values);
            free(next_states);
            return 0;
        }
        i = 0;
        while (i < old_cap) {
            if (old_states[i] == 1) {
                unsigned char* old_bytes = (unsigned char*)&old_keys[i];
                unsigned long old_hash = 1469598103934665603UL;
                int j;
                int old_slot;

                j = 0;
                while (j < (int)sizeof(K)) {
                    old_hash ^= old_bytes[j];
                    old_hash *= 1099511628211UL;
                    j++;
                }
                old_slot = old_hash - (old_hash / next_cap) * next_cap;
                while (next_states[old_slot] == 1) {
                    old_slot = old_slot + 1;
                    if (old_slot >= next_cap) {
                        old_slot = 0;
                    }
                }
                next_keys[old_slot] = old_keys[i];
                next_values[old_slot] = old_values[i];
                next_states[old_slot] = 1;
            }
            i++;
        }
        free(old_keys);
        free(old_values);
        free(old_states);
        self->keys = next_keys;
        self->values = next_values;
        self->states = next_states;
        self->cap = next_cap;
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            free(self->values[slot]);
            self->values[slot] = value;
            return 1;
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    self->keys[slot] = key;
    self->values[slot] = value;
    self->states[slot] = 1;
    self->len++;
    return 1;
}

generic<K,V>
struct __CMinusIndex<V> OwnedMap_get_opt(struct OwnedMap<K,V>* self, K key)
{
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL || self->cap == 0) {
        return new __CMinusIndex<V>.None();
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            return new __CMinusIndex<V>.Some(self->values[slot]);
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return new __CMinusIndex<V>.None();
}

generic<K,V>
int OwnedMap_contains(struct OwnedMap<K,V>* self, K key)
{
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL || self->cap == 0) {
        return 0;
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            return 1;
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return 0;
}

generic<K,V>
int OwnedMap_remove(struct OwnedMap<K,V>* self, K key)
{
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL || self->cap == 0) {
        return 0;
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            free(self->values[slot]);
            self->states[slot] = 2;
            self->len--;
            return 1;
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return 0;
}

generic<K,V>
void OwnedMap_clear(struct OwnedMap<K,V>* self)
{
    int i;

    if (self == NULL) {
        return;
    }
    i = 0;
    while (i < self->cap) {
        if (self->states[i] == 1) {
            free(self->values[i]);
        }
        i++;
    }
    free(self->keys);
    free(self->values);
    free(self->states);
    self->keys = NULL;
    self->values = NULL;
    self->states = NULL;
    self->len = 0;
    self->cap = 0;
}

generic<K,V>
void OwnedMap_delete(struct OwnedMap<K,V>* self)
{
    int i;

    if (self == NULL) {
        return;
    }
    i = 0;
    while (i < self->cap) {
        if (self->states[i] == 1) {
            free(self->values[i]);
        }
        i++;
    }
    free(self->keys);
    free(self->values);
    free(self->states);
}
