void cminus_panic(const char* message, const char* file, int line);
int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
__SIZE_TYPE__ cminus_stack_enter_impl(const char* file, int line, void* anchor);
void cminus_stack_leave_impl(__SIZE_TYPE__ id, const char* file, int line);
void* cminus_gc_calloc_impl(__SIZE_TYPE__ count, __SIZE_TYPE__ size, const char* file, int line);
void cminus_gc_free_impl(void* mem, const char* file, int line);

#define __CMINUS_GC_MAGIC 0x434d4743UL
#define cminus_gc_calloc(count, size) cminus_gc_calloc_impl((count), (size), __FILE__, __LINE__)
#define cminus_gc_free(mem) cminus_gc_free_impl((mem), __FILE__, __LINE__)
#define __cminus_mod_ul(value, alignment) ((unsigned long)(value) % (unsigned long)(alignment))
#define align_up(value, alignment) cminus_align_up_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#define align_down(value, alignment) cminus_align_down_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#define is_aligned(value, alignment) cminus_is_aligned_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
struct Optional_FILE_ptr{
    int tag;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
    union {
        FILE* Some;
    } payload;
};
enum {
    Optional_FILE_ptr_TAG_Some,
    Optional_FILE_ptr_TAG_None
};
static __attribute__((unused)) struct Optional_FILE_ptr Optional_FILE_ptr_Some(FILE* value)
{
    struct Optional_FILE_ptr out = {0};
    out.tag = Optional_FILE_ptr_TAG_Some;
    out.origin_kind = cminus_ptr_classify((void*)value, &out.origin_stack_id);
    out.payload.Some = value;
    return out;
}
static __attribute__((unused)) int Optional_FILE_ptr_is_Some(struct Optional_FILE_ptr* self)
{
    return self->tag == Optional_FILE_ptr_TAG_Some;
}
static __attribute__((unused)) FILE* Optional_FILE_ptr_get_Some(struct Optional_FILE_ptr* self)
{
    cminus_ptr_require_alive((void*)self->payload.Some, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return self->payload.Some;
}
static __attribute__((unused)) struct Optional_FILE_ptr Optional_FILE_ptr_None(void)
{
    struct Optional_FILE_ptr out = {0};
    out.tag = Optional_FILE_ptr_TAG_None;
    out.origin_kind = 0UL;
    out.origin_stack_id = 0UL;
    return out;
}
static __attribute__((unused)) int Optional_FILE_ptr_is_None(struct Optional_FILE_ptr* self)
{
    return self->tag == Optional_FILE_ptr_TAG_None;
}
struct Span_int{
    int* data;
    int len;
    int* base;
    int cap;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};
struct Vec_int{
    int* data;
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
struct Span_int Span_from_int(int* data, int len){
    struct Span_int out;
    unsigned long stack_id = 0;

    out.data = data;
    out.len = len < 0 ? 0 : len;
    out.base = data;
    out.cap = out.len;
    out.origin_kind = cminus_ptr_classify(data, &stack_id);
    out.origin_stack_id = stack_id;
    return out;
}
struct Span_int Span_empty_int(void){
    struct Span_int out;

    out.data = NULL;
    out.len = 0;
    out.base = NULL;
    out.cap = 0;
    out.origin_kind = 0UL;
    out.origin_stack_id = 0;
    return out;
}
struct Vec_int* Vec_new_int(void){
    return cminus_gc_calloc(1, sizeof(struct Vec_int));
}
void Vec_push_int(struct Vec_int* self, int value){
    int* next;
    int next_cap = self->cap == 0 ? 4 : self->cap * 2;

    if (self->len >= self->cap) {
        next = cminus_gc_calloc(next_cap, sizeof(int));
        if (next == NULL) {
            abort();
        }
        if (self->data != NULL && self->len > 0) {
            memcpy(next, self->data, sizeof(int) * self->len);
            cminus_gc_free(self->data);
        }
        self->data = next;
        self->cap = next_cap;
    }
    self->data[self->len++] = value;
}
void Vec_delete_int(struct Vec_int* self){
    if (self != NULL) {
        cminus_gc_free(self->data);
    }
}
struct Span_int Vec_as_span_int(struct Vec_int* self){
    if (self == NULL) {
        return Span_empty_int();
    }
    return Span_from_int(self->data, self->len);
}
struct List_int* List_new_int(void){
    return cminus_gc_calloc(1, sizeof(struct List_int));
}
void List_push_int(struct List_int* self, int value){
    struct ListNode_int* node = cminus_gc_calloc(1, sizeof(struct ListNode_int));

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
void List_delete_int(struct List_int* self){
    struct ListNode_int* node;

    if (self == NULL) {
        return;
    }
    node = self->head;
    while (node != NULL) {
        struct ListNode_int* next = node->next;
        cminus_gc_free(node);
        node = next;
    }
}
struct Vec_int* List_to_vec_int(struct List_int* self){
    struct Vec_int* out;
    struct ListNode_int* node;

    out = Vec_new_int();
    if (self == NULL) {
        return out;
    }
    node = self->head;
    while (node != NULL) {
        Vec_push_int(out, node->value);
        node = node->next;
    }
    return out;
}
struct List_int* Vec_to_list_int(struct Vec_int* self){
    struct List_int* out;
    int i;

    out = List_new_int();
    if (self == NULL) {
        return out;
    }
    i = 0;
    while (i < self->len) {
        List_push_int(out, self->data[i]);
        i++;
    }
    return out;
}
struct Map_int_int* Map_new_int_int(void){
    return cminus_gc_calloc(1, sizeof(struct Map_int_int));
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
        int* next_keys = cminus_gc_calloc(next_cap, sizeof(int));
        int* next_values = cminus_gc_calloc(next_cap, sizeof(int));
        int* next_states = cminus_gc_calloc(next_cap, sizeof(int));

        if (next_keys == NULL || next_values == NULL || next_states == NULL) {
            cminus_gc_free(next_keys);
            cminus_gc_free(next_values);
            cminus_gc_free(next_states);
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
        cminus_gc_free(old_keys);
        cminus_gc_free(old_values);
        cminus_gc_free(old_states);
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
void Map_delete_int_int(struct Map_int_int* self){
    if (self != NULL) {
        cminus_gc_free(self->keys);
        cminus_gc_free(self->values);
        cminus_gc_free(self->states);
    }
}
struct Vec_int* Map_keys_to_vec_int_int(struct Map_int_int* self){
    struct Vec_int* out;
    int i;

    out = Vec_new_int();
    if (self == NULL) {
        return out;
    }
    i = 0;
    while (i < self->cap) {
        if (self->states[i] == 1) {
            Vec_push_int(out, self->keys[i]);
        }
        i++;
    }
    return out;
}
struct List_int* Map_values_to_list_int_int(struct Map_int_int* self){
    struct List_int* out;
    int i;

    out = List_new_int();
    if (self == NULL) {
        return out;
    }
    i = 0;
    while (i < self->cap) {
        if (self->states[i] == 1) {
            List_push_int(out, self->values[i]);
        }
        i++;
    }
    return out;
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
    unsigned long magic;
    size_t size;
    size_t capacity;
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
    copy->magic = self->magic;
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
#ifndef CMINUS_BARE_H
char* cminus_string_format(const char* fmt, ...);
#endif
static __attribute__((unused)) int cminus_string_len(const char* self);
static __attribute__((unused)) int cminus_string_is_empty(const char* self);
static __attribute__((unused)) int cminus_string_cmp(const char* self, const char* other);
static __attribute__((unused)) int cminus_string_eq(const char* self, const char* other);
static __attribute__((unused)) int cminus_string_contains(const char* self, const char* needle);
static __attribute__((unused)) int cminus_string_starts_with(const char* self, const char* prefix);
static __attribute__((unused)) int cminus_string_ends_with(const char* self, const char* suffix);
#ifndef CMINUS_BARE_H
static __attribute__((unused)) unsigned long cminus_align_up_impl(unsigned long value, unsigned long alignment, const char* file, int line);
static __attribute__((unused)) unsigned long cminus_align_down_impl(unsigned long value, unsigned long alignment, const char* file, int line);
static __attribute__((unused)) int cminus_is_aligned_impl(unsigned long value, unsigned long alignment, const char* file, int line);
#endif
#ifndef CMINUS_BARE_H
#endif

struct __CMinusGCHeader* __cminus_gc_live_head = NULL;
struct __CMinusGCHeader* __cminus_gc_dead_head = NULL;
struct __CMinusStackFrame* __cminus_stack_head = NULL;
size_t __cminus_stack_next_id = 1;
#ifdef CMINUS_BARE_H
struct __CMinusStackFrame __cminus_stack_frames[256];
int __cminus_stack_frame_used[256];
#endif

static __attribute__((unused)) void* __cminus_gc_payload(struct __CMinusGCHeader* header)
{
    return (char*)header + sizeof(struct __CMinusGCHeader);
}

static __attribute__((unused)) struct __CMinusGCHeader* __cminus_gc_header_from_payload(void* mem)
{
    if (mem == NULL) {
        return NULL;
    }
    return (struct __CMinusGCHeader*)((char*)mem - sizeof(struct __CMinusGCHeader));
}

static __attribute__((unused)) int __cminus_gc_header_is_valid(struct __CMinusGCHeader* header)
{
    return header != NULL && header->magic == __CMINUS_GC_MAGIC;
}

static __attribute__((unused)) struct __CMinusGCHeader* __cminus_gc_take_dead_fit(size_t size)
{
    struct __CMinusGCHeader* it = __cminus_gc_dead_head;
    struct __CMinusGCHeader* prev = NULL;

    while (it != NULL) {
        if (it->capacity >= size) {
            if (prev != NULL) {
                prev->dead_next = it->dead_next;
            } else {
                __cminus_gc_dead_head = it->dead_next;
            }
            it->dead_next = NULL;
            return it;
        }
        prev = it;
        it = it->dead_next;
    }
    return NULL;
}

static __attribute__((unused)) void __cminus_gc_unlink_live(struct __CMinusGCHeader* header)
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

#ifndef CMINUS_BARE_H
static __attribute__((unused)) unsigned long cminus_align_up_impl(unsigned long value, unsigned long alignment, const char* file, int line)
{
    unsigned long rem = {0};
    memset(&rem, 0, sizeof(rem));

    unsigned long add = {0};
    memset(&add, 0, sizeof(add));


    if (alignment == 0u) {
        cminus_panic("alignment is zero", file, line);
    }
    rem = __cminus_mod_ul(value, alignment);
    if (rem == 0u) {
        return value;
    }
    add = alignment - rem;
    if (value > ~0UL - add) {
        cminus_panic("alignment overflow", file, line);
    }
    return value + add;
}

static __attribute__((unused)) unsigned long cminus_align_down_impl(unsigned long value, unsigned long alignment, const char* file, int line)
{
    unsigned long rem = {0};
    memset(&rem, 0, sizeof(rem));


    if (alignment == 0u) {
        cminus_panic("alignment is zero", file, line);
    }
    rem = __cminus_mod_ul(value, alignment);
    return value - rem;
}

static __attribute__((unused)) int cminus_is_aligned_impl(unsigned long value, unsigned long alignment, const char* file, int line)
{
    unsigned long rem = {0};
    memset(&rem, 0, sizeof(rem));


    if (alignment == 0u) {
        cminus_panic("alignment is zero", file, line);
    }
    rem = __cminus_mod_ul(value, alignment);
    return rem == 0u;
}
#endif

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
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));


    if (mem == NULL) {
        return 0;
    }
    header = __cminus_gc_header_from_payload(mem);
    return __cminus_gc_header_is_valid(header) && header->alive;
}

int cminus_gc_is_managed(void* mem)
{
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));


    if (mem == NULL) {
        return 0;
    }
    header = __cminus_gc_header_from_payload(mem);
    return __cminus_gc_header_is_valid(header);
}

int cminus_gc_is_dead(void* mem)
{
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));


    if (mem == NULL) {
        return 0;
    }
    header = __cminus_gc_header_from_payload(mem);
    return __cminus_gc_header_is_valid(header) && !header->alive;
}

void* cminus_gc_calloc_impl(size_t count, size_t size, const char* file, int line)
{
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));

    size_t total = count * size;

    header = __cminus_gc_take_dead_fit(total);
    if (header != NULL) {
        memset(__cminus_gc_payload(header), 0, header->capacity);
    } else {
        header = calloc(1, sizeof(struct __CMinusGCHeader) + total);
        if (header == NULL) {
            fprintf(stderr, "c-: out of memory at %s:%d\n", file, line);
            abort();
        }
        header->capacity = total;
    }
    header->magic = __CMINUS_GC_MAGIC;
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
    return __cminus_gc_payload(header);
}

void cminus_gc_free_impl(void* mem, const char* file, int line)
{
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));


    if (mem == NULL) {
        return;
    }
    header = __cminus_gc_header_from_payload(mem);
    if (!__cminus_gc_header_is_valid(header)) {
        free(mem);
        return;
    }
    if (!header->alive) {
        (void)file;
        (void)line;
        return;
    }
    __cminus_gc_unlink_live(header);
    header->alive = 0;
    header->dead_next = __cminus_gc_dead_head;
    __cminus_gc_dead_head = header;
}

#ifndef CMINUS_BARE_H
char* cminus_string_format(const char* fmt, ...)
{
    __builtin_va_list ap;
    __builtin_va_list copy;
    int len = {0};
    memset(&len, 0, sizeof(len));

    char* out = {0};
    memset(&out, 0, sizeof(out));


    __builtin_va_start(ap, fmt);
    __builtin_va_copy(copy, ap);
    len = vsnprintf(NULL, 0, fmt, ap);
    __builtin_va_end(ap);
    if (len < 0) {
        __builtin_va_end(copy);
        cminus_panic("string format failed", __FILE__, __LINE__);
    }
    out = cminus_gc_calloc((size_t)len + 1, sizeof(char));
    vsnprintf(out, (size_t)len + 1, fmt, copy);
    __builtin_va_end(copy);
    return out;
}
#endif

size_t cminus_stack_enter_impl(const char* file, int line, void* anchor)
{
#ifdef CMINUS_BARE_H
    int slot = -1;
    int i = {0};
    memset(&i, 0, sizeof(i));

    struct __CMinusStackFrame* frame = {0};
    memset(&frame, 0, sizeof(frame));

#else
    struct __CMinusStackFrame* frame = calloc(1, sizeof(struct __CMinusStackFrame));
#endif
    size_t here = (size_t)anchor;
    size_t prev;

#ifdef CMINUS_BARE_H
    for (i = 0; i < 256; i++) {
        if (!__cminus_stack_frame_used[i]) {
            slot = i;
            break;
        }
    }
    if (slot < 0) {
        cminus_panic("out of stack frame slots", file, line);
    }
    __cminus_stack_frame_used[slot] = 1;
    frame = &__cminus_stack_frames[slot];
    memset(frame, 0, sizeof(*frame));
#else
    if (frame == NULL) {
        cminus_panic("out of memory", file, line);
    }
#endif
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
#ifdef CMINUS_BARE_H
    int i = {0};
    memset(&i, 0, sizeof(i));

#endif

    if (frame == NULL || frame->id != id) {
        cminus_panic("stack frame mismatch", file, line);
    }
    __cminus_stack_head = frame->prev;
#ifdef CMINUS_BARE_H
    for (i = 0; i < 256; i++) {
        if (frame == &__cminus_stack_frames[i]) {
            __cminus_stack_frame_used[i] = 0;
            break;
        }
    }
    frame->id = 0;
#else
    free(frame);
#endif
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
    struct __CMinusStackFrame* frame = {0};
    memset(&frame, 0, sizeof(frame));

    size_t ptr;

    if (stack_id_out != NULL) {
        *stack_id_out = 0;
    }
    if (mem == NULL) {
        return __CMinusPtrKind_Raw;
    }
    ptr = (size_t)mem;
    frame = __cminus_stack_head;
    if (frame != NULL && ptr >= frame->low && ptr <= frame->high) {
        if (stack_id_out != NULL) {
            *stack_id_out = frame->id;
        }
        return __CMinusPtrKind_Stack;
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

static __attribute__((unused)) struct Optional_FILE_ptr xfopen(const char* path, const char* mode)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    __auto_type fp = fopen(path, mode);

    if (fp == NULL) {
        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return Optional_FILE_ptr_None();
    }
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return Optional_FILE_ptr_Some(fp);
}

static __attribute__((unused)) int cminus_string_len(const char* self)
{
    if (self == NULL) {
        cminus_panic("string is null", __FILE__, __LINE__);
    }
    return (int)strlen(self);
}

static __attribute__((unused)) int cminus_string_is_empty(const char* self)
{
    return cminus_string_len(self) == 0;
}

static __attribute__((unused)) int cminus_string_cmp(const char* self, const char* other)
{
    if (self == NULL || other == NULL) {
        cminus_panic("string is null", __FILE__, __LINE__);
    }
    return strcmp(self, other);
}

static __attribute__((unused)) int cminus_string_eq(const char* self, const char* other)
{
    return cminus_string_cmp(self, other) == 0;
}

static __attribute__((unused)) int cminus_string_contains(const char* self, const char* needle)
{
    int self_len = {0};
    memset(&self_len, 0, sizeof(self_len));

    int needle_len = {0};
    memset(&needle_len, 0, sizeof(needle_len));

    int i = {0};
    memset(&i, 0, sizeof(i));

    int j = {0};
    memset(&j, 0, sizeof(j));


    if (self == NULL || needle == NULL) {
        cminus_panic("string is null", __FILE__, __LINE__);
    }
    self_len = (int)strlen(self);
    needle_len = (int)strlen(needle);
    if (needle_len == 0) {
        return 1;
    }
    if (needle_len > self_len) {
        return 0;
    }
    i = 0;
    while (i <= self_len - needle_len) {
        j = 0;
        while (j < needle_len && self[i + j] == needle[j]) {
            j++;
        }
        if (j == needle_len) {
            return 1;
        }
        i++;
    }
    return 0;
}

static __attribute__((unused)) int cminus_string_starts_with(const char* self, const char* prefix)
{
    int prefix_len = {0};
    memset(&prefix_len, 0, sizeof(prefix_len));

    int i = {0};
    memset(&i, 0, sizeof(i));


    if (self == NULL || prefix == NULL) {
        cminus_panic("string is null", __FILE__, __LINE__);
    }
    prefix_len = (int)strlen(prefix);
    i = 0;
    while (i < prefix_len) {
        if (self[i] == '\0' || self[i] != prefix[i]) {
            return 0;
        }
        i++;
    }
    return 1;
}

static __attribute__((unused)) int cminus_string_ends_with(const char* self, const char* suffix)
{
    int self_len = {0};
    memset(&self_len, 0, sizeof(self_len));

    int suffix_len = {0};
    memset(&suffix_len, 0, sizeof(suffix_len));


    if (self == NULL || suffix == NULL) {
        cminus_panic("string is null", __FILE__, __LINE__);
    }
    self_len = (int)strlen(self);
    suffix_len = (int)strlen(suffix);
    if (suffix_len > self_len) {
        return 0;
    }
    return strcmp(self + self_len - suffix_len, suffix) == 0;
}

struct Critical {
    unsigned long state;
    int active;
};

static __attribute__((unused)) struct Critical* Critical_clone(struct Critical* self)
{
    struct Critical* copy = cminus_gc_calloc(1, sizeof(struct Critical));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->state = self->state;
    copy->active = self->active;
    return copy;
}


static __attribute__((unused)) unsigned long cminus_irq_save(void)
{
    return 0UL;
}

static __attribute__((unused)) void cminus_irq_restore(unsigned long state)
{
    (void)state;
}

static __attribute__((unused)) struct Critical Critical_enter(void)
{
    struct Critical out = {0};
    memset(&out, 0, sizeof(out));


    out.state = cminus_irq_save();
    out.active = 1;
    return out;
}

static __attribute__((unused)) int Critical_is_active(struct Critical* self)
{
    return self != NULL && self->active;
}

static __attribute__((unused)) void Critical_leave(struct Critical* self)
{
    if (self == NULL || !self->active) {
        return;
    }
    self->active = 0;
    cminus_irq_restore(self->state);
}
int sum_span(struct Span_int values)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    int sum = 0;

    for (int __foreach0 = 0, __foreach_once0 = 0; __foreach0 < values.len; __foreach0++) for (__foreach_once0 = 1; __foreach_once0; __foreach_once0 = 0) for (int value = values.data[__foreach0]; __foreach_once0; __foreach_once0 = 0) {
        sum += value;
    }
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return sum;
}

int main(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Vec_int *vec = Vec_new_int();
    struct List_int *list = List_new_int();
    struct Map_int_int *map = Map_new_int_int();
    struct List_int *from_vec = {0};
    memset(&from_vec, 0, sizeof(from_vec));

    struct Vec_int *from_list = {0};
    memset(&from_list, 0, sizeof(from_list));

    struct Vec_int *roundtrip = {0};
    memset(&roundtrip, 0, sizeof(roundtrip));

    struct Vec_int *keys = {0};
    memset(&keys, 0, sizeof(keys));

    struct Vec_int *values_vec = {0};
    memset(&values_vec, 0, sizeof(values_vec));

    struct List_int *values = {0};
    memset(&values, 0, sizeof(values));

    struct Vec_int *values_roundtrip = {0};
    memset(&values_roundtrip, 0, sizeof(values_roundtrip));


    Vec_push_int(vec, 1);
    Vec_push_int(vec, 2);
    List_push_int(list, 3);
    List_push_int(list, 4);
    Map_set_int_int(map, 10, 100);
    Map_set_int_int(map, 20, 200);

    from_vec = Vec_to_list_int(vec);
    from_list = List_to_vec_int(list);
    roundtrip = List_to_vec_int(from_vec);
    keys = Map_keys_to_vec_int_int(map);
    values = Map_values_to_list_int_int(map);
    values_vec = List_to_vec_int(values);
    values_roundtrip = values_vec;

    if (sum_span(Vec_as_span_int(roundtrip)) != 3) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (vec != NULL) {
            Vec_delete_int(vec);
            cminus_gc_free(vec);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (sum_span(Vec_as_span_int(from_list)) != 7) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (vec != NULL) {
            Vec_delete_int(vec);
            cminus_gc_free(vec);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 2;
    }
    if (sum_span(Vec_as_span_int(keys)) != 30) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (vec != NULL) {
            Vec_delete_int(vec);
            cminus_gc_free(vec);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 3;
    }
    if (sum_span(Vec_as_span_int(values_roundtrip)) != 300) {
        if (map != NULL) {
            Map_delete_int_int(map);
            cminus_gc_free(map);
        }

        if (list != NULL) {
            List_delete_int(list);
            cminus_gc_free(list);
        }

        if (vec != NULL) {
            Vec_delete_int(vec);
            cminus_gc_free(vec);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 4;
    }

    printf("%d\n", sum_span(Vec_as_span_int(roundtrip)) +
                   sum_span(Vec_as_span_int(from_list)) +
                   sum_span(Vec_as_span_int(keys)) +
                   sum_span(Vec_as_span_int(values_roundtrip)));
    if (map != NULL) {
        Map_delete_int_int(map);
        cminus_gc_free(map);
    }

    if (list != NULL) {
        List_delete_int(list);
        cminus_gc_free(list);
    }

    if (vec != NULL) {
        Vec_delete_int(vec);
        cminus_gc_free(vec);
    }

    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return 0;
}