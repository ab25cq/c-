#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
struct __CMinusIndex_int{
    int tag;
    union {
        int Some;
    } payload;
};
enum {
    __CMinusIndex_int_TAG_Some,
    __CMinusIndex_int_TAG_None
};
static __attribute__((unused)) struct __CMinusIndex_int __CMinusIndex_int_Some(int value)
{
    struct __CMinusIndex_int out = {0};
    out.tag = __CMinusIndex_int_TAG_Some;
    out.payload.Some = value;
    return out;
}
static __attribute__((unused)) int __CMinusIndex_int_is_Some(struct __CMinusIndex_int* self)
{
    return self->tag == __CMinusIndex_int_TAG_Some;
}
static __attribute__((unused)) int __CMinusIndex_int_get_Some(struct __CMinusIndex_int* self)
{
    return self->payload.Some;
}
static __attribute__((unused)) struct __CMinusIndex_int __CMinusIndex_int_None(void)
{
    struct __CMinusIndex_int out = {0};
    out.tag = __CMinusIndex_int_TAG_None;
    return out;
}
static __attribute__((unused)) int __CMinusIndex_int_is_None(struct __CMinusIndex_int* self)
{
    return self->tag == __CMinusIndex_int_TAG_None;
}
struct __CMinusIndex_int_ptr{
    int tag;
    union {
        int* Some;
    } payload;
};
enum {
    __CMinusIndex_int_ptr_TAG_Some,
    __CMinusIndex_int_ptr_TAG_None
};
static __attribute__((unused)) struct __CMinusIndex_int_ptr __CMinusIndex_int_ptr_Some(int* value)
{
    struct __CMinusIndex_int_ptr out = {0};
    out.tag = __CMinusIndex_int_ptr_TAG_Some;
    out.payload.Some = value;
    return out;
}
static __attribute__((unused)) int __CMinusIndex_int_ptr_is_Some(struct __CMinusIndex_int_ptr* self)
{
    return self->tag == __CMinusIndex_int_ptr_TAG_Some;
}
static __attribute__((unused)) int* __CMinusIndex_int_ptr_get_Some(struct __CMinusIndex_int_ptr* self)
{
    return self->payload.Some;
}
static __attribute__((unused)) struct __CMinusIndex_int_ptr __CMinusIndex_int_ptr_None(void)
{
    struct __CMinusIndex_int_ptr out = {0};
    out.tag = __CMinusIndex_int_ptr_TAG_None;
    return out;
}
static __attribute__((unused)) int __CMinusIndex_int_ptr_is_None(struct __CMinusIndex_int_ptr* self)
{
    return self->tag == __CMinusIndex_int_ptr_TAG_None;
}
struct Vec_int{
    int* data;
    int len;
    int cap;
};
struct Vec_int_ptr{
    int** data;
    int len;
    int cap;
};
struct Vec_Item{
    struct Item* data;
    int len;
    int cap;
};
struct ListNode_int{
    int value;
    struct ListNode_int* next;
};
struct ListNode_int_ptr{
    int* value;
    struct ListNode_int_ptr* next;
};
struct List_int_ptr{
    struct ListNode_int_ptr* head;
    struct ListNode_int_ptr* tail;
    int len;
};
struct List_int{
    struct ListNode_int* head;
    struct ListNode_int* tail;
    int len;
};
struct Map_int_int_ptr{
    int* keys;
    int** values;
    int* states;
    int len;
    int cap;
};
struct Map_int_int{
    int* keys;
    int* values;
    int* states;
    int len;
    int cap;
};
struct OwnedVec_int_ptr{
    int** data;
    int len;
    int cap;
};
struct OwnedList_int_ptr{
    int** data;
    int len;
    int cap;
};
struct OwnedMap_int_int_ptr{
    int* keys;
    int** values;
    int* states;
    int len;
    int cap;
};
void Vec_push_int(struct Vec_int* self, int value){
    int* next;
    int next_cap = self->cap == 0 ? 4 : self->cap * 2;

    if (self->len >= self->cap) {
        next = realloc(self->data, sizeof(int) * next_cap);
        if (next == NULL) {
            abort();
        }
        self->data = next;
        self->cap = next_cap;
    }
    self->data[self->len++] = value;
}
int Vec_len_int(struct Vec_int* self){
    return self == NULL ? 0 : self->len;
}
int Vec_capacity_int(struct Vec_int* self){
    return self == NULL ? 0 : self->cap;
}
int Vec_is_empty_int(struct Vec_int* self){
    return self == NULL || self->len == 0;
}
void Vec_clear_int(struct Vec_int* self){
    if (self != NULL) {
        self->len = 0;
    }
}
int Vec_reserve_int(struct Vec_int* self, int cap){
    int* next;

    if (self == NULL) {
        return 0;
    }
    if (cap <= self->cap) {
        return 1;
    }
    next = realloc(self->data, sizeof(int) * cap);
    if (next == NULL) {
        return 0;
    }
    self->data = next;
    self->cap = cap;
    return 1;
}
struct __CMinusIndex_int Vec_pop_opt_int(struct Vec_int* self){
    if (self == NULL || self->len <= 0) {
        return __CMinusIndex_int_None();
    }
    self->len--;
    return __CMinusIndex_int_Some(self->data[self->len]);
}
void Vec_delete_int(struct Vec_int* self){
    if (self != NULL) {
        free(self->data);
    }
}
int Vec_first_int(struct Vec_int* self){
    return self->data[0];
}
int Vec_last_int(struct Vec_int* self){
    return self->data[self->len - 1];
}
int Vec_get_int(struct Vec_int* self, int index){
    return self->data[index];
}
int Vec_set_int(struct Vec_int* self, int index, int value){
    if (self == NULL || index < 0 || index >= self->len) {
        return 0;
    }
    self->data[index] = value;
    return 1;
}
struct __CMinusIndex_int Vec_get_opt_int(struct Vec_int* self, int index){
    if (self == NULL || index < 0 || index >= self->len) {
        return __CMinusIndex_int_None();
    }
    return __CMinusIndex_int_Some(self->data[index]);
}
struct List_int* List_new_int(void){
    return calloc(1, sizeof(struct List_int));
}
void List_push_int(struct List_int* self, int value){
    struct ListNode_int* node = calloc(1, sizeof(struct ListNode_int));

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
void List_push_front_int(struct List_int* self, int value){
    struct ListNode_int* node = calloc(1, sizeof(struct ListNode_int));

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
int List_len_int(struct List_int* self){
    return self == NULL ? 0 : self->len;
}
int List_is_empty_int(struct List_int* self){
    return self == NULL || self->len == 0;
}
void List_clear_int(struct List_int* self){
    struct ListNode_int* node;

    if (self == NULL) {
        return;
    }
    node = self->head;
    while (node != NULL) {
        struct ListNode_int* next = node->next;
        free(node);
        node = next;
    }
    self->head = NULL;
    self->tail = NULL;
    self->len = 0;
}
struct __CMinusIndex_int List_pop_front_opt_int(struct List_int* self){
    struct ListNode_int* node;
    int value;

    if (self == NULL || self->head == NULL) {
        return __CMinusIndex_int_None();
    }
    node = self->head;
    value = node->value;
    self->head = node->next;
    if (self->head == NULL) {
        self->tail = NULL;
    }
    self->len--;
    free(node);
    return __CMinusIndex_int_Some(value);
}
void List_delete_int(struct List_int* self){
    struct ListNode_int* node;

    if (self == NULL) {
        return;
    }
    node = self->head;
    while (node != NULL) {
        struct ListNode_int* next = node->next;
        free(node);
        node = next;
    }
}
int List_first_int(struct List_int* self){
    return self->head->value;
}
int List_last_int(struct List_int* self){
    return self->tail->value;
}
int List_get_int(struct List_int* self, int index){
    struct ListNode_int* node = self->head;
    int i = 0;

    while (i < index) {
        node = node->next;
        i++;
    }
    return node->value;
}
int List_set_int(struct List_int* self, int index, int value){
    struct ListNode_int* node;
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
struct __CMinusIndex_int List_get_opt_int(struct List_int* self, int index){
    struct ListNode_int* node;
    int i;

    if (self == NULL || index < 0 || index >= self->len) {
        return __CMinusIndex_int_None();
    }
    node = self->head;
    i = 0;
    while (i < index) {
        node = node->next;
        i++;
    }
    return __CMinusIndex_int_Some(node->value);
}
struct Map_int_int* Map_new_int_int(void){
    return calloc(1, sizeof(struct Map_int_int));
}
int Map_len_int_int(struct Map_int_int* self){
    return self == NULL ? 0 : self->len;
}
int Map_set_int_int(struct Map_int_int* self, int key, int value){
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL) {
        return 0;
    }
    if (self->cap == 0 || (self->len + 1) * 3 >= self->cap * 2) {
        int* old_keys = self->keys;
        int* old_values = self->values;
        int* old_states = self->states;
        int old_cap = self->cap;
        int next_cap = old_cap == 0 ? 16 : old_cap * 2;
        int* next_keys = calloc(next_cap, sizeof(int));
        int* next_values = calloc(next_cap, sizeof(int));
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
                while (j < (int)sizeof(int)) {
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
    while (i < (int)sizeof(int)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(int)) == 0) {
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
struct __CMinusIndex_int Map_get_opt_int_int(struct Map_int_int* self, int key){
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL || self->cap == 0) {
        return __CMinusIndex_int_None();
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(int)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(int)) == 0) {
            return __CMinusIndex_int_Some(self->values[slot]);
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return __CMinusIndex_int_None();
}
int Map_contains_int_int(struct Map_int_int* self, int key){
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
    while (i < (int)sizeof(int)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(int)) == 0) {
            return 1;
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return 0;
}
int Map_remove_int_int(struct Map_int_int* self, int key){
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
    while (i < (int)sizeof(int)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(int)) == 0) {
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
void Map_delete_int_int(struct Map_int_int* self){
    if (self != NULL) {
        free(self->keys);
        free(self->values);
        free(self->states);
    }
}
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
int OwnedVec_is_empty_int_ptr(struct OwnedVec_int_ptr* self){
    return self == NULL || self->len == 0;
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
int* OwnedVec_get_int_ptr(struct OwnedVec_int_ptr* self, int index){
    return self->data[index];
}
int OwnedVec_set_int_ptr(struct OwnedVec_int_ptr* self, int index, int* value){
    if (self == NULL || index < 0 || index >= self->len) {
        return 0;
    }
    free(self->data[index]);
    self->data[index] = value;
    return 1;
}
struct OwnedList_int_ptr* OwnedList_new_int_ptr(void){
    return calloc(1, sizeof(struct OwnedList_int_ptr));
}
void OwnedList_push_int_ptr(struct OwnedList_int_ptr* self, int* value){
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
void OwnedList_push_front_int_ptr(struct OwnedList_int_ptr* self, int* value){
    int** next;
    int next_cap = self->cap == 0 ? 4 : self->cap * 2;
    int i;

    if (self->len >= self->cap) {
        next = realloc(self->data, sizeof(int*) * next_cap);
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
int OwnedList_len_int_ptr(struct OwnedList_int_ptr* self){
    return self == NULL ? 0 : self->len;
}
int OwnedList_is_empty_int_ptr(struct OwnedList_int_ptr* self){
    return self == NULL || self->len == 0;
}
void OwnedList_clear_int_ptr(struct OwnedList_int_ptr* self){
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
void OwnedList_delete_int_ptr(struct OwnedList_int_ptr* self){
    if (self != NULL) {
        OwnedList_clear_int_ptr(self);
        free(self->data);
    }
}
int* OwnedList_get_int_ptr(struct OwnedList_int_ptr* self, int index){
    return self->data[index];
}
struct OwnedMap_int_int_ptr* OwnedMap_new_int_int_ptr(void){
    return calloc(1, sizeof(struct OwnedMap_int_int_ptr));
}
int OwnedMap_set_int_int_ptr(struct OwnedMap_int_int_ptr* self, int key, int* value){
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL) {
        return 0;
    }
    if (self->cap == 0 || (self->len + 1) * 3 >= self->cap * 2) {
        int* old_keys = self->keys;
        int** old_values = self->values;
        int* old_states = self->states;
        int old_cap = self->cap;
        int next_cap = old_cap == 0 ? 16 : old_cap * 2;
        int* next_keys = calloc(next_cap, sizeof(int));
        int** next_values = calloc(next_cap, sizeof(int*));
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
                while (j < (int)sizeof(int)) {
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
    while (i < (int)sizeof(int)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(int)) == 0) {
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
struct __CMinusIndex_int_ptr OwnedMap_get_opt_int_int_ptr(struct OwnedMap_int_int_ptr* self, int key){
    unsigned char* bytes;
    unsigned long hash;
    int i;
    int slot;

    if (self == NULL || self->cap == 0) {
        return __CMinusIndex_int_ptr_None();
    }
    bytes = (unsigned char*)&key;
    hash = 1469598103934665603UL;
    i = 0;
    while (i < (int)sizeof(int)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(int)) == 0) {
            return __CMinusIndex_int_ptr_Some(self->values[slot]);
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return __CMinusIndex_int_ptr_None();
}
int OwnedMap_contains_int_int_ptr(struct OwnedMap_int_int_ptr* self, int key){
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
    while (i < (int)sizeof(int)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(int)) == 0) {
            return 1;
        }
        slot = slot + 1;
        if (slot >= self->cap) {
            slot = 0;
        }
    }
    return 0;
}
int OwnedMap_remove_int_int_ptr(struct OwnedMap_int_int_ptr* self, int key){
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
    while (i < (int)sizeof(int)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(int)) == 0) {
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
void OwnedMap_delete_int_int_ptr(struct OwnedMap_int_int_ptr* self){
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

struct Item {
    int value;
};

static __attribute__((unused)) struct Item* Item_clone(struct Item* self)
{
    struct Item* copy = calloc(1, sizeof(struct Item));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->value = self->value;
    return copy;
}


int main(void)
{
    int values[3] = {0};
    memset(&values, 0, sizeof(values));

    struct Item items[2] = {0};
    memset(&items, 0, sizeof(items));

    int sum = 0;
    int item_sum = 0;
    int list_sum = 0;
    struct Vec_int nums = {0};
    memset(&nums, 0, sizeof(nums));

    struct Vec_int dyn = {0};
    memset(&dyn, 0, sizeof(dyn));

    struct Vec_int_ptr ptr_vec_force = {0};
    memset(&ptr_vec_force, 0, sizeof(ptr_vec_force));

    struct Vec_int* nums_ptr = {0};
    memset(&nums_ptr, 0, sizeof(nums_ptr));

    struct Vec_Item item_vec = {0};
    memset(&item_vec, 0, sizeof(item_vec));

    struct List_int_ptr* ptr_list_force = {0};
    memset(&ptr_list_force, 0, sizeof(ptr_list_force));

    struct Map_int_int_ptr* ptr_map_force = {0};
    memset(&ptr_map_force, 0, sizeof(ptr_map_force));

    struct List_int* list = List_new_int();
    struct Map_int_int* map = Map_new_int_int();
    struct OwnedVec_int_ptr* owned_vec = OwnedVec_new_int_ptr();
    struct OwnedList_int_ptr* owned_list = OwnedList_new_int_ptr();
    struct OwnedMap_int_int_ptr* owned_map = OwnedMap_new_int_int_ptr();

    values[0] = 1;
    values[1] = 2;
    values[2] = 3;
    items[0].value = 4;
    items[1].value = 5;
    nums.data = values;
    nums.len = 3;
    ptr_vec_force.len = 0;
    ptr_list_force = NULL;
    ptr_map_force = NULL;
    nums_ptr = &nums;
    item_vec.data = items;
    item_vec.len = 2;
    for (int __foreach0 = 0, __foreach_once0 = 0; __foreach0 < nums.len; __foreach0++) for (__foreach_once0 = 1; __foreach_once0; __foreach_once0 = 0) for (int value = nums.data[__foreach0]; __foreach_once0; __foreach_once0 = 0) {
        sum += value;
    }
    for (int __foreach1 = 0, __foreach_once1 = 0; __foreach1 < item_vec.len; __foreach1++) for (__foreach_once1 = 1; __foreach_once1; __foreach_once1 = 0) for (struct Item item = item_vec.data[__foreach1]; __foreach_once1; __foreach_once1 = 0) {
        item_sum += item.value;
    }
    List_push_int(list, 6);
    List_push_int(list, 7);
    for (struct ListNode_int* __foreach_node2 = list->head; __foreach_node2 != NULL; __foreach_node2 = __foreach_node2->next) for (int __foreach_once2 = 1; __foreach_once2; __foreach_once2 = 0) for (int value = __foreach_node2->value; __foreach_once2; __foreach_once2 = 0) {
        list_sum += value;
    }
    if (Vec_first_int(&nums) != 1) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (({ struct __CMinusIndex_int __index_result0 = Vec_get_opt_int(&nums, 1); if (__index_result0.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/generics_foreach.c-", 57); } __index_result0.payload.Some; }) != 2) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (Vec_first_int(nums_ptr) != 1) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (Vec_len_int(&nums) != 3 || Vec_is_empty_int(&nums)) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    Vec_reserve_int(&dyn, 2);
    Vec_push_int(&dyn, 8);
    Vec_push_int(&dyn, 9);
    if (Vec_len_int(&dyn) != 2 || Vec_capacity_int(&dyn) < 2 || Vec_last_int(&dyn) != 9) {
        Vec_delete_int(&dyn);
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (!Vec_set_int(&dyn, 0, 10) || Vec_get_int(&dyn, 0) != 10) {
        Vec_delete_int(&dyn);
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    struct __CMinusIndex_int popped_vec = Vec_pop_opt_int(&dyn);
    if (!__CMinusIndex_int_is_Some(&popped_vec) || __CMinusIndex_int_get_Some(&popped_vec) != 9 || Vec_len_int(&dyn) != 1) {
        Vec_delete_int(&dyn);
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    Vec_clear_int(&dyn);
    if (!Vec_is_empty_int(&dyn)) {
        Vec_delete_int(&dyn);
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    Vec_delete_int(&dyn);
    if (List_first_int(list) != 6) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (({ struct __CMinusIndex_int __index_result1 = List_get_opt_int(list, 1); if (__index_result1.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/generics_foreach.c-", 91); } __index_result1.payload.Some; }) != 7) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    Map_set_int_int(map, 100, 200);
    Map_set_int_int(map, 101, 201);
    struct __CMinusIndex_int map_value = Map_get_opt_int_int(map, 100);
    if (!__CMinusIndex_int_is_Some(&map_value) || __CMinusIndex_int_get_Some(&map_value) != 200 || !Map_contains_int_int(map, 101)) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    Map_remove_int_int(map, 100);
    if (Map_contains_int_int(map, 100) || Map_len_int_int(map) != 1) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    int* owned_a = calloc(1, sizeof(int));
    int* owned_b = calloc(1, sizeof(int));
    int* owned_c = calloc(1, sizeof(int));
    int* owned_d = calloc(1, sizeof(int));
    int* owned_e = calloc(1, sizeof(int));
    int* owned_f = calloc(1, sizeof(int));

    *owned_a = 1;
    *owned_b = 2;
    *owned_c = 3;
    *owned_d = 4;
    *owned_e = 5;
    *owned_f = 6;
    OwnedVec_push_int_ptr(owned_vec, owned_a);
    if (OwnedVec_len_int_ptr(owned_vec) != 1 || *OwnedVec_get_int_ptr(owned_vec, 0) != 1) {
        if (owned_f != NULL) {
            free(owned_f);
        }

        if (owned_e != NULL) {
            free(owned_e);
        }

        if (owned_d != NULL) {
            free(owned_d);
        }

        if (owned_c != NULL) {
            free(owned_c);
        }

        if (owned_b != NULL) {
            free(owned_b);
        }

        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    OwnedVec_set_int_ptr(owned_vec, 0, owned_b);
    if (*OwnedVec_get_int_ptr(owned_vec, 0) != 2) {
        if (owned_f != NULL) {
            free(owned_f);
        }

        if (owned_e != NULL) {
            free(owned_e);
        }

        if (owned_d != NULL) {
            free(owned_d);
        }

        if (owned_c != NULL) {
            free(owned_c);
        }

        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    OwnedVec_clear_int_ptr(owned_vec);
    if (!OwnedVec_is_empty_int_ptr(owned_vec)) {
        if (owned_f != NULL) {
            free(owned_f);
        }

        if (owned_e != NULL) {
            free(owned_e);
        }

        if (owned_d != NULL) {
            free(owned_d);
        }

        if (owned_c != NULL) {
            free(owned_c);
        }

        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    OwnedList_push_int_ptr(owned_list, owned_c);
    OwnedList_push_front_int_ptr(owned_list, owned_d);
    if (OwnedList_len_int_ptr(owned_list) != 2 || *OwnedList_get_int_ptr(owned_list, 0) != 4) {
        if (owned_f != NULL) {
            free(owned_f);
        }

        if (owned_e != NULL) {
            free(owned_e);
        }

        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    OwnedList_clear_int_ptr(owned_list);
    if (!OwnedList_is_empty_int_ptr(owned_list)) {
        if (owned_f != NULL) {
            free(owned_f);
        }

        if (owned_e != NULL) {
            free(owned_e);
        }

        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    OwnedMap_set_int_int_ptr(owned_map, 1, owned_e);
    OwnedMap_set_int_int_ptr(owned_map, 1, owned_f);
    struct __CMinusIndex_int_ptr owned_map_value = OwnedMap_get_opt_int_int_ptr(owned_map, 1);
    if (!__CMinusIndex_int_ptr_is_Some(&owned_map_value) || *__CMinusIndex_int_ptr_get_Some(&owned_map_value) != 6) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    OwnedMap_remove_int_int_ptr(owned_map, 1);
    if (OwnedMap_contains_int_int_ptr(owned_map, 1)) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    List_push_front_int(list, 5);
    if (List_len_int(list) != 3 || List_first_int(list) != 5 || List_last_int(list) != 7) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (!List_set_int(list, 1, 66) || List_get_int(list, 1) != 66) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    struct __CMinusIndex_int front = List_pop_front_opt_int(list);
    if (!__CMinusIndex_int_is_Some(&front) || __CMinusIndex_int_get_Some(&front) != 5 || List_len_int(list) != 2) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    List_clear_int(list);
    if (!List_is_empty_int(list)) {
        if (owned_map != NULL) {
            OwnedMap_delete_int_int_ptr(owned_map);
            free(owned_map);
        }

        if (owned_list != NULL) {
            OwnedList_delete_int_ptr(owned_list);
            free(owned_list);
        }

        if (owned_vec != NULL) {
            OwnedVec_delete_int_ptr(owned_vec);
            free(owned_vec);
        }

        if (map != NULL) {
            Map_delete_int_int(map);
            free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (owned_map != NULL) {
        OwnedMap_delete_int_int_ptr(owned_map);
        free(owned_map);
    }

    if (owned_list != NULL) {
        OwnedList_delete_int_ptr(owned_list);
        free(owned_list);
    }

    if (owned_vec != NULL) {
        OwnedVec_delete_int_ptr(owned_vec);
        free(owned_vec);
    }

    if (map != NULL) {
        Map_delete_int_int(map);
        free(map);
    }

    if (list != NULL) {
        List_delete_int(list);
        free(list);
    }

    return sum == 6 && item_sum == 9 && list_sum == 13 ? 0 : 1;
}