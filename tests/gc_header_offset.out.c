void cminus_panic(const char* message, const char* file, int line);
int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
void* cminus_gc_calloc_impl(unsigned long count, unsigned long size, const char* file, int line);

#define __CMINUS_GC_MAGIC 0x434d494e55534743UL

#define cminus_gc_calloc(count, size) cminus_gc_calloc_impl((count), (size), __FILE__, __LINE__)
#define cminus_gc_free(mem) cminus_gc_free_impl((mem), __FILE__, __LINE__)
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
static __attribute__((unused)) struct Optional_FILE_ptr* Optional_FILE_ptr_Some(FILE* value)
{
    struct Optional_FILE_ptr* out = cminus_gc_calloc(1, sizeof(struct Optional_FILE_ptr));
    out->tag = Optional_FILE_ptr_TAG_Some;
    out->origin_kind = cminus_ptr_classify((void*)value, &out->origin_stack_id);
    out->payload.Some = value;
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
static __attribute__((unused)) struct Optional_FILE_ptr* Optional_FILE_ptr_None(void)
{
    struct Optional_FILE_ptr* out = cminus_gc_calloc(1, sizeof(struct Optional_FILE_ptr));
    out->tag = Optional_FILE_ptr_TAG_None;
    out->origin_kind = 0UL;
    out->origin_stack_id = 0UL;
    return out;
}
static __attribute__((unused)) int Optional_FILE_ptr_is_None(struct Optional_FILE_ptr* self)
{
    return self->tag == Optional_FILE_ptr_TAG_None;
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
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));

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
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));

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

void cminus_gc_step(void)
{
    (void)__cminus_gc_step_budget;
}

void cminus_gc_collect(void)
{
    cminus_gc_step();
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

static __attribute__((unused)) struct Optional_FILE_ptr* xfopen(const char* path, const char* mode)
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
struct Data {
    int value;
};

static __attribute__((unused)) struct Data* Data_clone(struct Data* self)
{
    struct Data* copy = cminus_gc_calloc(1, sizeof(struct Data));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->value = self->value;
    return copy;
}


int main(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Data *first = cminus_gc_calloc(1, sizeof(struct Data)); {
        struct __CMinusGCHeader* first_header = __cminus_gc_header_from_payload(first);

        if (__cminus_gc_payload(first_header) != first) {
            if (first != NULL) {
                cminus_gc_free(first);
            }

            cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
            return 1;
        }
        if (first_header->magic != __CMINUS_GC_MAGIC) {
            if (first != NULL) {
                cminus_gc_free(first);
            }

            cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
            return 2;
        }
        if (!first_header->alive) {
            if (first != NULL) {
                cminus_gc_free(first);
            }

            cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
            return 3;
        }
        cminus_gc_free(first);
        if (first_header->alive) {
            if (first != NULL) {
                cminus_gc_free(first);
            }

            cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
            return 4;
        }
    }
    if (first != NULL) {
        cminus_gc_free(first);
    }

    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return 0;
}