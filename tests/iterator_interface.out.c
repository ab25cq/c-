void cminus_panic(const char* message, const char* file, int line);
int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
__SIZE_TYPE__ cminus_stack_enter_impl(const char* file, int line, void* anchor);
void cminus_stack_leave_impl(__SIZE_TYPE__ id, const char* file, int line);
void* cminus_gc_calloc_impl(__SIZE_TYPE__ count, __SIZE_TYPE__ size, const char* file, int line);
void cminus_gc_free_impl(void* mem, const char* file, int line);

#define __CMINUS_GC_MAGIC 0x434d4743UL
#define __CMINUS_STACK_NOTE_WINDOW (1024UL * 1024UL)
#define cminus_gc_calloc(count, size) cminus_gc_calloc_impl((count), (size), __FILE__, __LINE__)
#define cminus_gc_free(mem) cminus_gc_free_impl((mem), __FILE__, __LINE__)
#define AtomicRelaxed __ATOMIC_RELAXED
#define AtomicAcquire __ATOMIC_ACQUIRE
#define AtomicRelease __ATOMIC_RELEASE
#define AtomicAcqRel __ATOMIC_ACQ_REL
#define AtomicSeqCst __ATOMIC_SEQ_CST
#define CMINUS_PTHREAD_STORAGE_WORDS 8
#define CMINUS_THREAD_LOCAL __thread
#define __cminus_mod_ul(value, alignment) ((unsigned long)(value) % (unsigned long)(alignment))
#define align_up(value, alignment) cminus_align_up_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#define align_down(value, alignment) cminus_align_down_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#define is_aligned(value, alignment) cminus_is_aligned_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)


#define __CMINUS_BITMAP_SELECT(_1, _2, _3, NAME, ...) NAME
#define __CMINUS_BITMAP_FROM2(words, bits) Bitmap_from_impl((words), (bits), 0)
#define __CMINUS_BITMAP_FROM3(words, bits, allow_raw) Bitmap_from_impl((words), (bits), (allow_raw))
#define __CMINUS_BITMAP_FROM_WORDS2(words, words_len) Bitmap_from_words_impl((words), (words_len), 0)
#define __CMINUS_BITMAP_FROM_WORDS3(words, words_len, allow_raw) Bitmap_from_words_impl((words), (words_len), (allow_raw))
#define __CMINUS_BITMAP_FROM_BYTES2(words, bytes) Bitmap_from_bytes_impl((words), (bytes), 0)
#define __CMINUS_BITMAP_FROM_BYTES3(words, bytes, allow_raw) Bitmap_from_bytes_impl((words), (bytes), (allow_raw))
#define Bitmap_from(...) __CMINUS_BITMAP_SELECT(__VA_ARGS__, __CMINUS_BITMAP_FROM3, __CMINUS_BITMAP_FROM2)(__VA_ARGS__)
#define Bitmap_from_words(...) __CMINUS_BITMAP_SELECT(__VA_ARGS__, __CMINUS_BITMAP_FROM_WORDS3, __CMINUS_BITMAP_FROM_WORDS2)(__VA_ARGS__)
#define Bitmap_from_bytes(...) __CMINUS_BITMAP_SELECT(__VA_ARGS__, __CMINUS_BITMAP_FROM_BYTES3, __CMINUS_BITMAP_FROM_BYTES2)(__VA_ARGS__)
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
#include <pthread.h>
#include <sched.h>
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
struct Iterator_int{
    void* self;
    struct __CMinusIndex_int (*next_fn)(void* self);
};
struct Vec_int{
    int* data;
    int len;
    int cap;
};
struct VecIterator_int{
    struct Vec_int* vec;
    int index;
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
struct ListIterator_int{
    struct ListNode_int* node;
};
struct Iterator_int* Iterator_new_int(void* self, struct __CMinusIndex_int (*next_fn)(void* self));
struct __CMinusIndex_int Iterator_next_int(struct Iterator_int* self);
struct Vec_int* Vec_new_int(void);
void Vec_push_int(struct Vec_int* self, int value);
void Vec_delete_int(struct Vec_int* self);
struct __CMinusIndex_int VecIterator_next_int(struct VecIterator_int* self);
struct Iterator_int* Vec_iter_int(struct Vec_int* self);
struct List_int* List_new_int(void);
void List_push_int(struct List_int* self, int value);
void List_delete_int(struct List_int* self);
struct __CMinusIndex_int ListIterator_next_int(struct ListIterator_int* self);
struct Iterator_int* List_iter_int(struct List_int* self);
#ifndef CMINUS_BARE_H
#endif

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
    size_t explicit_low;
    size_t explicit_high;
    int has_explicit;
    struct __CMinusStackFrame* prev;
};

static __attribute__((unused)) struct __CMinusStackFrame* __CMinusStackFrame_clone(struct __CMinusStackFrame* self)
{
    struct __CMinusStackFrame* copy = calloc(1, sizeof(struct __CMinusStackFrame));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->has_explicit = self->has_explicit;
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
void cminus_stack_note_caller_range(void* mem, size_t bytes);
void cminus_stack_note_parent_range(void* mem, size_t bytes);
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
CMINUS_THREAD_LOCAL struct __CMinusStackFrame* __cminus_stack_head = NULL;
CMINUS_THREAD_LOCAL size_t __cminus_stack_next_id = 1;
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
#ifndef CMINUS_BARE_H
    if (__cminus_stack_head != NULL) {
        if (here < __cminus_stack_head->low) {
            __cminus_stack_head->low = here;
        }
        if (here > __cminus_stack_head->high) {
            __cminus_stack_head->high = here;
        }
    }
#endif
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

void cminus_stack_note_caller_range(void* mem, size_t bytes)
{
    struct __CMinusStackFrame* frame = {0};
    memset(&frame, 0, sizeof(frame));

    size_t low;
    size_t high;
    size_t anchor;
    size_t parent_anchor;
    size_t near_anchor;
    size_t near_parent;

    if (mem == NULL || bytes == 0) {
        return;
    }
    frame = __cminus_stack_head;
    if (frame == NULL) {
        return;
    }
    low = (size_t)mem;
    high = low + bytes - 1;
    if (high < low) {
        high = low;
    }
    anchor = frame->anchor;
    parent_anchor = frame->parent_anchor;
    near_anchor = low > anchor ? low - anchor : anchor - low;
    if (high > anchor && high - anchor < near_anchor) {
        near_anchor = high - anchor;
    } else if (high <= anchor && anchor - high < near_anchor) {
        near_anchor = anchor - high;
    }
    near_parent = low > parent_anchor ? low - parent_anchor : parent_anchor - low;
    if (high > parent_anchor && high - parent_anchor < near_parent) {
        near_parent = high - parent_anchor;
    } else if (high <= parent_anchor && parent_anchor - high < near_parent) {
        near_parent = parent_anchor - high;
    }
    if (near_anchor > __CMINUS_STACK_NOTE_WINDOW && near_parent > __CMINUS_STACK_NOTE_WINDOW) {
        return;
    }
    if (low < frame->low) {
        frame->low = low;
    }
    if (high > frame->high) {
        frame->high = high;
    }
    if (!frame->has_explicit || low < frame->explicit_low) {
        frame->explicit_low = low;
    }
    if (!frame->has_explicit || high > frame->explicit_high) {
        frame->explicit_high = high;
    }
    frame->has_explicit = 1;
}

void cminus_stack_note_parent_range(void* mem, size_t bytes)
{
    struct __CMinusStackFrame* frame = __cminus_stack_head;
    size_t low;
    size_t high;

    if (mem == NULL || bytes == 0 || frame == NULL || frame->prev == NULL) {
        return;
    }
    frame = frame->prev;
    low = (size_t)mem;
    high = low + bytes - 1;
    if (high < low) {
        high = low;
    }
    if (low < frame->low) {
        frame->low = low;
    }
    if (high > frame->high) {
        frame->high = high;
    }
    if (!frame->has_explicit || low < frame->explicit_low) {
        frame->explicit_low = low;
    }
    if (!frame->has_explicit || high > frame->explicit_high) {
        frame->explicit_high = high;
    }
    frame->has_explicit = 1;
}

int cminus_ptr_classify(void* mem, unsigned long* stack_id_out)
{
    struct __CMinusStackFrame* frame = {0};
    memset(&frame, 0, sizeof(frame));

#ifndef CMINUS_BARE_H
    struct __CMinusStackFrame* owner = NULL;
#endif
    size_t ptr;

    if (stack_id_out != NULL) {
        *stack_id_out = 0;
    }
    if (mem == NULL) {
        return __CMinusPtrKind_Raw;
    }
    ptr = (size_t)mem;
    frame = __cminus_stack_head;
#ifdef CMINUS_BARE_H
    while (frame != NULL) {
        if (frame->has_explicit && ptr >= frame->explicit_low && ptr <= frame->explicit_high) {
            if (stack_id_out != NULL) {
                *stack_id_out = frame->id;
            }
            return __CMinusPtrKind_Stack;
        }
        frame = frame->prev;
    }
    frame = __cminus_stack_head;
    if (frame != NULL && ptr >= frame->low && ptr <= frame->high) {
        if (stack_id_out != NULL) {
            *stack_id_out = frame->id;
        }
        return __CMinusPtrKind_Stack;
    }
#else
    while (frame != NULL) {
        if (frame->has_explicit && ptr >= frame->explicit_low && ptr <= frame->explicit_high) {
            if (stack_id_out != NULL) {
                *stack_id_out = frame->id;
            }
            return __CMinusPtrKind_Stack;
        }
        frame = frame->prev;
    }
    frame = __cminus_stack_head;
    while (frame != NULL) {
        if (ptr >= frame->low && ptr <= frame->high) {
            owner = frame;
        }
        frame = frame->prev;
    }
    if (owner != NULL) {
        if (stack_id_out != NULL) {
            *stack_id_out = owner->id;
        }
        return __CMinusPtrKind_Stack;
    }
#endif

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
        __typeof__((Optional_FILE_ptr_None())) __cminus_return0 = (Optional_FILE_ptr_None());
        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return __cminus_return0;
    }
    __typeof__((Optional_FILE_ptr_Some(fp))) __cminus_return1 = (Optional_FILE_ptr_Some(fp));
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return1;
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

#ifndef CMINUS_BARE_H
typedef int (*CMinusThreadMain)(void);

typedef struct Thread Thread;
typedef struct Mutex Mutex;
typedef struct Cond Cond;

struct __CMinusThreadState {
    CMinusThreadMain fn;
    int result;
};

static __attribute__((unused)) struct __CMinusThreadState* __CMinusThreadState_clone(struct __CMinusThreadState* self)
{
    struct __CMinusThreadState* copy = calloc(1, sizeof(struct __CMinusThreadState));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->result = self->result;
    return copy;
}


struct Thread {
    unsigned long handle_bits;
    struct __CMinusThreadState* state;
    int started;
    int joined;
};

static __attribute__((unused)) struct Thread* Thread_clone(struct Thread* self)
{
    struct Thread* copy = cminus_gc_calloc(1, sizeof(struct Thread));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->handle_bits = self->handle_bits;
    copy->state = self->state;
    copy->started = self->started;
    copy->joined = self->joined;
    return copy;
}


struct Mutex {
    unsigned long value_bits[CMINUS_PTHREAD_STORAGE_WORDS];
    int initialized;
};

static __attribute__((unused)) struct Mutex* Mutex_clone(struct Mutex* self)
{
    struct Mutex* copy = cminus_gc_calloc(1, sizeof(struct Mutex));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    memcpy(copy->value_bits, self->value_bits, sizeof(copy->value_bits));
    copy->initialized = self->initialized;
    return copy;
}


struct Cond {
    unsigned long value_bits[CMINUS_PTHREAD_STORAGE_WORDS];
    int initialized;
};

static __attribute__((unused)) struct Cond* Cond_clone(struct Cond* self)
{
    struct Cond* copy = cminus_gc_calloc(1, sizeof(struct Cond));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    memcpy(copy->value_bits, self->value_bits, sizeof(copy->value_bits));
    copy->initialized = self->initialized;
    return copy;
}

#endif


#ifndef CMINUS_BARE_H
static __attribute__((unused)) void* __cminus_thread_entry(void* raw)
{
    struct __CMinusThreadState* state = (struct __CMinusThreadState*)raw;

    state->result = (*(state->fn))();
    return NULL;
}

static __attribute__((unused)) struct Thread Thread_spawn(CMinusThreadMain fn)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Thread out = {0};
    memset(&out, 0, sizeof(out));

    pthread_t handle;
    int rc = {0};
    memset(&rc, 0, sizeof(rc));


    if (fn == NULL) {
        cminus_panic("thread function is null", __FILE__, __LINE__);
    }
    if (sizeof(pthread_t) > sizeof(out.handle_bits)) {
        cminus_panic("pthread_t is too large", __FILE__, __LINE__);
    }
    memset(&out, 0, sizeof(out));
    out.state = (struct __CMinusThreadState*)calloc(1, sizeof(struct __CMinusThreadState));
    if (out.state == NULL) {
        cminus_panic("thread allocation failed", __FILE__, __LINE__);
    }
    out.state->fn = fn;
    rc = pthread_create(&handle, NULL, __cminus_thread_entry, out.state);
    if (rc != 0) {
        free(out.state);
        cminus_panic("pthread_create failed", __FILE__, __LINE__);
    }
    memcpy(&out.handle_bits, &handle, sizeof(handle));
    out.started = 1;
    __typeof__((out)) __cminus_return2 = (out);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return2;
}

static __attribute__((unused)) int Thread_join(struct Thread* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_t handle;
    int rc = {0};
    memset(&rc, 0, sizeof(rc));

    int result = {0};
    memset(&result, 0, sizeof(result));


    if (self == NULL || !self->started) {
        cminus_panic("thread is not started", __FILE__, __LINE__);
    }
    if (self->joined) {
        cminus_panic("thread is already joined", __FILE__, __LINE__);
    }
    memset(&handle, 0, sizeof(handle));
    memcpy(&handle, &self->handle_bits, sizeof(handle));
    rc = pthread_join(handle, NULL);
    if (rc != 0) {
        cminus_panic("pthread_join failed", __FILE__, __LINE__);
    }
    result = self->state != NULL ? self->state->result : 0;
    free(self->state);
    self->state = NULL;
    self->joined = 1;
    __typeof__((result)) __cminus_return3 = (result);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return3;
}

static __attribute__((unused)) void Thread_detach(struct Thread* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_t handle;
    int rc = {0};
    memset(&rc, 0, sizeof(rc));


    if (self == NULL || !self->started) {
        cminus_panic("thread is not started", __FILE__, __LINE__);
    }
    if (self->joined) {
        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return;
    }
    memset(&handle, 0, sizeof(handle));
    memcpy(&handle, &self->handle_bits, sizeof(handle));
    rc = pthread_detach(handle);
    if (rc != 0) {
        cminus_panic("pthread_detach failed", __FILE__, __LINE__);
    }
    free(self->state);
    self->state = NULL;
    self->joined = 1;    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Thread_yield(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    sched_yield();    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) struct Mutex Mutex_init(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Mutex out = {0};
    memset(&out, 0, sizeof(out));

    pthread_mutex_t* native;

    if (sizeof(pthread_mutex_t) > sizeof(out.value_bits)) {
        cminus_panic("pthread_mutex_t is too large", __FILE__, __LINE__);
    }
    memset(&out, 0, sizeof(out));
    native = (pthread_mutex_t*)out.value_bits;
    if (pthread_mutex_init(native, NULL) != 0) {
        cminus_panic("pthread_mutex_init failed", __FILE__, __LINE__);
    }
    out.initialized = 1;
    __typeof__((out)) __cminus_return4 = (out);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return4;
}

static __attribute__((unused)) void Mutex_lock(struct Mutex* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_mutex_t* native;

    if (self == NULL || !self->initialized) {
        cminus_panic("mutex is uninitialized", __FILE__, __LINE__);
    }
    native = (pthread_mutex_t*)self->value_bits;
    if (pthread_mutex_lock(native) != 0) {
        cminus_panic("pthread_mutex_lock failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Mutex_unlock(struct Mutex* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_mutex_t* native;

    if (self == NULL || !self->initialized) {
        cminus_panic("mutex is uninitialized", __FILE__, __LINE__);
    }
    native = (pthread_mutex_t*)self->value_bits;
    if (pthread_mutex_unlock(native) != 0) {
        cminus_panic("pthread_mutex_unlock failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Mutex_destroy(struct Mutex* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_mutex_t* native;

    if (self == NULL || !self->initialized) {
        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return;
    }
    native = (pthread_mutex_t*)self->value_bits;
    if (pthread_mutex_destroy(native) != 0) {
        cminus_panic("pthread_mutex_destroy failed", __FILE__, __LINE__);
    }
    self->initialized = 0;    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) struct Cond Cond_init(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Cond out = {0};
    memset(&out, 0, sizeof(out));

    pthread_cond_t* native;

    if (sizeof(pthread_cond_t) > sizeof(out.value_bits)) {
        cminus_panic("pthread_cond_t is too large", __FILE__, __LINE__);
    }
    memset(&out, 0, sizeof(out));
    native = (pthread_cond_t*)out.value_bits;
    if (pthread_cond_init(native, NULL) != 0) {
        cminus_panic("pthread_cond_init failed", __FILE__, __LINE__);
    }
    out.initialized = 1;
    __typeof__((out)) __cminus_return5 = (out);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return5;
}

static __attribute__((unused)) void Cond_wait(struct Cond* self, struct Mutex* mutex)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_cond_t* native_cond;
    pthread_mutex_t* native_mutex;

    if (self == NULL || !self->initialized || mutex == NULL || !mutex->initialized) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    native_cond = (pthread_cond_t*)self->value_bits;
    native_mutex = (pthread_mutex_t*)mutex->value_bits;
    if (pthread_cond_wait(native_cond, native_mutex) != 0) {
        cminus_panic("pthread_cond_wait failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Cond_signal(struct Cond* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_cond_t* native;

    if (self == NULL || !self->initialized) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    native = (pthread_cond_t*)self->value_bits;
    if (pthread_cond_signal(native) != 0) {
        cminus_panic("pthread_cond_signal failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Cond_broadcast(struct Cond* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_cond_t* native;

    if (self == NULL || !self->initialized) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    native = (pthread_cond_t*)self->value_bits;
    if (pthread_cond_broadcast(native) != 0) {
        cminus_panic("pthread_cond_broadcast failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Cond_destroy(struct Cond* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_cond_t* native;

    if (self == NULL || !self->initialized) {
        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return;
    }
    native = (pthread_cond_t*)self->value_bits;
    if (pthread_cond_destroy(native) != 0) {
        cminus_panic("pthread_cond_destroy failed", __FILE__, __LINE__);
    }
    self->initialized = 0;    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}
#endif


struct Bitmap {
    unsigned long* words;
    int bits;
    int words_len;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};

static __attribute__((unused)) struct Bitmap* Bitmap_clone(struct Bitmap* self)
{
    struct Bitmap* copy = cminus_gc_calloc(1, sizeof(struct Bitmap));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->words = self->words;
    copy->bits = self->bits;
    copy->words_len = self->words_len;
    copy->origin_kind = self->origin_kind;
    copy->origin_stack_id = self->origin_stack_id;
    return copy;
}

typedef struct Bitmap Bitmap;

static __attribute__((unused)) int Bitmap_bits_per_word(void)
{
    return (int)(sizeof(unsigned long) * 8);
}

static __attribute__((unused)) int Bitmap_word_shift(void)
{
    return sizeof(unsigned long) == 8 ? 6 : 5;
}
static __attribute__((unused)) struct Bitmap Bitmap_from_impl(unsigned long* words, int bits, int allow_raw)
{
    struct Bitmap out = {0};
    memset(&out, 0, sizeof(out));

    unsigned long stack_id = {0};
    memset(&stack_id, 0, sizeof(stack_id));

    int shift = Bitmap_word_shift();

    out.words = words;
    out.bits = bits < 0 ? 0 : bits;
    out.words_len = out.bits == 0 ? 0 : (out.bits + Bitmap_bits_per_word() - 1) >> shift;
    if (allow_raw) {
        out.origin_kind = __CMinusPtrKind_Raw;
    } else {
        cminus_stack_note_caller_range(words, (size_t)out.words_len * sizeof(unsigned long));
        out.origin_kind = cminus_ptr_classify(words, &stack_id);
    }
    out.origin_stack_id = stack_id;
    return out;
}

static __attribute__((unused)) struct Bitmap Bitmap_from_words_impl(unsigned long* words, int words_len, int allow_raw)
{
    struct Bitmap out = {0};
    memset(&out, 0, sizeof(out));

    unsigned long stack_id = {0};
    memset(&stack_id, 0, sizeof(stack_id));

    int n = words_len < 0 ? 0 : words_len;

    out.words = words;
    out.bits = n * Bitmap_bits_per_word();
    out.words_len = n;
    if (allow_raw) {
        out.origin_kind = __CMinusPtrKind_Raw;
    } else {
        cminus_stack_note_caller_range(words, (size_t)out.words_len * sizeof(unsigned long));
        out.origin_kind = cminus_ptr_classify(words, &stack_id);
    }
    out.origin_stack_id = stack_id;
    return out;
}

static __attribute__((unused)) struct Bitmap Bitmap_from_bytes_impl(unsigned long* words, int bytes, int allow_raw)
{
    int word_bytes = sizeof(unsigned long);
    int shift = Bitmap_word_shift() - 3;

    if (bytes < 0 || (bytes & (word_bytes - 1)) != 0) {
        cminus_panic("bitmap byte size is not aligned to word size", __FILE__, __LINE__);
    }
    return Bitmap_from_words_impl(words, bytes >> shift, allow_raw);
}

static __attribute__((unused)) int Bitmap_len(struct Bitmap* self)
{
    if (self == NULL) {
        return 0;
    }
    cminus_ptr_require_alive(self->words, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return self->bits;
}

static __attribute__((unused)) int Bitmap_word_len(struct Bitmap* self)
{
    if (self == NULL) {
        return 0;
    }
    return self->words_len;
}

static __attribute__((unused)) int Bitmap_is_empty(struct Bitmap* self)
{
    return self == NULL || self->bits == 0;
}

static __attribute__((unused)) void Bitmap_check_index(struct Bitmap* self, int index)
{
    if (self == NULL || self->words == NULL) {
        cminus_panic("bitmap is null", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->words, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (index < 0 || index >= self->bits) {
        cminus_panic("bitmap index out of range", __FILE__, __LINE__);
    }
}

static __attribute__((unused)) int Bitmap_test(struct Bitmap* self, int index)
{
    int shift = Bitmap_word_shift();
    int mask = Bitmap_bits_per_word() - 1;

    Bitmap_check_index(self, index);
    return (self->words[index >> shift] & (1UL << (index & mask))) != 0UL;
}

static __attribute__((unused)) void Bitmap_set(struct Bitmap* self, int index)
{
    int shift = Bitmap_word_shift();
    int mask = Bitmap_bits_per_word() - 1;

    Bitmap_check_index(self, index);
    self->words[index >> shift] |= 1UL << (index & mask);
}

static __attribute__((unused)) void Bitmap_clear_bit(struct Bitmap* self, int index)
{
    int shift = Bitmap_word_shift();
    int mask = Bitmap_bits_per_word() - 1;

    Bitmap_check_index(self, index);
    self->words[index >> shift] &= ~(1UL << (index & mask));
}

static __attribute__((unused)) void Bitmap_clear_all(struct Bitmap* self)
{
    int i = 0;

    if (self == NULL || self->words == NULL) {
        return;
    }
    cminus_ptr_require_alive(self->words, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    while (i < self->words_len) {
        self->words[i] = 0UL;
        i++;
    }
}

static __attribute__((unused)) struct __CMinusIndex_int Bitmap_find_zero(struct Bitmap* self)
{
    int i = 0;

    if (self == NULL || self->words == NULL) {
        return __CMinusIndex_int_None();
    }
    cminus_ptr_require_alive(self->words, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    while (i < self->bits) {
        if (!Bitmap_test(self, i)) {
            return __CMinusIndex_int_Some(i);
        }
        i++;
    }
    return __CMinusIndex_int_None();
}

static __attribute__((unused)) struct __CMinusIndex_int Bitmap_alloc_opt(struct Bitmap* self)
{
    struct __CMinusIndex_int slot = Bitmap_find_zero(self);

    if (__CMinusIndex_int_is_Some(&slot)) {
        Bitmap_set(self, __CMinusIndex_int_get_Some(&slot));
    }
    return slot;
}

static __attribute__((unused)) void Bitmap_free_bit(struct Bitmap* self, int index)
{
    Bitmap_clear_bit(self, index);
}

int sum_iter(struct Iterator_int *it)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct __CMinusIndex_int item = {0};
    memset(&item, 0, sizeof(item));

    int sum = 0;

    while (1) {
        item = Iterator_next_int(it);
        if (__CMinusIndex_int_is_None(&item)) {
            break;
        }
        sum += __CMinusIndex_int_get_Some(&item);
    }
    __typeof__((sum)) __cminus_return6 = (sum);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return6;
}

int main(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Vec_int *xs = Vec_new_int();
    struct List_int *ys = List_new_int();
    int total = {0};
    memset(&total, 0, sizeof(total));


    Vec_push_int(xs, 1);
    Vec_push_int(xs, 2);
    Vec_push_int(xs, 3);

    List_push_int(ys, 10);
    List_push_int(ys, 20);

    total = sum_iter(Vec_iter_int(xs)) + sum_iter(List_iter_int(ys));
    printf("%d\n", total);
    __typeof__((total == 36 ? 0 : 1)) __cminus_return7 = (total == 36 ? 0 : 1);
    if (ys != NULL) {
        List_delete_int(ys);
        cminus_gc_free(ys);
    }

    if (xs != NULL) {
        Vec_delete_int(xs);
        cminus_gc_free(xs);
    }

    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return7;
}
struct Iterator_int* Iterator_new_int(void* self, struct __CMinusIndex_int (*next_fn)(void* self)){
    struct Iterator_int* out = cminus_gc_calloc(1, sizeof(struct Iterator_int));

    out->self = self;
    out->next_fn = next_fn;
    return out;
}
struct __CMinusIndex_int Iterator_next_int(struct Iterator_int* self){
    if (self == NULL || self->next_fn == NULL) {
        return __CMinusIndex_int_None();
    }
    return self->next_fn(self->self);
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
struct __CMinusIndex_int VecIterator_next_int(struct VecIterator_int* self){
    int value;

    if (self == NULL || self->vec == NULL) {
        return __CMinusIndex_int_None();
    }
    if (self->index >= self->vec->len) {
        return __CMinusIndex_int_None();
    }
    value = self->vec->data[self->index];
    self->index++;
    return __CMinusIndex_int_Some(value);
}
struct Iterator_int* Vec_iter_int(struct Vec_int* self){
    struct VecIterator_int* state = cminus_gc_calloc(1, sizeof(struct VecIterator_int));

    state->vec = self;
    state->index = 0;
    return Iterator_new_int(state, (struct __CMinusIndex_int (*)(void*))VecIterator_next_int);
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
struct __CMinusIndex_int ListIterator_next_int(struct ListIterator_int* self){
    int value;

    if (self == NULL || self->node == NULL) {
        return __CMinusIndex_int_None();
    }
    value = self->node->value;
    self->node = self->node->next;
    return __CMinusIndex_int_Some(value);
}
struct Iterator_int* List_iter_int(struct List_int* self){
    struct ListIterator_int* state = cminus_gc_calloc(1, sizeof(struct ListIterator_int));

    state->node = self == NULL ? NULL : self->head;
    return Iterator_new_int(state, (struct __CMinusIndex_int (*)(void*))ListIterator_next_int);
}
