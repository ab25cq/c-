#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <execinfo.h>

#define __CMINUS_GC_MAGIC 0x434d494e55534743UL

uniq void cminus_panic(const char* message, const char* file, int line)
{
    void* frames[64];
    int count;

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

uniq void cminus_gc_step(void);
uniq void cminus_gc_collect(void);
uniq int cminus_gc_is_alive(void* mem);
uniq int cminus_gc_is_managed(void* mem);
uniq int cminus_gc_is_dead(void* mem);
uniq void cminus_gc_report_leaks(void);
uniq size_t cminus_stack_enter_impl(const char* file, int line, void* anchor);
uniq void cminus_stack_leave_impl(size_t id, const char* file, int line);
uniq int cminus_stack_is_alive(size_t id);
uniq int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
uniq void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
uniq void* cminus_gc_calloc_impl(size_t count, size_t size, const char* file, int line);
uniq void cminus_gc_free_impl(void* mem, const char* file, int line);
#define cminus_gc_calloc(count, size) cminus_gc_calloc_impl((count), (size), __FILE__, __LINE__)
#define cminus_gc_free(mem) cminus_gc_free_impl((mem), __FILE__, __LINE__)

uniq struct __CMinusGCHeader* __cminus_gc_live_head = NULL;
uniq struct __CMinusGCHeader* __cminus_gc_dead_head = NULL;
uniq size_t __cminus_gc_step_budget = 1;
uniq size_t __cminus_gc_live_count = 0;
uniq struct __CMinusStackFrame* __cminus_stack_head = NULL;
uniq size_t __cminus_stack_next_id = 1;

static void* __cminus_gc_payload(struct __CMinusGCHeader* header)
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

static __attribute__((unused)) struct __CMinusGCHeader* __cminus_gc_find_live(void* mem)
{
    struct __CMinusGCHeader* header;
    struct __CMinusGCHeader* it = __cminus_gc_live_head;

    while (it != NULL) {
        if (__cminus_gc_payload(it) == mem) {
            header = __cminus_gc_header_from_payload(mem);
            if (__cminus_gc_header_is_valid(header) && header == it && header->alive) {
                return header;
            }
            return NULL;
        }
        it = it->next;
    }
    return NULL;
}

static __attribute__((unused)) struct __CMinusGCHeader* __cminus_gc_find_dead(void* mem)
{
    struct __CMinusGCHeader* header;
    struct __CMinusGCHeader* it = __cminus_gc_dead_head;

    while (it != NULL) {
        if (__cminus_gc_payload(it) == mem) {
            header = __cminus_gc_header_from_payload(mem);
            if (__cminus_gc_header_is_valid(header) && header == it && !header->alive) {
                return header;
            }
            return NULL;
        }
        it = it->dead_next;
    }
    return NULL;
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

static __attribute__((unused)) int __cminus_gc_contains(struct __CMinusGCHeader* header, void* mem)
{
    size_t start = (size_t)__cminus_gc_payload(header);
    size_t end = start + header->capacity;
    size_t ptr = (size_t)mem;

    return ptr >= start && ptr < end;
}

uniq void cminus_gc_step(void)
{
    (void)__cminus_gc_step_budget;
}

uniq void cminus_gc_collect(void)
{
    cminus_gc_step();
}

uniq void cminus_gc_report_leaks(void)
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

uniq int cminus_gc_is_alive(void* mem)
{
    struct __CMinusGCHeader* it;

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

uniq int cminus_gc_is_managed(void* mem)
{
    struct __CMinusGCHeader* it;

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

uniq int cminus_gc_is_dead(void* mem)
{
    struct __CMinusGCHeader* it;

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

uniq void* cminus_gc_calloc_impl(size_t count, size_t size, const char* file, int line)
{
    struct __CMinusGCHeader* header;
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
    __cminus_gc_live_count++;
    cminus_gc_step();
    return __cminus_gc_payload(header);
}

uniq void cminus_gc_free_impl(void* mem, const char* file, int line)
{
    struct __CMinusGCHeader* live;
    struct __CMinusGCHeader* dead;

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
        (void)file;
        (void)line;
        return;
    }
    for (dead = __cminus_gc_dead_head; dead != NULL; dead = dead->dead_next) {
        if (__cminus_gc_contains(dead, mem)) {
            (void)file;
            (void)line;
            return;
        }
    }
    free(mem);
}

uniq size_t cminus_stack_enter_impl(const char* file, int line, void* anchor)
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

uniq void cminus_stack_leave_impl(size_t id, const char* file, int line)
{
    struct __CMinusStackFrame* frame = __cminus_stack_head;

    if (frame == NULL || frame->id != id) {
        cminus_panic("stack frame mismatch", file, line);
    }
    __cminus_stack_head = frame->prev;
    free(frame);
}

uniq int cminus_stack_is_alive(size_t id)
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

uniq int cminus_ptr_classify(void* mem, unsigned long* stack_id_out)
{
    struct __CMinusGCHeader* it;
    struct __CMinusStackFrame* frame;
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

uniq void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line)
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

enum __CMinusIndex<T> {
    Some(T),
    None,
};

enum Optional<T> {
    Some(T),
    None,
};

static __attribute__((unused)) Optional<FILE*>* xfopen(const char* path, const char* mode)
{
    __auto_type fp = fopen(path, mode);

    if (fp == NULL) {
        return new Optional<FILE*>.None();
    }
    return new Optional<FILE*>.Some(fp);
}

generic<T>
struct Ref {
    T* data;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};

generic<T>
struct Ref<T>* Ref_from(T* data)
{
    struct Ref<T>* out;
    unsigned long stack_id = 0;

    out = cminus_gc_calloc(1, sizeof(struct Ref<T>));
    out->data = data;
    out->origin_kind = cminus_ptr_classify(data, &stack_id);
    out->origin_stack_id = stack_id;
    return out;
}

generic<T>
int Ref_is_null(struct Ref<T>* self)
{
    if (self == NULL) {
        return 1;
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return self->data == NULL;
}

generic<T>
T Ref_get(struct Ref<T>* self)
{
    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return *self->data;
}

generic<T>
void Ref_set(struct Ref<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    *self->data = value;
}

generic<T>
struct Span {
    T* data;
    int len;
    T* base;
    int cap;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};

generic<T>
struct Span<T>* Span_from(T* data, int len)
{
    struct Span<T>* out;
    unsigned long stack_id = 0;

    out = cminus_gc_calloc(1, sizeof(struct Span<T>));
    out->data = data;
    out->len = len < 0 ? 0 : len;
    out->base = data;
    out->cap = out->len;
    out->origin_kind = cminus_ptr_classify(data, &stack_id);
    out->origin_stack_id = stack_id;
    return out;
}

generic<T>
struct Span<T>* Span_from_bytes(T* data, int bytes)
{
    if (bytes < 0 || bytes % (int)sizeof(T) != 0) {
        cminus_panic("span byte size is not aligned to element size", __FILE__, __LINE__);
    }
    return Span<T>.from(data, bytes / (int)sizeof(T));
}

generic<T>
struct Span<T>* Span_empty(void)
{
    struct Span<T>* out;

    out = cminus_gc_calloc(1, sizeof(struct Span<T>));
    out->data = NULL;
    out->len = 0;
    out->base = NULL;
    out->cap = 0;
    out->origin_kind = 0UL;
    out->origin_stack_id = 0;
    return out;
}

generic<T>
int Span_len(struct Span<T>* self)
{
    if (self == NULL) {
        return 0;
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return self->len;
}

generic<T>
int Span_is_empty(struct Span<T>* self)
{
    if (self == NULL) {
        return 1;
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return self->len == 0;
}

generic<T>
T Span_get(struct Span<T>* self, int index)
{
    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return self->data[index];
}

generic<T>
struct __CMinusIndex<T> Span_get_opt(struct Span<T>* self, int index)
{
    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self == NULL || self->data == NULL || self->base == NULL || index < 0 ||
        index >= self->len || self->data + index < self->base ||
        self->data + index >= self->base + self->cap) {
        return new __CMinusIndex<T>.None();
    }
    return new __CMinusIndex<T>.Some(self->data[index]);
}

generic<T>
T* Span_ptr_at(struct Span<T>* self, int index, const char* file, int line)
{
    if (self == NULL) {
        cminus_panic("dangling reference", file, line);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self == NULL || self->data == NULL || self->base == NULL || index < 0 ||
        index >= self->len || self->data + index < self->base ||
        self->data + index >= self->base + self->cap) {
        cminus_panic("index out of range", file, line);
    }
    return self->data + index;
}

generic<T>
struct Span<T>* Span_offset(struct Span<T>* self, int offset, const char* file, int line)
{
    struct Span<T>* out;

    if (self == NULL) {
        cminus_panic("dangling reference", file, line);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self == NULL || self->data == NULL || self->base == NULL) {
        cminus_panic("span offset out of range", file, line);
    }
    if (offset >= 0) {
        if (offset > self->len || self->data + offset > self->base + self->cap) {
            cminus_panic("span offset out of range", file, line);
        }
    } else {
        if (self->data + offset < self->base) {
            cminus_panic("span offset out of range", file, line);
        }
    }
    out = cminus_gc_calloc(1, sizeof(struct Span<T>));
    out->data = self->data + offset;
    out->len = self->len - offset;
    out->base = self->base;
    out->cap = self->cap;
    out->origin_kind = self->origin_kind;
    out->origin_stack_id = self->origin_stack_id;
    return out;
}

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
struct Span<T>* Vec_as_span(struct Vec<T>* self)
{
    if (self == NULL) {
        return Span_empty<T>();
    }
    return Span_from<T>(self->data, self->len);
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
int List_insert(struct List<T>* self, int index, T value)
{
    struct ListNode<T>* node;
    struct ListNode<T>* prev;
    int i;

    if (self == NULL || index < 0 || index > self->len) {
        return 0;
    }
    if (index == 0) {
        List_push_front<T>(self, value);
        return 1;
    }
    if (index == self->len) {
        List_push<T>(self, value);
        return 1;
    }
    node = calloc(1, sizeof(struct ListNode<T>));
    if (node == NULL) {
        abort();
    }
    node->value = value;
    prev = self->head;
    i = 0;
    while (prev != NULL && i < index - 1) {
        prev = prev->next;
        i++;
    }
    if (prev == NULL) {
        free(node);
        return 0;
    }
    node->next = prev->next;
    prev->next = node;
    self->len++;
    return 1;
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
struct __CMinusIndex<T> List_remove_at_opt(struct List<T>* self, int index)
{
    struct ListNode<T>* node;
    struct ListNode<T>* prev;
    T value;
    int i;

    if (self == NULL || index < 0 || index >= self->len) {
        return new __CMinusIndex<T>.None();
    }
    if (index == 0) {
        return List_pop_front_opt<T>(self);
    }
    prev = self->head;
    i = 0;
    while (prev != NULL && i < index - 1) {
        prev = prev->next;
        i++;
    }
    if (prev == NULL || prev->next == NULL) {
        return new __CMinusIndex<T>.None();
    }
    node = prev->next;
    value = node->value;
    prev->next = node->next;
    if (self->tail == node) {
        self->tail = prev;
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

generic<T>
struct Span<T>* List_to_span(struct List<T>* self, T* out, int cap)
{
    struct ListNode<T>* node;
    int count;

    if (self == NULL || out == NULL || cap <= 0) {
        return Span_empty<T>();
    }
    node = self->head;
    count = 0;
    while (node != NULL && count < cap) {
        out[count] = node->value;
        node = node->next;
        count++;
    }
    return Span_from<T>(out, count);
}

generic<T>
struct Vec<T>* List_to_vec(struct List<T>* self)
{
    struct Vec<T>* out;
    struct ListNode<T>* node;

    out = Vec_new<T>();
    if (self == NULL) {
        return out;
    }
    node = self->head;
    while (node != NULL) {
        Vec_push<T>(out, node->value);
        node = node->next;
    }
    return out;
}

generic<T>
struct List<T>* Vec_to_list(struct Vec<T>* self)
{
    struct List<T>* out;
    int i;

    out = List_new<T>();
    if (self == NULL) {
        return out;
    }
    i = 0;
    while (i < self->len) {
        List_push<T>(out, self->data[i]);
        i++;
    }
    return out;
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

generic<K,V>
struct Span<K>* Map_keys_to_span(struct Map<K,V>* self, K* out, int cap)
{
    int i;
    int count;

    if (self == NULL || out == NULL || cap <= 0) {
        return Span_empty<K>();
    }
    i = 0;
    count = 0;
    while (i < self->cap && count < cap) {
        if (self->states[i] == 1) {
            out[count] = self->keys[i];
            count++;
        }
        i++;
    }
    return Span_from<K>(out, count);
}

generic<K,V>
struct Span<V>* Map_values_to_span(struct Map<K,V>* self, V* out, int cap)
{
    int i;
    int count;

    if (self == NULL || out == NULL || cap <= 0) {
        return Span_empty<V>();
    }
    i = 0;
    count = 0;
    while (i < self->cap && count < cap) {
        if (self->states[i] == 1) {
            out[count] = self->values[i];
            count++;
        }
        i++;
    }
    return Span_from<V>(out, count);
}

generic<K,V>
struct Vec<K>* Map_keys_to_vec(struct Map<K,V>* self)
{
    struct Vec<K>* out;
    int i;

    out = Vec_new<K>();
    if (self == NULL) {
        return out;
    }
    i = 0;
    while (i < self->cap) {
        if (self->states[i] == 1) {
            Vec_push<K>(out, self->keys[i]);
        }
        i++;
    }
    return out;
}

generic<K,V>
struct List<K>* Map_keys_to_list(struct Map<K,V>* self)
{
    struct List<K>* out;
    int i;

    out = List_new<K>();
    if (self == NULL) {
        return out;
    }
    i = 0;
    while (i < self->cap) {
        if (self->states[i] == 1) {
            List_push<K>(out, self->keys[i]);
        }
        i++;
    }
    return out;
}

generic<K,V>
struct Vec<V>* Map_values_to_vec(struct Map<K,V>* self)
{
    struct Vec<V>* out;
    int i;

    out = Vec_new<V>();
    if (self == NULL) {
        return out;
    }
    i = 0;
    while (i < self->cap) {
        if (self->states[i] == 1) {
            Vec_push<V>(out, self->values[i]);
        }
        i++;
    }
    return out;
}

generic<K,V>
struct List<V>* Map_values_to_list(struct Map<K,V>* self)
{
    struct List<V>* out;
    int i;

    out = List_new<V>();
    if (self == NULL) {
        return out;
    }
    i = 0;
    while (i < self->cap) {
        if (self->states[i] == 1) {
            List_push<V>(out, self->values[i]);
        }
        i++;
    }
    return out;
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
