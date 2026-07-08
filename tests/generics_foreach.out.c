void cminus_panic(const char* message, const char* file, int line);
int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
void* cminus_gc_calloc_impl(unsigned long count, unsigned long size, const char* file, int line);

#define cminus_gc_calloc(count, size) cminus_gc_calloc_impl((count), (size), __FILE__, __LINE__)
#define cminus_gc_free(mem) cminus_gc_free_impl((mem), __FILE__, __LINE__)
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
struct __CMinusIndex_int{
    int tag;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
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
    out.origin_kind = 0UL;
    out.origin_stack_id = 0UL;
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
    out.origin_kind = 0UL;
    out.origin_stack_id = 0UL;
    return out;
}
static __attribute__((unused)) int __CMinusIndex_int_is_None(struct __CMinusIndex_int* self)
{
    return self->tag == __CMinusIndex_int_TAG_None;
}
struct Vec_int{
    int* data;
    int len;
    int cap;
};
struct Vec_Item_ptr{
    struct Item** data;
    int len;
    int cap;
};
struct ListNode_int{
    int value;
    struct ListNode_int* next;
};
struct List_int{
    struct ListNode_int* head;
    struct ListNode_int* tail;
    int len;
};
struct Map_int_int{
    int* keys;
    int* values;
    int* states;
    int len;
    int cap;
};
struct Vec_int* Vec_new_int(void){
    return calloc(1, sizeof(struct Vec_int));
}
struct Vec_Item_ptr* Vec_new_Item_ptr(void){
    return calloc(1, sizeof(struct Vec_Item_ptr));
}
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
void Vec_push_Item_ptr(struct Vec_Item_ptr* self, struct Item* value){
    struct Item** next;
    int next_cap = self->cap == 0 ? 4 : self->cap * 2;

    if (self->len >= self->cap) {
        next = realloc(self->data, sizeof(struct Item*) * next_cap);
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
void Vec_delete_Item_ptr(struct Vec_Item_ptr* self){
    if (self != NULL) {
        free(self->data);
    }
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

struct __CMinusGCHeader {
    size_t size;
    const char* file;
    int line;
    int alive;
    struct __CMinusGCHeader* next;
    struct __CMinusGCHeader* prev;
    struct __CMinusGCHeader* dead_next;
};

static __attribute__((unused)) struct __CMinusGCHeader* __CMinusGCHeader_clone(struct __CMinusGCHeader* self)
{
    struct __CMinusGCHeader* copy = calloc(1, sizeof(struct __CMinusGCHeader));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->file = self->file;
    copy->line = self->line;
    copy->alive = self->alive;
    copy->next = self->next;
    copy->prev = self->prev;
    copy->dead_next = self->dead_next;
    return copy;
}


enum __CMinusPtrKind {
    __CMinusPtrKind_Raw = 0,
    __CMinusPtrKind_Managed = 1,
    __CMinusPtrKind_Stack = 2,
};

struct __CMinusStackFrame {
    size_t id;
    size_t anchor;
    size_t parent_anchor;
    size_t low;
    size_t high;
    struct __CMinusStackFrame* prev;
};

static __attribute__((unused)) struct __CMinusStackFrame* __CMinusStackFrame_clone(struct __CMinusStackFrame* self)
{
    struct __CMinusStackFrame* copy = calloc(1, sizeof(struct __CMinusStackFrame));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->prev = self->prev;
    return copy;
}


void cminus_gc_step(void);
void cminus_gc_collect(void);
int cminus_gc_is_alive(void* mem);
int cminus_gc_is_managed(void* mem);
int cminus_gc_is_dead(void* mem);
void cminus_gc_report_leaks(void);
size_t cminus_stack_enter_impl(const char* file, int line, void* anchor);
void cminus_stack_leave_impl(size_t id, const char* file, int line);
int cminus_stack_is_alive(size_t id);
int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
void* cminus_gc_calloc_impl(size_t count, size_t size, const char* file, int line);
void cminus_gc_free_impl(void* mem, const char* file, int line);
struct __CMinusGCHeader* __cminus_gc_live_head = NULL;
struct __CMinusGCHeader* __cminus_gc_dead_head = NULL;
size_t __cminus_gc_step_budget = 1;
size_t __cminus_gc_live_count = 0;
struct __CMinusStackFrame* __cminus_stack_head = NULL;
size_t __cminus_stack_next_id = 1;

static void* __cminus_gc_payload(struct __CMinusGCHeader* header)
{
    return (char*)header + sizeof(struct __CMinusGCHeader);
}

static  struct __CMinusGCHeader* __cminus_gc_find_live(void* mem)
{
    struct __CMinusGCHeader* it = __cminus_gc_live_head;

    while (it != NULL) {
        if (__cminus_gc_payload(it) == mem) {
            return it;
        }
        it = it->next;
    }
    return NULL;
}

static  struct __CMinusGCHeader* __cminus_gc_find_dead(void* mem)
{
    struct __CMinusGCHeader* it = __cminus_gc_dead_head;

    while (it != NULL) {
        if (__cminus_gc_payload(it) == mem) {
            return it;
        }
        it = it->dead_next;
    }
    return NULL;
}

static  void __cminus_gc_unlink_live(struct __CMinusGCHeader* header)
{
    if (header->prev != NULL) {
        header->prev->next = header->next;
    } else {
        __cminus_gc_live_head = header->next;
    }
    if (header->next != NULL) {
        header->next->prev = header->prev;
    }
    header->next = NULL;
    header->prev = NULL;
}

static  int __cminus_gc_contains(struct __CMinusGCHeader* header, void* mem)
{
    size_t start = (size_t)__cminus_gc_payload(header);
    size_t end = start + header->size;
    size_t ptr = (size_t)mem;

    return ptr >= start && ptr < end;
}

void cminus_gc_step(void)
{
    size_t budget = __cminus_gc_step_budget;

    while (budget > 0 && __cminus_gc_dead_head != NULL) {
        struct __CMinusGCHeader* header = __cminus_gc_dead_head;

        __cminus_gc_dead_head = header->dead_next;
        header->dead_next = NULL;
        free(header);
        budget--;
    }
}

void cminus_gc_collect(void)
{
    while (__cminus_gc_dead_head != NULL) {
        cminus_gc_step();
    }
}

void cminus_gc_report_leaks(void)
{
    struct __CMinusGCHeader* it = __cminus_gc_live_head;
    size_t leaks = 0;

    while (it != NULL) {
        leaks++;
        fprintf(stderr, "managed leak #%zu: %zu bytes at %s:%d\n",
                leaks, it->size, it->file, it->line);
        it = it->next;
    }
    if (leaks > 0) {
        fprintf(stderr, "c-: %zu managed heap leaks\n", leaks);
    }
}

int cminus_gc_is_alive(void* mem)
{
    struct __CMinusGCHeader* it = {0};
    memset(&it, 0, sizeof(it));


    if (mem == NULL) {
        return 0;
    }
    if (__cminus_gc_find_live(mem) != NULL) {
        return 1;
    }
    for (it = __cminus_gc_live_head; it != NULL; it = it->next) {
        if (__cminus_gc_contains(it, mem)) {
            return it->alive != 0;
        }
    }
    for (it = __cminus_gc_dead_head; it != NULL; it = it->dead_next) {
        if (__cminus_gc_contains(it, mem)) {
            return 0;
        }
    }
    return 0;
}

int cminus_gc_is_managed(void* mem)
{
    struct __CMinusGCHeader* it = {0};
    memset(&it, 0, sizeof(it));


    if (mem == NULL) {
        return 0;
    }
    if (__cminus_gc_find_live(mem) != NULL || __cminus_gc_find_dead(mem) != NULL) {
        return 1;
    }
    for (it = __cminus_gc_live_head; it != NULL; it = it->next) {
        if (__cminus_gc_contains(it, mem)) {
            return 1;
        }
    }
    for (it = __cminus_gc_dead_head; it != NULL; it = it->dead_next) {
        if (__cminus_gc_contains(it, mem)) {
            return 1;
        }
    }
    return 0;
}

int cminus_gc_is_dead(void* mem)
{
    struct __CMinusGCHeader* it = {0};
    memset(&it, 0, sizeof(it));


    if (mem == NULL) {
        return 0;
    }
    if (__cminus_gc_find_dead(mem) != NULL) {
        return 1;
    }
    for (it = __cminus_gc_dead_head; it != NULL; it = it->dead_next) {
        if (__cminus_gc_contains(it, mem)) {
            return 1;
        }
    }
    return 0;
}

void* cminus_gc_calloc_impl(size_t count, size_t size, const char* file, int line)
{
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));

    size_t total = count * size;

    header = calloc(1, sizeof(struct __CMinusGCHeader) + total);
    if (header == NULL) {
        fprintf(stderr, "c-: out of memory at %s:%d\n", file, line);
        abort();
    }
    header->size = total;
    header->file = file;
    header->line = line;
    header->alive = 1;
    header->next = __cminus_gc_live_head;
    header->prev = NULL;
    header->dead_next = NULL;
    if (__cminus_gc_live_head != NULL) {
        __cminus_gc_live_head->prev = header;
    }
    __cminus_gc_live_head = header;
    __cminus_gc_live_count++;
    cminus_gc_step();
    return __cminus_gc_payload(header);
}

void cminus_gc_free_impl(void* mem, const char* file, int line)
{
    struct __CMinusGCHeader* live = {0};
    memset(&live, 0, sizeof(live));

    struct __CMinusGCHeader* dead = {0};
    memset(&dead, 0, sizeof(dead));


    if (mem == NULL) {
        return;
    }
    live = __cminus_gc_find_live(mem);
    if (live != NULL) {
        __cminus_gc_unlink_live(live);
        live->alive = 0;
        live->dead_next = __cminus_gc_dead_head;
        __cminus_gc_dead_head = live;
        if (__cminus_gc_live_count > 0) {
            __cminus_gc_live_count--;
        }
        cminus_gc_step();
        return;
    }
    dead = __cminus_gc_find_dead(mem);
    if (dead != NULL) {
        fprintf(stderr, "c-: double free of managed heap object at %s:%d\n", file, line);
        abort();
    }
    free(mem);
}

size_t cminus_stack_enter_impl(const char* file, int line, void* anchor)
{
    struct __CMinusStackFrame* frame = calloc(1, sizeof(struct __CMinusStackFrame));
    size_t here = (size_t)anchor;
    size_t prev;

    if (frame == NULL) {
        cminus_panic("out of memory", file, line);
    }
    prev = __cminus_stack_head == NULL ? here : __cminus_stack_head->anchor;
    frame->id = __cminus_stack_next_id++;
    frame->anchor = here;
    frame->parent_anchor = prev;
    frame->low = prev < here ? prev : here;
    frame->high = prev > here ? prev : here;
    frame->prev = __cminus_stack_head;
    __cminus_stack_head = frame;
    return frame->id;
}

void cminus_stack_leave_impl(size_t id, const char* file, int line)
{
    struct __CMinusStackFrame* frame = __cminus_stack_head;

    if (frame == NULL || frame->id != id) {
        cminus_panic("stack frame mismatch", file, line);
    }
    __cminus_stack_head = frame->prev;
    free(frame);
}

int cminus_stack_is_alive(size_t id)
{
    struct __CMinusStackFrame* frame = __cminus_stack_head;

    while (frame != NULL) {
        if (frame->id == id) {
            return 1;
        }
        frame = frame->prev;
    }
    return 0;
}

int cminus_ptr_classify(void* mem, unsigned long* stack_id_out)
{
    struct __CMinusGCHeader* it = {0};
    memset(&it, 0, sizeof(it));

    struct __CMinusStackFrame* frame = {0};
    memset(&frame, 0, sizeof(frame));

    size_t ptr;

    if (stack_id_out != NULL) {
        *stack_id_out = 0;
    }
    if (mem == NULL) {
        return __CMinusPtrKind_Raw;
    }
    if (cminus_gc_is_managed(mem)) {
        return __CMinusPtrKind_Managed;
    }
    ptr = (size_t)mem;
    frame = __cminus_stack_head;
    if (frame != NULL && ptr >= frame->low && ptr <= frame->high) {
        if (stack_id_out != NULL) {
            *stack_id_out = frame->id;
        }
        return __CMinusPtrKind_Stack;
    }
    for (it = __cminus_gc_live_head; it != NULL; it = it->next) {
        if (__cminus_gc_contains(it, mem)) {
            return __CMinusPtrKind_Managed;
        }
    }
    for (it = __cminus_gc_dead_head; it != NULL; it = it->dead_next) {
        if (__cminus_gc_contains(it, mem)) {
            return __CMinusPtrKind_Managed;
        }
    }
    return __CMinusPtrKind_Raw;
}

void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line)
{
    if (kind == __CMinusPtrKind_Raw) {
        return;
    }
    if (mem == NULL) {
        cminus_panic("dangling reference", file, line);
    }
    if (kind == __CMinusPtrKind_Managed) {
        if (!cminus_gc_is_alive(mem)) {
            cminus_panic("dangling managed heap reference", file, line);
        }
    } else if (kind == __CMinusPtrKind_Stack) {
        if (!cminus_stack_is_alive(stack_id)) {
            cminus_panic("dangling stack reference", file, line);
        }
    }
}

struct Item {
    int value;
};

static __attribute__((unused)) struct Item* Item_clone(struct Item* self)
{
    struct Item* copy = cminus_gc_calloc(1, sizeof(struct Item));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->value = self->value;
    return copy;
}


int main(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    int sum = 0;
    int item_sum = 0;
    int list_sum = 0;
    struct Vec_int *nums = Vec_new_int();
    struct Vec_int *dyn = Vec_new_int();
    struct Vec_Item_ptr *item_vec = Vec_new_Item_ptr();
    struct List_int *list = List_new_int();
    struct Map_int_int *map = Map_new_int_int();

    Vec_push_int(nums, 1);
    Vec_push_int(nums, 2);
    Vec_push_int(nums, 3);
    Vec_push_Item_ptr(item_vec, ({ struct Item* __right_value0 = cminus_gc_calloc(1, sizeof(struct Item)); if (__right_value0 != NULL) { __right_value0->value = 4; } __right_value0; }));
    Vec_push_Item_ptr(item_vec, ({ struct Item* __right_value1 = cminus_gc_calloc(1, sizeof(struct Item)); if (__right_value1 != NULL) { __right_value1->value = 5; } __right_value1; }));
    for (int __foreach0 = 0, __foreach_once0 = 0; __foreach0 < nums->len; __foreach0++) for (__foreach_once0 = 1; __foreach_once0; __foreach_once0 = 0) for (int value = nums->data[__foreach0]; __foreach_once0; __foreach_once0 = 0) {
        sum += value;
    }
    for (int __foreach1 = 0, __foreach_once1 = 0; __foreach1 < item_vec->len; __foreach1++) for (__foreach_once1 = 1; __foreach_once1; __foreach_once1 = 0) for (struct Item* item = item_vec->data[__foreach1]; __foreach_once1; __foreach_once1 = 0) {
        item_sum += item->value;
    }
    List_push_int(list, 6);
    List_push_int(list, 7);
    for (struct ListNode_int* __foreach_node2 = list->head; __foreach_node2 != NULL; __foreach_node2 = __foreach_node2->next) for (int __foreach_once2 = 1; __foreach_once2; __foreach_once2 = 0) for (int value = __foreach_node2->value; __foreach_once2; __foreach_once2 = 0) {
        list_sum += value;
    }
    if (Vec_first_int(nums) != 1) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (({ struct __CMinusIndex_int __index_result0 = Vec_get_opt_int(nums, 1); if (__index_result0.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/generics_foreach.c-", 41); } __index_result0.payload.Some; }) != 2) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (Vec_len_int(nums) != 3 || Vec_is_empty_int(nums)) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    Vec_reserve_int(dyn, 2);
    Vec_push_int(dyn, 8);
    Vec_push_int(dyn, 9);
    if (Vec_len_int(dyn) != 2 || Vec_capacity_int(dyn) < 2 || Vec_last_int(dyn) != 9) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (!Vec_set_int(dyn, 0, 10) || Vec_get_int(dyn, 0) != 10) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    struct __CMinusIndex_int popped_vec = Vec_pop_opt_int(dyn);
    if (!__CMinusIndex_int_is_Some(&popped_vec) || __CMinusIndex_int_get_Some(&popped_vec) != 9 || Vec_len_int(dyn) != 1) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    Vec_clear_int(dyn);
    if (!Vec_is_empty_int(dyn)) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (List_first_int(list) != 6) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (({ struct __CMinusIndex_int __index_result1 = List_get_opt_int(list, 1); if (__index_result1.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/generics_foreach.c-", 67); } __index_result1.payload.Some; }) != 7) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    Map_set_int_int(map, 100, 200);
    Map_set_int_int(map, 101, 201);
    struct __CMinusIndex_int map_value = Map_get_opt_int_int(map, 100);
    if (!__CMinusIndex_int_is_Some(&map_value) || __CMinusIndex_int_get_Some(&map_value) != 200 || !Map_contains_int_int(map, 101)) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    Map_remove_int_int(map, 100);
    if (Map_contains_int_int(map, 100) || Map_len_int_int(map) != 1) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    List_push_front_int(list, 5);
    if (List_len_int(list) != 3 || List_first_int(list) != 5 || List_last_int(list) != 7) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (!List_set_int(list, 1, 66) || List_get_int(list, 1) != 66) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    struct __CMinusIndex_int front = List_pop_front_opt_int(list);
    if (!__CMinusIndex_int_is_Some(&front) || __CMinusIndex_int_get_Some(&front) != 5 || List_len_int(list) != 2) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    List_clear_int(list);
    if (!List_is_empty_int(list)) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (item_vec != NULL) {
            Vec_delete_Item_ptr(item_vec);
            cminus_gc_free(item_vec);
        }

        if (dyn != NULL) {
            Vec_delete_int(dyn);
            cminus_gc_free(dyn);
        }

        if (nums != NULL) {
            Vec_delete_int(nums);
            cminus_gc_free(nums);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (map != NULL) {
        Map_delete_int_int(map);
        cminus_gc_free(map);
    }

    if (list != NULL) {
        List_delete_int(list);
        cminus_gc_free(list);
    }

    if (item_vec != NULL) {
        Vec_delete_Item_ptr(item_vec);
        cminus_gc_free(item_vec);
    }

    if (dyn != NULL) {
        Vec_delete_int(dyn);
        cminus_gc_free(dyn);
    }

    if (nums != NULL) {
        Vec_delete_int(nums);
        cminus_gc_free(nums);
    }

    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return sum == 6 && item_sum == 9 && list_sum == 13 ? 0 : 1;
}