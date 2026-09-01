#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <execinfo.h>
#ifndef CMINUS_BARE_H
#include <pthread.h>
#include <sched.h>
#endif

#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC optimize ("trapv")
#endif

#define __CMINUS_GC_MAGIC 0x434d4743UL
#define __CMINUS_STACK_NOTE_WINDOW (1024UL * 1024UL)
#ifndef CMINUS_MAX_ALLOCATION
#define CMINUS_MAX_ALLOCATION (1024UL * 1024UL * 1024UL)
#endif
#ifndef CMINUS_MAX_STACK_DEPTH
#define CMINUS_MAX_STACK_DEPTH 1024UL
#endif
#ifndef CMINUS_MAX_STACK_BYTES
#define CMINUS_MAX_STACK_BYTES (2UL * 1024UL * 1024UL)
#endif

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
    unsigned long allocation_id;
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
    size_t explicit_low;
    size_t explicit_high;
    int has_explicit;
    struct __CMinusStackFrame* prev;
};

uniq int cminus_gc_is_alive(void* mem);
uniq int cminus_gc_is_managed(void* mem);
uniq int cminus_gc_is_dead(void* mem);
uniq void cminus_gc_report_leaks(void);
uniq size_t cminus_stack_enter_impl(const char* file, int line, void* anchor);
uniq void cminus_stack_leave_impl(size_t id, const char* file, int line);
uniq int cminus_stack_is_alive(size_t id);
uniq void cminus_stack_note_caller_range(void* mem, size_t bytes);
uniq void cminus_stack_note_parent_range(void* mem, size_t bytes);
uniq int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
uniq void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
uniq size_t cminus_checked_size_add_impl(size_t left, size_t right, const char* file, int line);
uniq size_t cminus_checked_size_mul_impl(size_t left, size_t right, const char* file, int line);
uniq int cminus_checked_int_add_impl(int left, int right, const char* file, int line);
uniq int cminus_checked_int_mul_impl(int left, int right, const char* file, int line);
uniq void* cminus_gc_calloc_impl(size_t count, size_t size, const char* file, int line);
uniq void cminus_gc_free_impl(void* mem, const char* file, int line);
#ifndef CMINUS_BARE_H
uniq char* cminus_string_format(const char* fmt, ...);
#endif
static __attribute__((unused)) int cminus_string_len(const char* self);
static __attribute__((unused)) int cminus_string_is_empty(const char* self);
static __attribute__((unused)) int cminus_string_cmp(const char* self, const char* other);
static __attribute__((unused)) int cminus_string_eq(const char* self, const char* other);
static __attribute__((unused)) int cminus_string_contains(const char* self, const char* needle);
static __attribute__((unused)) int cminus_string_starts_with(const char* self, const char* prefix);
static __attribute__((unused)) int cminus_string_ends_with(const char* self, const char* suffix);
static __attribute__((unused)) void cminus_string_require_alive(const char* value);
#ifndef CMINUS_BARE_H
static __attribute__((unused)) unsigned long cminus_align_up_impl(unsigned long value, unsigned long alignment, const char* file, int line);
static __attribute__((unused)) unsigned long cminus_align_down_impl(unsigned long value, unsigned long alignment, const char* file, int line);
static __attribute__((unused)) int cminus_is_aligned_impl(unsigned long value, unsigned long alignment, const char* file, int line);
#endif
#define cminus_gc_calloc(count, size) cminus_gc_calloc_impl((count), (size), __FILE__, __LINE__)
#define cminus_gc_free(mem) cminus_gc_free_impl((mem), __FILE__, __LINE__)
#define cminus_checked_size_add(left, right) cminus_checked_size_add_impl((left), (right), __FILE__, __LINE__)
#define cminus_checked_size_mul(left, right) cminus_checked_size_mul_impl((left), (right), __FILE__, __LINE__)
#define cminus_checked_int_add(left, right) cminus_checked_int_add_impl((left), (right), __FILE__, __LINE__)
#define cminus_checked_int_mul(left, right) cminus_checked_int_mul_impl((left), (right), __FILE__, __LINE__)
#define AtomicRelaxed __ATOMIC_RELAXED
#define AtomicAcquire __ATOMIC_ACQUIRE
#define AtomicRelease __ATOMIC_RELEASE
#define AtomicAcqRel __ATOMIC_ACQ_REL
#define AtomicSeqCst __ATOMIC_SEQ_CST
#define CMINUS_PTHREAD_STORAGE_WORDS 8
#define CMINUS_THREAD_LOCAL __thread
#ifndef CMINUS_BARE_H
#define __cminus_mod_ul(value, alignment) ((unsigned long)(value) % (unsigned long)(alignment))
#define align_up(value, alignment) cminus_align_up_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#define align_down(value, alignment) cminus_align_down_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#define is_aligned(value, alignment) cminus_is_aligned_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#endif

uniq struct __CMinusGCHeader* __cminus_gc_live_head = NULL;
uniq struct __CMinusGCHeader* __cminus_gc_dead_head = NULL;
uniq unsigned long __cminus_gc_next_allocation_id = 1UL;
#ifndef CMINUS_BARE_H
uniq int __cminus_gc_lock_word = 0;
#endif
uniq CMINUS_THREAD_LOCAL struct __CMinusStackFrame* __cminus_stack_head = NULL;
uniq CMINUS_THREAD_LOCAL size_t __cminus_stack_next_id = 1;
uniq CMINUS_THREAD_LOCAL size_t __cminus_stack_depth = 0;
uniq CMINUS_THREAD_LOCAL size_t __cminus_stack_root_anchor = 0;
#ifdef CMINUS_BARE_H
uniq struct __CMinusStackFrame __cminus_stack_frames[256];
uniq int __cminus_stack_frame_used[256];
#endif

static __attribute__((unused)) void __cminus_gc_lock(void)
{
#ifndef CMINUS_BARE_H
    while (__atomic_exchange_n(&__cminus_gc_lock_word, 1,
                               __ATOMIC_ACQUIRE) != 0) {
        sched_yield();
    }
#endif
}

static __attribute__((unused)) void __cminus_gc_unlock(void)
{
#ifndef CMINUS_BARE_H
    __atomic_store_n(&__cminus_gc_lock_word, 0, __ATOMIC_RELEASE);
#endif
}

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

static __attribute__((unused)) int __cminus_gc_header_contains(
    struct __CMinusGCHeader* header, void* mem)
{
    size_t address;
    size_t base;
    size_t span;

    if (header == NULL || mem == NULL) {
        return 0;
    }
    address = (size_t)mem;
    base = (size_t)__cminus_gc_payload(header);
    span = header->capacity == 0 ? 1 : header->capacity;
    return address >= base && address - base < span;
}

static __attribute__((unused)) struct __CMinusGCHeader*
__cminus_gc_find_live_containing(void* mem)
{
    struct __CMinusGCHeader* it = __cminus_gc_live_head;

    while (it != NULL) {
        if (__cminus_gc_header_contains(it, mem)) {
            return it;
        }
        it = it->next;
    }
    return NULL;
}

static __attribute__((unused)) struct __CMinusGCHeader*
__cminus_gc_find_dead_containing(void* mem)
{
    struct __CMinusGCHeader* it = __cminus_gc_dead_head;

    while (it != NULL) {
        if (__cminus_gc_header_contains(it, mem)) {
            return it;
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

#ifndef CMINUS_BARE_H
static __attribute__((unused)) unsigned long cminus_align_up_impl(unsigned long value, unsigned long alignment, const char* file, int line)
{
    unsigned long rem;
    unsigned long add;

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
    unsigned long rem;

    if (alignment == 0u) {
        cminus_panic("alignment is zero", file, line);
    }
    rem = __cminus_mod_ul(value, alignment);
    return value - rem;
}

static __attribute__((unused)) int cminus_is_aligned_impl(unsigned long value, unsigned long alignment, const char* file, int line)
{
    unsigned long rem;

    if (alignment == 0u) {
        cminus_panic("alignment is zero", file, line);
    }
    rem = __cminus_mod_ul(value, alignment);
    return rem == 0u;
}
#endif

uniq void cminus_gc_report_leaks(void)
{
    struct __CMinusGCHeader* it;
    size_t leaks = 0;

    __cminus_gc_lock();
    it = __cminus_gc_live_head;
    while (it != NULL) {
        leaks++;
        fprintf(stderr, "managed leak #%zu: %zu bytes at %s:%d\n",
                leaks, it->size, it->file, it->line);
        it = it->next;
    }
    if (leaks > 0) {
        fprintf(stderr, "c-: %zu managed heap leaks\n", leaks);
    }
    __cminus_gc_unlock();
}

uniq int cminus_gc_is_alive(void* mem)
{
    int found;

    __cminus_gc_lock();
    found = __cminus_gc_find_live_containing(mem) != NULL;
    __cminus_gc_unlock();
    return found;
}

uniq int cminus_gc_is_managed(void* mem)
{
    int found;

    __cminus_gc_lock();
    found = __cminus_gc_find_live_containing(mem) != NULL ||
        __cminus_gc_find_dead_containing(mem) != NULL;
    __cminus_gc_unlock();
    return found;
}

uniq int cminus_gc_is_dead(void* mem)
{
    int found;

    __cminus_gc_lock();
    found = __cminus_gc_find_dead_containing(mem) != NULL;
    __cminus_gc_unlock();
    return found;
}

uniq size_t cminus_checked_size_add_impl(size_t left, size_t right, const char* file, int line)
{
    if (left > (size_t)-1 - right) {
        cminus_panic("size addition overflow", file, line);
    }
    return left + right;
}

uniq size_t cminus_checked_size_mul_impl(size_t left, size_t right, const char* file, int line)
{
    size_t result;

    if (__builtin_mul_overflow(left, right, &result)) {
        cminus_panic("size multiplication overflow", file, line);
    }
    return result;
}

uniq int cminus_checked_int_add_impl(int left, int right, const char* file, int line)
{
    int result;

    if (__builtin_add_overflow(left, right, &result)) {
        cminus_panic("integer addition overflow", file, line);
    }
    return result;
}

uniq int cminus_checked_int_mul_impl(int left, int right, const char* file, int line)
{
    int result;

    if (__builtin_mul_overflow(left, right, &result)) {
        cminus_panic("integer multiplication overflow", file, line);
    }
    return result;
}

#ifdef CMINUS_BARE_H
uniq int __addvsi3(int left, int right)
{
    return cminus_checked_int_add_impl(left, right, __FILE__, __LINE__);
}

uniq int __subvsi3(int left, int right)
{
    int result;

    if (__builtin_sub_overflow(left, right, &result)) {
        cminus_panic("integer subtraction overflow", __FILE__, __LINE__);
    }
    return result;
}

uniq int __mulvsi3(int left, int right)
{
    return cminus_checked_int_mul_impl(left, right, __FILE__, __LINE__);
}

uniq long long __addvdi3(long long left, long long right)
{
    long long result;

    if (__builtin_add_overflow(left, right, &result)) {
        cminus_panic("integer addition overflow", __FILE__, __LINE__);
    }
    return result;
}

uniq long long __subvdi3(long long left, long long right)
{
    long long result;

    if (__builtin_sub_overflow(left, right, &result)) {
        cminus_panic("integer subtraction overflow", __FILE__, __LINE__);
    }
    return result;
}

uniq long long __mulvdi3(long long left, long long right)
{
    long long result;

    if (__builtin_mul_overflow(left, right, &result)) {
        cminus_panic("integer multiplication overflow", __FILE__, __LINE__);
    }
    return result;
}
#endif

uniq void* cminus_gc_calloc_impl(size_t count, size_t size, const char* file, int line)
{
    struct __CMinusGCHeader* header;
    size_t total = cminus_checked_size_mul_impl(count, size, file, line);
    size_t allocation = cminus_checked_size_add_impl(sizeof(struct __CMinusGCHeader), total, file, line);

    if (total > (size_t)CMINUS_MAX_ALLOCATION) {
        cminus_panic("allocation exceeds safe limit", file, line);
    }

    __cminus_gc_lock();
    header = __cminus_gc_take_dead_fit(total);
    __cminus_gc_unlock();
    if (header != NULL) {
        memset(__cminus_gc_payload(header), 0, header->capacity);
    } else {
        header = calloc(1, allocation);
        if (header == NULL) {
            fprintf(stderr, "c-: out of memory at %s:%d\n", file, line);
            abort();
        }
        header->capacity = total;
    }
    header->magic = __CMINUS_GC_MAGIC;
    __cminus_gc_lock();
    header->allocation_id = __cminus_gc_next_allocation_id;
    __cminus_gc_next_allocation_id = (unsigned long)(
        __cminus_gc_next_allocation_id + (unsigned long)1);
    if (__cminus_gc_next_allocation_id == (unsigned long)0) {
        __cminus_gc_next_allocation_id = (unsigned long)1;
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
    __cminus_gc_unlock();
    return __cminus_gc_payload(header);
}

uniq void cminus_gc_free_impl(void* mem, const char* file, int line)
{
    struct __CMinusGCHeader* header;
    struct __CMinusGCHeader* containing;
    int invalid_interior = 0;

    if (mem == NULL) {
        return;
    }
    __cminus_gc_lock();
    containing = __cminus_gc_find_live_containing(mem);
    if (containing == NULL) {
        containing = __cminus_gc_find_dead_containing(mem);
    }
    if (containing != NULL && __cminus_gc_payload(containing) != mem) {
        invalid_interior = 1;
    }
    if (invalid_interior) {
        __cminus_gc_unlock();
        cminus_panic("cannot free interior managed pointer", file, line);
    }
    header = containing;
    if (header == NULL) {
        __cminus_gc_unlock();
        free(mem);
        return;
    }
    if (!header->alive) {
        __cminus_gc_unlock();
        (void)file;
        (void)line;
        return;
    }
    __cminus_gc_unlink_live(header);
    header->alive = 0;
    header->dead_next = __cminus_gc_dead_head;
    __cminus_gc_dead_head = header;
    __cminus_gc_unlock();
}

#ifndef CMINUS_BARE_H
uniq char* cminus_string_format(const char* fmt, ...)
{
    __builtin_va_list ap;
    __builtin_va_list copy;
    int len;
    char* out;

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

uniq size_t cminus_stack_enter_impl(const char* file, int line, void* anchor)
{
#ifdef CMINUS_BARE_H
    int slot = -1;
    int i;
    struct __CMinusStackFrame* frame;
#else
    struct __CMinusStackFrame* frame = calloc(1, sizeof(struct __CMinusStackFrame));
#endif
    size_t here = (size_t)anchor;
    size_t prev;
    size_t used;

    if (__cminus_stack_depth >= (size_t)CMINUS_MAX_STACK_DEPTH) {
        cminus_panic("safe stack depth exceeded", file, line);
    }
    if (__cminus_stack_depth == 0) {
        __cminus_stack_root_anchor = here;
    } else {
        used = here > __cminus_stack_root_anchor
            ? here - __cminus_stack_root_anchor
            : __cminus_stack_root_anchor - here;
        if (used >= (size_t)CMINUS_MAX_STACK_BYTES) {
            cminus_panic("safe stack byte budget exceeded", file, line);
        }
    }

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
    __cminus_stack_depth++;
    return frame->id;
}

uniq void cminus_stack_leave_impl(size_t id, const char* file, int line)
{
    struct __CMinusStackFrame* frame = __cminus_stack_head;
#ifdef CMINUS_BARE_H
    int i;
#endif

    if (frame == NULL || frame->id != id) {
        cminus_panic("stack frame mismatch", file, line);
    }
    __cminus_stack_head = frame->prev;
    if (__cminus_stack_depth > 0) {
        __cminus_stack_depth--;
    }
    if (__cminus_stack_depth == 0) {
        __cminus_stack_root_anchor = 0;
    }
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

uniq void cminus_stack_note_caller_range(void* mem, size_t bytes)
{
    struct __CMinusStackFrame* frame;
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

uniq void cminus_stack_note_parent_range(void* mem, size_t bytes)
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

uniq int cminus_ptr_classify(void* mem, unsigned long* stack_id_out)
{
    struct __CMinusStackFrame* frame;
    struct __CMinusGCHeader* managed;
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
    __cminus_gc_lock();
    managed = __cminus_gc_find_live_containing(mem);
    if (managed == NULL) {
        managed = __cminus_gc_find_dead_containing(mem);
    }
    if (managed != NULL) {
        if (stack_id_out != NULL) {
            *stack_id_out = managed->allocation_id;
        }
        __cminus_gc_unlock();
        return __CMinusPtrKind_Managed;
    }
    __cminus_gc_unlock();
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

uniq void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line)
{
    struct __CMinusGCHeader* managed;

    if (kind == __CMinusPtrKind_Raw) {
        return;
    }
    if (mem == NULL) {
        cminus_panic("dangling reference", file, line);
    }
    if (kind == __CMinusPtrKind_Managed) {
        __cminus_gc_lock();
        managed = __cminus_gc_find_live_containing(mem);
        if (managed == NULL || managed->allocation_id != stack_id) {
            __cminus_gc_unlock();
            cminus_panic("dangling managed heap reference", file, line);
        }
        __cminus_gc_unlock();
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

generic<T>
struct Iterator {
    void* self;
    struct __CMinusIndex<T> (*next_fn)(void* self);
};

generic<T>
struct Iterator<T>* Iterator_new(void* self, struct __CMinusIndex<T> (*next_fn)(void* self))
{
    struct Iterator<T>* out = cminus_gc_calloc(1, sizeof(struct Iterator<T>));

    out->self = self;
    out->next_fn = next_fn;
    return out;
}

generic<T>
struct __CMinusIndex<T> Iterator_next(struct Iterator<T>* self)
{
    if (self == NULL || self->next_fn == NULL) {
        return new __CMinusIndex<T>.None();
    }
    return self->next_fn(self->self);
}

static __attribute__((unused)) Optional<FILE*> xfopen(const char* path, const char* mode)
{
    __auto_type fp = fopen(path, mode);

    if (fp == NULL) {
        return new Optional<FILE*>.None();
    }
    return new Optional<FILE*>.Some(fp);
}

static __attribute__((unused)) void cminus_string_require_alive(const char* value)
{
    unsigned long allocation_id = (unsigned long)0;
    int kind;

    if (value == NULL) {
        cminus_panic("string is null", __FILE__, __LINE__);
    }
    kind = cminus_ptr_classify((void*)value, &allocation_id);
    cminus_ptr_require_alive((void*)value, (unsigned long)kind,
                             allocation_id, __FILE__, __LINE__);
}

static __attribute__((unused)) int cminus_string_len(const char* self)
{
    cminus_string_require_alive(self);
    return (int)strlen(self);
}

static __attribute__((unused)) int cminus_string_is_empty(const char* self)
{
    return cminus_string_len(self) == 0;
}

static __attribute__((unused)) int cminus_string_cmp(const char* self, const char* other)
{
    cminus_string_require_alive(self);
    cminus_string_require_alive(other);
    return strcmp(self, other);
}

static __attribute__((unused)) int cminus_string_eq(const char* self, const char* other)
{
    return cminus_string_cmp(self, other) == 0;
}

static __attribute__((unused)) int cminus_string_contains(const char* self, const char* needle)
{
    int self_len;
    int needle_len;
    int i;
    int j;

    cminus_string_require_alive(self);
    cminus_string_require_alive(needle);
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
    int prefix_len;
    int i;

    cminus_string_require_alive(self);
    cminus_string_require_alive(prefix);
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
    int self_len;
    int suffix_len;

    cminus_string_require_alive(self);
    cminus_string_require_alive(suffix);
    self_len = (int)strlen(self);
    suffix_len = (int)strlen(suffix);
    if (suffix_len > self_len) {
        return 0;
    }
    return strcmp(self + self_len - suffix_len, suffix) == 0;
}

generic<T>
struct Ref {
    T* data;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};

generic<T>
struct Ref<T> Ref_from(T* data, int allow_raw = 0)
{
    struct Ref<T> out;
    unsigned long stack_id = 0UL;

    out.data = data;
    if (allow_raw) {
        out.origin_kind = __CMinusPtrKind_Raw;
    } else {
        cminus_stack_note_caller_range(data, sizeof(T));
        out.origin_kind = cminus_ptr_classify(data, &stack_id);
    }
    out.origin_stack_id = stack_id;
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
    unsigned char* base_bytes;
    int cap_bytes;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};

generic<T>
struct Register {
    volatile T* addr;
};

generic<T>
struct Volatile {
    volatile T* addr;
};

struct Critical {
    unsigned long state;
    int active;
};

generic<T>
struct StaticCell {
    T value;
    int initialized;
};

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
    struct Critical out;

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

generic<T>
struct Atomic {
    T value;
};

#ifndef CMINUS_BARE_H
typedef int (*CMinusThreadMain)(void);
typedef int (*CMinusThreadContextMain)(void*);

typedef struct Thread Thread;
typedef struct Mutex Mutex;
typedef struct Cond Cond;

struct __CMinusThreadState {
    CMinusThreadMain fn;
    CMinusThreadContextMain context_fn;
    void* context;
    int result;
    int references;
};

struct Thread {
    unsigned long handle_bits;
    struct __CMinusThreadState* state;
    int started;
    int joined;
};

struct Mutex {
    pthread_mutex_t* native;
    int initialized;
};

struct Cond {
    pthread_cond_t* native;
    int initialized;
};
#endif

generic<T>
struct StaticCell<T> StaticCell_init(T value)
{
    struct StaticCell<T> out;

    out.value = value;
    out.initialized = 1;
    return out;
}

generic<T>
struct StaticCell<T> StaticCell_uninit(void)
{
    struct StaticCell<T> out;

    memset(&out, 0, sizeof(out));
    return out;
}

generic<T>
int StaticCell_is_initialized(struct StaticCell<T>* self)
{
    return self != NULL && self->initialized;
}

generic<T>
T StaticCell_get(struct StaticCell<T>* self)
{
    if (self == NULL || !self->initialized) {
        cminus_panic("static cell is uninitialized", __FILE__, __LINE__);
    }
    return self->value;
}

generic<T>
void StaticCell_set(struct StaticCell<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("static cell is null", __FILE__, __LINE__);
    }
    self->value = value;
    self->initialized = 1;
}

generic<T>
T StaticCell_replace(struct StaticCell<T>* self, T value)
{
    T old;

    if (self == NULL || !self->initialized) {
        cminus_panic("static cell is uninitialized", __FILE__, __LINE__);
    }
    old = self->value;
    self->value = value;
    return old;
}

static __attribute__((unused)) void cminus_atomic_require_load_order(int order)
{
    if (order != __ATOMIC_RELAXED && order != __ATOMIC_ACQUIRE &&
        order != __ATOMIC_SEQ_CST) {
        cminus_panic("invalid atomic load memory order", __FILE__, __LINE__);
    }
}

static __attribute__((unused)) void cminus_atomic_require_store_order(int order)
{
    if (order != __ATOMIC_RELAXED && order != __ATOMIC_RELEASE &&
        order != __ATOMIC_SEQ_CST) {
        cminus_panic("invalid atomic store memory order", __FILE__, __LINE__);
    }
}

static __attribute__((unused)) void cminus_atomic_require_rmw_order(int order)
{
    if (order != __ATOMIC_RELAXED && order != __ATOMIC_ACQUIRE &&
        order != __ATOMIC_RELEASE && order != __ATOMIC_ACQ_REL &&
        order != __ATOMIC_SEQ_CST) {
        cminus_panic("invalid atomic read-modify-write memory order",
                     __FILE__, __LINE__);
    }
}

static __attribute__((unused)) void cminus_atomic_require_compare_orders(
    int success_order, int failure_order)
{
    cminus_atomic_require_rmw_order(success_order);
    cminus_atomic_require_load_order(failure_order);
    if ((failure_order == __ATOMIC_ACQUIRE &&
         success_order != __ATOMIC_ACQUIRE &&
         success_order != __ATOMIC_ACQ_REL &&
         success_order != __ATOMIC_SEQ_CST) ||
        (failure_order == __ATOMIC_SEQ_CST &&
         success_order != __ATOMIC_SEQ_CST)) {
        cminus_panic("atomic compare-exchange failure order is stronger than success order",
                     __FILE__, __LINE__);
    }
}

generic<T>
struct Atomic<T> Atomic_init(T value)
{
    struct Atomic<T> out;

    __atomic_store_n(&out.value, value, __ATOMIC_SEQ_CST);
    return out;
}

generic<T>
T Atomic_load(struct Atomic<T>* self)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    return __atomic_load_n(&self->value, __ATOMIC_SEQ_CST);
}

generic<T>
T Atomic_load_order(struct Atomic<T>* self, int order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_load_order(order);
    return __atomic_load_n(&self->value, order);
}

generic<T>
void Atomic_store(struct Atomic<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    __atomic_store_n(&self->value, value, __ATOMIC_SEQ_CST);
}

generic<T>
void Atomic_store_order(struct Atomic<T>* self, T value, int order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_store_order(order);
    __atomic_store_n(&self->value, value, order);
}

generic<T>
T Atomic_exchange(struct Atomic<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    return __atomic_exchange_n(&self->value, value, __ATOMIC_SEQ_CST);
}

generic<T>
T Atomic_exchange_order(struct Atomic<T>* self, T value, int order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_rmw_order(order);
    return __atomic_exchange_n(&self->value, value, order);
}

generic<T>
int Atomic_compare_exchange(struct Atomic<T>* self, T expected, T desired)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    return __atomic_compare_exchange_n(&self->value, &expected, desired, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
}

generic<T>
int Atomic_compare_exchange_order(struct Atomic<T>* self, T expected, T desired, int success_order, int failure_order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_compare_orders(success_order, failure_order);
    return __atomic_compare_exchange_n(&self->value, &expected, desired, 0, success_order, failure_order);
}

generic<T>
T Atomic_fetch_add(struct Atomic<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    return __atomic_fetch_add(&self->value, value, __ATOMIC_SEQ_CST);
}

generic<T>
T Atomic_fetch_add_order(struct Atomic<T>* self, T value, int order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_rmw_order(order);
    return __atomic_fetch_add(&self->value, value, order);
}

generic<T>
T Atomic_fetch_sub(struct Atomic<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    return __atomic_fetch_sub(&self->value, value, __ATOMIC_SEQ_CST);
}

generic<T>
T Atomic_fetch_sub_order(struct Atomic<T>* self, T value, int order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_rmw_order(order);
    return __atomic_fetch_sub(&self->value, value, order);
}

generic<T>
T Atomic_fetch_or(struct Atomic<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    return __atomic_fetch_or(&self->value, value, __ATOMIC_SEQ_CST);
}

generic<T>
T Atomic_fetch_or_order(struct Atomic<T>* self, T value, int order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_rmw_order(order);
    return __atomic_fetch_or(&self->value, value, order);
}

generic<T>
T Atomic_fetch_and(struct Atomic<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    return __atomic_fetch_and(&self->value, value, __ATOMIC_SEQ_CST);
}

generic<T>
T Atomic_fetch_and_order(struct Atomic<T>* self, T value, int order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_rmw_order(order);
    return __atomic_fetch_and(&self->value, value, order);
}

generic<T>
T Atomic_fetch_xor(struct Atomic<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    return __atomic_fetch_xor(&self->value, value, __ATOMIC_SEQ_CST);
}

generic<T>
T Atomic_fetch_xor_order(struct Atomic<T>* self, T value, int order)
{
    if (self == NULL) {
        cminus_panic("atomic is null", __FILE__, __LINE__);
    }
    cminus_atomic_require_rmw_order(order);
    return __atomic_fetch_xor(&self->value, value, order);
}

#ifndef CMINUS_BARE_H
static __attribute__((unused)) void __cminus_thread_state_release(
    struct __CMinusThreadState* state)
{
    if (state != NULL &&
        __atomic_fetch_sub(&state->references, 1, __ATOMIC_ACQ_REL) == 1) {
        free(state);
    }
}

static __attribute__((unused)) void* __cminus_thread_entry(void* raw)
{
    struct __CMinusThreadState* state = (struct __CMinusThreadState*)raw;

    if (state->context_fn != NULL) {
        state->result = (*(state->context_fn))(state->context);
    }
    else {
        state->result = (*(state->fn))();
    }
    __cminus_thread_state_release(state);
    return NULL;
}

static __attribute__((unused)) struct Thread Thread_spawn(CMinusThreadMain fn)
{
    struct Thread out;
    pthread_t handle;
    int rc;

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
    out.state->references = 2;
    rc = pthread_create(&handle, NULL, __cminus_thread_entry, out.state);
    if (rc != 0) {
        free(out.state);
        cminus_panic("pthread_create failed", __FILE__, __LINE__);
    }
    memcpy(&out.handle_bits, &handle, sizeof(handle));
    out.started = 1;
    return out;
}

static __attribute__((unused)) struct Thread Thread_spawn_context(
    void* context, CMinusThreadContextMain fn)
{
    struct Thread out;
    pthread_t handle;
    int rc;

    if (context == NULL) {
        cminus_panic("thread context is null", __FILE__, __LINE__);
    }
    if (fn == NULL) {
        cminus_panic("thread context function is null", __FILE__, __LINE__);
    }
    if (sizeof(pthread_t) > sizeof(out.handle_bits)) {
        cminus_panic("pthread_t is too large", __FILE__, __LINE__);
    }
    memset(&out, 0, sizeof(out));
    out.state = (struct __CMinusThreadState*)calloc(1, sizeof(struct __CMinusThreadState));
    if (out.state == NULL) {
        cminus_panic("thread allocation failed", __FILE__, __LINE__);
    }
    out.state->context_fn = fn;
    out.state->context = context;
    out.state->references = 2;
    rc = pthread_create(&handle, NULL, __cminus_thread_entry, out.state);
    if (rc != 0) {
        free(out.state);
        cminus_panic("pthread_create failed", __FILE__, __LINE__);
    }
    memcpy(&out.handle_bits, &handle, sizeof(handle));
    out.started = 1;
    return out;
}

static __attribute__((unused)) int Thread_join(struct Thread* self)
{
    pthread_t handle;
    int rc;
    int result;
    int expected = 0;

    if (self == NULL || !self->started) {
        cminus_panic("thread is not started", __FILE__, __LINE__);
    }
    if (!__atomic_compare_exchange_n(&self->joined, &expected, 2, 0,
                                     __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        cminus_panic("thread is already joined or detached", __FILE__, __LINE__);
    }
    memset(&handle, 0, sizeof(handle));
    memcpy(&handle, &self->handle_bits, sizeof(handle));
    rc = pthread_join(handle, NULL);
    if (rc != 0) {
        cminus_panic("pthread_join failed", __FILE__, __LINE__);
    }
    result = self->state != NULL ? self->state->result : 0;
    __cminus_thread_state_release(self->state);
    self->state = NULL;
    __atomic_store_n(&self->joined, 1, __ATOMIC_RELEASE);
    return result;
}

static __attribute__((unused)) void Thread_detach(struct Thread* self)
{
    pthread_t handle;
    int rc;
    int expected = 0;

    if (self == NULL || !self->started) {
        cminus_panic("thread is not started", __FILE__, __LINE__);
    }
    if (!__atomic_compare_exchange_n(&self->joined, &expected, 2, 0,
                                     __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        cminus_panic("thread is already joined or detached", __FILE__, __LINE__);
    }
    memset(&handle, 0, sizeof(handle));
    memcpy(&handle, &self->handle_bits, sizeof(handle));
    rc = pthread_detach(handle);
    if (rc != 0) {
        cminus_panic("pthread_detach failed", __FILE__, __LINE__);
    }
    __cminus_thread_state_release(self->state);
    self->state = NULL;
    __atomic_store_n(&self->joined, 1, __ATOMIC_RELEASE);
}

static __attribute__((unused)) void Thread_yield(void)
{
    sched_yield();
}

static __attribute__((unused)) struct Mutex Mutex_init(void)
{
    struct Mutex out;

    memset(&out, 0, sizeof(out));
    out.native = (pthread_mutex_t*)calloc(1, sizeof(pthread_mutex_t));
    if (out.native == NULL) {
        cminus_panic("mutex allocation failed", __FILE__, __LINE__);
    }
    if (pthread_mutex_init(out.native, NULL) != 0) {
        free(out.native);
        cminus_panic("pthread_mutex_init failed", __FILE__, __LINE__);
    }
    out.initialized = 1;
    return out;
}

static __attribute__((unused)) void Mutex_lock(struct Mutex* self)
{
    if (self == NULL || !self->initialized || self->native == NULL) {
        cminus_panic("mutex is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_mutex_lock(self->native) != 0) {
        cminus_panic("pthread_mutex_lock failed", __FILE__, __LINE__);
    }
}

static __attribute__((unused)) void Mutex_unlock(struct Mutex* self)
{
    if (self == NULL || !self->initialized || self->native == NULL) {
        cminus_panic("mutex is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_mutex_unlock(self->native) != 0) {
        cminus_panic("pthread_mutex_unlock failed", __FILE__, __LINE__);
    }
}

static __attribute__((unused)) void Mutex_destroy(struct Mutex* self)
{
    if (self == NULL || !self->initialized) {
        return;
    }
    if (self->native == NULL) {
        cminus_panic("mutex is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_mutex_destroy(self->native) != 0) {
        cminus_panic("pthread_mutex_destroy failed", __FILE__, __LINE__);
    }
    free(self->native);
    self->native = NULL;
    self->initialized = 0;
}

static __attribute__((unused)) struct Cond Cond_init(void)
{
    struct Cond out;

    memset(&out, 0, sizeof(out));
    out.native = (pthread_cond_t*)calloc(1, sizeof(pthread_cond_t));
    if (out.native == NULL) {
        cminus_panic("condition variable allocation failed", __FILE__, __LINE__);
    }
    if (pthread_cond_init(out.native, NULL) != 0) {
        free(out.native);
        cminus_panic("pthread_cond_init failed", __FILE__, __LINE__);
    }
    out.initialized = 1;
    return out;
}

static __attribute__((unused)) void Cond_wait(struct Cond* self, struct Mutex* mutex)
{
    if (self == NULL || !self->initialized || self->native == NULL ||
        mutex == NULL || !mutex->initialized || mutex->native == NULL) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_cond_wait(self->native, mutex->native) != 0) {
        cminus_panic("pthread_cond_wait failed", __FILE__, __LINE__);
    }
}

static __attribute__((unused)) void Cond_signal(struct Cond* self)
{
    if (self == NULL || !self->initialized || self->native == NULL) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_cond_signal(self->native) != 0) {
        cminus_panic("pthread_cond_signal failed", __FILE__, __LINE__);
    }
}

static __attribute__((unused)) void Cond_broadcast(struct Cond* self)
{
    if (self == NULL || !self->initialized || self->native == NULL) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_cond_broadcast(self->native) != 0) {
        cminus_panic("pthread_cond_broadcast failed", __FILE__, __LINE__);
    }
}

static __attribute__((unused)) void Cond_destroy(struct Cond* self)
{
    if (self == NULL || !self->initialized) {
        return;
    }
    if (self->native == NULL) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_cond_destroy(self->native) != 0) {
        cminus_panic("pthread_cond_destroy failed", __FILE__, __LINE__);
    }
    free(self->native);
    self->native = NULL;
    self->initialized = 0;
}
#endif

generic<T>
struct Register<T> Register_from_addr(unsigned long addr)
{
    struct Register<T> out;

    out.addr = (volatile T*)addr;
    return out;
}

generic<T>
struct Volatile<T> Volatile_from_addr(unsigned long addr)
{
    struct Volatile<T> out;

    out.addr = (volatile T*)addr;
    return out;
}

generic<T>
int Volatile_is_null(struct Volatile<T>* self)
{
    return self == NULL || self->addr == NULL;
}

generic<T>
T Volatile_read(struct Volatile<T>* self)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("volatile reference is null", __FILE__, __LINE__);
    }
    return *self->addr;
}

generic<T>
void Volatile_write(struct Volatile<T>* self, T value)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("volatile reference is null", __FILE__, __LINE__);
    }
    *self->addr = value;
}

generic<T>
int Register_is_null(struct Register<T>* self)
{
    return self == NULL || self->addr == NULL;
}

generic<T>
T Register_read(struct Register<T>* self)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("register is null", __FILE__, __LINE__);
    }
    return *self->addr;
}

generic<T>
void Register_write(struct Register<T>* self, T value)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("register is null", __FILE__, __LINE__);
    }
    *self->addr = value;
}

generic<T>
void Register_set_bits(struct Register<T>* self, T mask)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("register is null", __FILE__, __LINE__);
    }
    *self->addr = *self->addr | mask;
}

generic<T>
void Register_clear_bits(struct Register<T>* self, T mask)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("register is null", __FILE__, __LINE__);
    }
    *self->addr = *self->addr & ~mask;
}

generic<T>
T Register_get_bits(struct Register<T>* self, T mask)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("register is null", __FILE__, __LINE__);
    }
    return *self->addr & mask;
}

generic<T>
int Register_has_bits(struct Register<T>* self, T mask)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("register is null", __FILE__, __LINE__);
    }
    return (*self->addr & mask) == mask;
}

generic<T>
void Register_replace_bits(struct Register<T>* self, T mask, T value)
{
    if (self == NULL || self->addr == NULL) {
        cminus_panic("register is null", __FILE__, __LINE__);
    }
    *self->addr = (*self->addr & ~mask) | (value & mask);
}

generic<T>
struct Span<T> Span_from(T* data, int len, int allow_raw = 0)
{
    struct Span<T> out;
    unsigned long stack_id = 0UL;

    out.data = data;
    out.len = len < 0 ? 0 : len;
    out.base = data;
    out.cap = out.len;
    out.base_bytes = (unsigned char*)data;
    out.cap_bytes = out.cap * (int)sizeof(T);
    if (allow_raw) {
        out.origin_kind = __CMinusPtrKind_Raw;
    } else {
        cminus_stack_note_caller_range(data, (size_t)out.cap_bytes);
        out.origin_kind = cminus_ptr_classify(data, &stack_id);
    }
    out.origin_stack_id = stack_id;
    return out;
}

generic<T>
struct Span<T> Span_map_from(void* data, int bytes, int len, int allow_raw = 0)
{
    struct Span<T> out;
    unsigned long stack_id = 0UL;
    unsigned long align = (unsigned long)__alignof__(T);
    unsigned long addr = (unsigned long)data;
    int need;

    if (len < 0 || bytes < 0) {
        cminus_panic("span map size is negative", __FILE__, __LINE__);
    }
    if (sizeof(T) == 0 || bytes % (int)sizeof(T) != 0) {
        cminus_panic("span map byte size is not aligned to element size", __FILE__, __LINE__);
    }
    need = len * (int)sizeof(T);
    if (len != 0 && need / len != (int)sizeof(T)) {
        cminus_panic("span map size overflow", __FILE__, __LINE__);
    }
    if (need > bytes) {
        cminus_panic("span map exceeds source buffer", __FILE__, __LINE__);
    }
    if (data != NULL && align > 1UL && addr % align != 0UL) {
        cminus_panic("span map address is not aligned to element type", __FILE__, __LINE__);
    }
    out.data = (T*)data;
    out.len = len;
    out.base = (T*)data;
    out.cap = bytes / (int)sizeof(T);
    out.base_bytes = (unsigned char*)data;
    out.cap_bytes = bytes;
    if (allow_raw) {
        out.origin_kind = __CMinusPtrKind_Raw;
    } else {
        cminus_stack_note_caller_range(data, (size_t)bytes);
        out.origin_kind = cminus_ptr_classify(data, &stack_id);
    }
    out.origin_stack_id = stack_id;
    return out;
}

generic<T>
struct Span<T> Span_from_bytes(T* data, int bytes, int allow_raw = 0)
{
    if (bytes < 0 || bytes % (int)sizeof(T) != 0) {
        cminus_panic("span byte size is not aligned to element size", __FILE__, __LINE__);
    }
    return Span<T>.from(data, bytes / (int)sizeof(T), allow_raw);
}

generic<T>
struct Span<T> Span_empty(void)
{
    struct Span<T> out;

    out.data = NULL;
    out.len = 0;
    out.base = NULL;
    out.cap = 0;
    out.base_bytes = NULL;
    out.cap_bytes = 0;
    out.origin_kind = 0UL;
    out.origin_stack_id = 0UL;
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
    if (self->data == NULL || self->base == NULL || index < 0 ||
        index >= self->len ||
        (unsigned char*)(self->data + index) < self->base_bytes ||
        (unsigned char*)(self->data + index + 1) > self->base_bytes + self->cap_bytes) {
        cminus_panic("index out of range", __FILE__, __LINE__);
    }
    return self->data[index];
}

generic<T>
int Span_set(struct Span<T>* self, int index, T value)
{
    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self->data == NULL || self->base == NULL || index < 0 ||
        index >= self->len ||
        (unsigned char*)(self->data + index) < self->base_bytes ||
        (unsigned char*)(self->data + index + 1) > self->base_bytes + self->cap_bytes) {
        cminus_panic("index out of range", __FILE__, __LINE__);
    }
    self->data[index] = value;
    return 1;
}

generic<T>
void Span_fill(struct Span<T>* self, T value)
{
    int i = 0;

    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    while (i < self->len) {
        Span<T>.set(self, i, value);
        i++;
    }
}

generic<T>
struct __CMinusIndex<T> Span_get_opt(struct Span<T>* self, int index)
{
    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self == NULL || self->data == NULL || self->base == NULL || index < 0 ||
        index >= self->len ||
        (unsigned char*)(self->data + index) < self->base_bytes ||
        (unsigned char*)(self->data + index + 1) > self->base_bytes + self->cap_bytes) {
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
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, file, line);
    if (self == NULL || self->data == NULL || self->base == NULL || index < 0 ||
        index >= self->len ||
        (unsigned char*)(self->data + index) < self->base_bytes ||
        (unsigned char*)(self->data + index + 1) > self->base_bytes + self->cap_bytes) {
        cminus_panic("index out of range", file, line);
    }
    return self->data + index;
}

generic<T>
struct Span<T> Span_offset(struct Span<T>* self, int offset, const char* file, int line)
{
    struct Span<T> out;

    if (self == NULL) {
        cminus_panic("dangling reference", file, line);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self == NULL || self->data == NULL || self->base == NULL) {
        cminus_panic("span offset out of range", file, line);
    }
    if (offset >= 0) {
        if (offset > self->len ||
            (unsigned char*)(self->data + offset) > self->base_bytes + self->cap_bytes) {
            cminus_panic("span offset out of range", file, line);
        }
    } else {
        if ((unsigned char*)(self->data + offset) < self->base_bytes) {
            cminus_panic("span offset out of range", file, line);
        }
    }
    out.data = self->data + offset;
    out.len = self->len - offset;
    out.base = self->base;
    out.cap = self->cap;
    out.base_bytes = self->base_bytes;
    out.cap_bytes = self->cap_bytes;
    out.origin_kind = self->origin_kind;
    out.origin_stack_id = self->origin_stack_id;
    return out;
}

generic<T>
struct Span<T> Span_slice(struct Span<T>* self, int start, int len)
{
    struct Span<T> out;

    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self->data == NULL || self->base == NULL || start < 0 || len < 0 ||
        start > self->len || len > self->len - start ||
        (unsigned char*)(self->data + start) < self->base_bytes ||
        (unsigned char*)(self->data + start + len) > self->base_bytes + self->cap_bytes) {
        cminus_panic("span slice out of range", __FILE__, __LINE__);
    }
    out.data = self->data + start;
    out.len = len;
    out.base = self->base;
    out.cap = self->cap;
    out.base_bytes = self->base_bytes;
    out.cap_bytes = self->cap_bytes;
    out.origin_kind = self->origin_kind;
    out.origin_stack_id = self->origin_stack_id;
    return out;
}

generic<T>
int Span_copy_from_count(struct Span<T>* self, struct Span<T> src, int count)
{
    int i = 0;

    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    cminus_ptr_require_alive(src.data, src.origin_kind, src.origin_stack_id, __FILE__, __LINE__);
    if (count < 0 || count > self->len || count > src.len) {
        cminus_panic("span copy out of range", __FILE__, __LINE__);
    }
    while (i < count) {
        Span<T>.set(self, i, Span<T>.get(&src, i));
        i++;
    }
    return count;
}

generic<T>
int Span_copy_from(struct Span<T>* self, struct Span<T> src)
{
    int count;

    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    count = self->len < src.len ? self->len : src.len;
    return Span<T>.copy_from_count(self, src, count);
}

generic<T>
int Span_cstr_len(struct Span<T>* self)
{
    int i = 0;

    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    while (i < self->len) {
        if (Span<T>.get(self, i) == 0) {
            return i;
        }
        i++;
    }
    return self->len;
}

generic<T>
int Span_cstr_eq(struct Span<T>* self, struct Span<T> other)
{
    int i = 0;
    T left;
    T right;

    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    cminus_ptr_require_alive(other.data, other.origin_kind, other.origin_stack_id, __FILE__, __LINE__);
    while (i < self->len && i < other.len) {
        left = Span<T>.get(self, i);
        right = Span<T>.get(&other, i);
        if (left != right) {
            return 0;
        }
        if (left == 0) {
            return 1;
        }
        i++;
    }
    return 0;
}

generic<T>
int Span_copy_cstr_from(struct Span<T>* self, struct Span<T> src)
{
    int i = 0;
    T value;

    if (self == NULL) {
        cminus_panic("dangling reference", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    cminus_ptr_require_alive(src.data, src.origin_kind, src.origin_stack_id, __FILE__, __LINE__);
    if (self->len <= 0) {
        return 0;
    }
    while (i + 1 < self->len && i < src.len) {
        value = Span<T>.get(&src, i);
        Span<T>.set(self, i, value);
        if (value == 0) {
            return i;
        }
        i++;
    }
    Span<T>.set(self, i, 0);
    return i;
}

generic<T>
struct FixedVec {
    T* data;
    int len;
    int cap;
    T* base;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};

generic<T>
struct FixedVec<T> FixedVec_from(T* data, int cap, int allow_raw = 0)
{
    struct FixedVec<T> out;
    unsigned long stack_id = 0UL;

    out.data = data;
    out.len = 0;
    out.cap = cap < 0 ? 0 : cap;
    out.base = data;
    if (allow_raw) {
        out.origin_kind = __CMinusPtrKind_Raw;
    } else {
        cminus_stack_note_caller_range(data, (size_t)out.cap * sizeof(T));
        out.origin_kind = cminus_ptr_classify(data, &stack_id);
    }
    out.origin_stack_id = stack_id;
    return out;
}

generic<T>
struct FixedVec<T> FixedVec_from_bytes(T* data, int bytes, int allow_raw = 0)
{
    if (bytes < 0 || bytes % (int)sizeof(T) != 0) {
        cminus_panic("fixed vec byte size is not aligned to element size", __FILE__, __LINE__);
    }
    return FixedVec<T>.from(data, bytes / (int)sizeof(T), allow_raw);
}

generic<T>
int FixedVec_len(struct FixedVec<T>* self)
{
    if (self == NULL) {
        return 0;
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return self->len;
}

generic<T>
int FixedVec_capacity(struct FixedVec<T>* self)
{
    if (self == NULL) {
        return 0;
    }
    return self->cap;
}

generic<T>
int FixedVec_is_empty(struct FixedVec<T>* self)
{
    return self == NULL || self->len == 0;
}

generic<T>
int FixedVec_is_full(struct FixedVec<T>* self)
{
    return self == NULL || self->len >= self->cap;
}

generic<T>
void FixedVec_clear(struct FixedVec<T>* self)
{
    if (self != NULL) {
        self->len = 0;
    }
}

generic<T>
int FixedVec_push(struct FixedVec<T>* self, T value)
{
    if (self == NULL) {
        cminus_panic("fixed vec is null", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self->data == NULL || self->len < 0 || self->len >= self->cap) {
        cminus_panic("fixed vec is full", __FILE__, __LINE__);
    }
    self->data[self->len] = value;
    self->len = cminus_checked_int_add(self->len, 1);
    return 1;
}

generic<T>
struct __CMinusIndex<T> FixedVec_pop_opt(struct FixedVec<T>* self)
{
    if (self == NULL || self->len <= 0) {
        return new __CMinusIndex<T>.None();
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    self->len--;
    return new __CMinusIndex<T>.Some(self->data[self->len]);
}

generic<T>
T FixedVec_get(struct FixedVec<T>* self, int index)
{
    if (self == NULL) {
        cminus_panic("fixed vec is null", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (index < 0 || index >= self->len) {
        cminus_panic("index out of range", __FILE__, __LINE__);
    }
    return self->data[index];
}

generic<T>
int FixedVec_set(struct FixedVec<T>* self, int index, T value)
{
    if (self == NULL) {
        cminus_panic("fixed vec is null", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (index < 0 || index >= self->len) {
        return 0;
    }
    self->data[index] = value;
    return 1;
}

generic<T>
struct __CMinusIndex<T> FixedVec_get_opt(struct FixedVec<T>* self, int index)
{
    if (self == NULL || index < 0 || index >= self->len) {
        return new __CMinusIndex<T>.None();
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return new __CMinusIndex<T>.Some(self->data[index]);
}

generic<T>
struct Span<T> FixedVec_as_span(struct FixedVec<T>* self)
{
    if (self == NULL) {
        return Span_empty<T>();
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return Span_from<T>(self->data, self->len);
}

generic<T>
struct RingBuffer {
    T* data;
    int cap;
    int head;
    int len;
    T* base;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};

generic<T>
struct RingBuffer<T> RingBuffer_from(T* data, int cap, int allow_raw = 0)
{
    struct RingBuffer<T> out;
    unsigned long stack_id = 0UL;

    out.data = data;
    out.cap = cap < 0 ? 0 : cap;
    out.head = 0;
    out.len = 0;
    out.base = data;
    if (allow_raw) {
        out.origin_kind = __CMinusPtrKind_Raw;
    } else {
        cminus_stack_note_caller_range(data, (size_t)out.cap * sizeof(T));
        out.origin_kind = cminus_ptr_classify(data, &stack_id);
    }
    out.origin_stack_id = stack_id;
    return out;
}

generic<T>
struct RingBuffer<T> RingBuffer_from_bytes(T* data, int bytes, int allow_raw = 0)
{
    if (bytes < 0 || bytes % (int)sizeof(T) != 0) {
        cminus_panic("ring buffer byte size is not aligned to element size", __FILE__, __LINE__);
    }
    return RingBuffer<T>.from(data, bytes / (int)sizeof(T), allow_raw);
}

generic<T>
int RingBuffer_len(struct RingBuffer<T>* self)
{
    if (self == NULL) {
        return 0;
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    return self->len;
}

generic<T>
int RingBuffer_capacity(struct RingBuffer<T>* self)
{
    if (self == NULL) {
        return 0;
    }
    return self->cap;
}

generic<T>
int RingBuffer_is_empty(struct RingBuffer<T>* self)
{
    return self == NULL || self->len == 0;
}

generic<T>
int RingBuffer_is_full(struct RingBuffer<T>* self)
{
    return self != NULL && self->len >= self->cap;
}

generic<T>
void RingBuffer_clear(struct RingBuffer<T>* self)
{
    if (self != NULL) {
        self->head = 0;
        self->len = 0;
    }
}

generic<T>
int RingBuffer_push(struct RingBuffer<T>* self, T value)
{
    int tail;

    if (self == NULL) {
        cminus_panic("ring buffer is null", __FILE__, __LINE__);
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self->data == NULL || self->base == NULL || self->cap <= 0 || self->len < 0 || self->len >= self->cap) {
        cminus_panic("ring buffer is full", __FILE__, __LINE__);
    }
    tail = (self->head + self->len) % self->cap;
    self->data[tail] = value;
    self->len = cminus_checked_int_add(self->len, 1);
    return 1;
}

generic<T>
struct __CMinusIndex<T> RingBuffer_pop_opt(struct RingBuffer<T>* self)
{
    T value;

    if (self == NULL || self->len <= 0) {
        return new __CMinusIndex<T>.None();
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self->data == NULL || self->base == NULL || self->cap <= 0 || self->head < 0 || self->head >= self->cap) {
        cminus_panic("ring buffer is invalid", __FILE__, __LINE__);
    }
    value = self->data[self->head];
    self->head = (self->head + 1) % self->cap;
    self->len--;
    if (self->len == 0) {
        self->head = 0;
    }
    return new __CMinusIndex<T>.Some(value);
}

generic<T>
struct __CMinusIndex<T> RingBuffer_peek_opt(struct RingBuffer<T>* self)
{
    if (self == NULL || self->len <= 0) {
        return new __CMinusIndex<T>.None();
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    if (self->data == NULL || self->base == NULL || self->cap <= 0 || self->head < 0 || self->head >= self->cap) {
        cminus_panic("ring buffer is invalid", __FILE__, __LINE__);
    }
    return new __CMinusIndex<T>.Some(self->data[self->head]);
}

generic<T>
struct Span<T> RingBuffer_drain_to_span(struct RingBuffer<T>* self, T* out, int cap)
{
    struct Span<T> span;
    int count;
    int i;
    int index;

    if (self == NULL) {
        return Span_empty<T>();
    }
    cminus_ptr_require_alive(self->data, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    count = self->len;
    if (count > cap) {
        count = cap;
    }
    span = Span_from<T>(out, count);
    i = 0;
    while (i < count) {
        index = (self->head + i) % self->cap;
        Span_set<T>(&span, i, self->data[index]);
        i++;
    }
    self->head = (self->head + count) % self->cap;
    self->len -= count;
    if (self->len == 0) {
        self->head = 0;
    }
    return span;
}

struct Bitmap {
    unsigned long* words;
    int bits;
    int words_len;
    unsigned long origin_kind;
    unsigned long origin_stack_id;
};
typedef struct Bitmap Bitmap;

static __attribute__((unused)) int Bitmap_bits_per_word(void)
{
    return (int)(sizeof(unsigned long) * 8);
}

static __attribute__((unused)) int Bitmap_word_shift(void)
{
    return sizeof(unsigned long) == 8 ? 6 : 5;
}

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

static __attribute__((unused)) struct Bitmap Bitmap_from_impl(unsigned long* words, int bits, int allow_raw)
{
    struct Bitmap out;
    unsigned long stack_id;
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
    struct Bitmap out;
    unsigned long stack_id;
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

static __attribute__((unused)) struct __CMinusIndex<int> Bitmap_find_zero(struct Bitmap* self)
{
    int i = 0;

    if (self == NULL || self->words == NULL) {
        return new __CMinusIndex<int>.None();
    }
    cminus_ptr_require_alive(self->words, self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);
    while (i < self->bits) {
        if (!Bitmap_test(self, i)) {
            return new __CMinusIndex<int>.Some(i);
        }
        i++;
    }
    return new __CMinusIndex<int>.None();
}

static __attribute__((unused)) struct __CMinusIndex<int> Bitmap_alloc_opt(struct Bitmap* self)
{
    struct __CMinusIndex<int> slot = Bitmap_find_zero(self);

    if (slot.is_Some()) {
        Bitmap_set(self, slot.get_Some());
    }
    return slot;
}

static __attribute__((unused)) void Bitmap_free_bit(struct Bitmap* self, int index)
{
    Bitmap_clear_bit(self, index);
}

generic<T>
struct Vec {
    T* data;
    int len;
    int cap;
};

generic<T>
struct VecIterator {
    struct Vec<T>* vec;
    int index;
};

generic<T>
struct Vec<T>* Vec_new(void)
{
    return cminus_gc_calloc(1, sizeof(struct Vec<T>));
}

generic<T>
void Vec_push(struct Vec<T>* self, T value)
{
    T* next;
    int next_cap = self->cap == 0 ? 4 : cminus_checked_int_mul(self->cap, 2);

    if (self->len >= self->cap) {
        next = cminus_gc_calloc(next_cap, sizeof(T));
        if (next == NULL) {
            abort();
        }
        if (self->data != NULL && self->len > 0) {
            memcpy(next, self->data, sizeof(T) * self->len);
            cminus_gc_free(self->data);
        }
        self->data = next;
        self->cap = next_cap;
    }
    self->data[self->len] = value;
    self->len = cminus_checked_int_add(self->len, 1);
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
    next = cminus_gc_calloc(cap, sizeof(T));
    if (next == NULL) {
        return 0;
    }
    if (self->data != NULL && self->len > 0) {
        memcpy(next, self->data, sizeof(T) * self->len);
        cminus_gc_free(self->data);
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
        cminus_gc_free(self->data);
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
struct Span<T> Vec_as_span(struct Vec<T>* self)
{
    if (self == NULL) {
        return Span_empty<T>();
    }
    return Span_from<T>(self->data, self->len);
}

generic<T>
struct __CMinusIndex<T> VecIterator_next(struct VecIterator<T>* self)
{
    T value;

    if (self == NULL || self->vec == NULL) {
        return new __CMinusIndex<T>.None();
    }
    if (self->index >= self->vec->len) {
        return new __CMinusIndex<T>.None();
    }
    value = self->vec->data[self->index];
    self->index++;
    return new __CMinusIndex<T>.Some(value);
}

generic<T>
struct Iterator<T>* Vec_iter(struct Vec<T>* self)
{
    struct VecIterator<T>* state = cminus_gc_calloc(1, sizeof(struct VecIterator<T>));

    state->vec = self;
    state->index = 0;
    return Iterator_new<T>(state, (struct __CMinusIndex<T> (*)(void*))VecIterator_next<T>);
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
struct ListIterator {
    struct ListNode<T>* node;
};

generic<T>
struct List<T>* List_new(void)
{
    return cminus_gc_calloc(1, sizeof(struct List<T>));
}

generic<T>
void List_push(struct List<T>* self, T value)
{
    struct ListNode<T>* node = cminus_gc_calloc(1, sizeof(struct ListNode<T>));

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
    self->len = cminus_checked_int_add(self->len, 1);
}

generic<T>
void List_push_front(struct List<T>* self, T value)
{
    struct ListNode<T>* node = cminus_gc_calloc(1, sizeof(struct ListNode<T>));

    if (node == NULL) {
        abort();
    }
    node->value = value;
    node->next = self->head;
    self->head = node;
    if (self->tail == NULL) {
        self->tail = node;
    }
    self->len = cminus_checked_int_add(self->len, 1);
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
    node = cminus_gc_calloc(1, sizeof(struct ListNode<T>));
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
        cminus_gc_free(node);
        return 0;
    }
    node->next = prev->next;
    prev->next = node;
    self->len = cminus_checked_int_add(self->len, 1);
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
        cminus_gc_free(node);
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
    cminus_gc_free(node);
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
    cminus_gc_free(node);
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
        cminus_gc_free(node);
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
struct Span<T> List_to_span(struct List<T>* self, T* out, int cap)
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
struct __CMinusIndex<T> ListIterator_next(struct ListIterator<T>* self)
{
    T value;

    if (self == NULL || self->node == NULL) {
        return new __CMinusIndex<T>.None();
    }
    value = self->node->value;
    self->node = self->node->next;
    return new __CMinusIndex<T>.Some(value);
}

generic<T>
struct Iterator<T>* List_iter(struct List<T>* self)
{
    struct ListIterator<T>* state = cminus_gc_calloc(1, sizeof(struct ListIterator<T>));

    state->node = self == NULL ? NULL : self->head;
    return Iterator_new<T>(state, (struct __CMinusIndex<T> (*)(void*))ListIterator_next<T>);
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
    return cminus_gc_calloc(1, sizeof(struct Map<K,V>));
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
    if (self->cap == 0 || cminus_checked_int_mul(cminus_checked_int_add(self->len, 1), 3) >= cminus_checked_int_mul(self->cap, 2)) {
        K* old_keys = self->keys;
        V* old_values = self->values;
        int* old_states = self->states;
        int old_cap = self->cap;
        int next_cap = old_cap == 0 ? 16 : cminus_checked_int_mul(old_cap, 2);
        K* next_keys = cminus_gc_calloc(next_cap, sizeof(K));
        V* next_values = cminus_gc_calloc(next_cap, sizeof(V));
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
    self->len = cminus_checked_int_add(self->len, 1);
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
    cminus_gc_free(self->keys);
    cminus_gc_free(self->values);
    cminus_gc_free(self->states);
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
        cminus_gc_free(self->keys);
        cminus_gc_free(self->values);
        cminus_gc_free(self->states);
    }
}

generic<K,V>
struct Span<K> Map_keys_to_span(struct Map<K,V>* self, K* out, int cap)
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
struct Span<V> Map_values_to_span(struct Map<K,V>* self, V* out, int cap)
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
    return cminus_gc_calloc(1, sizeof(struct OwnedVec<T>));
}

generic<T>
void OwnedVec_push(struct OwnedVec<T>* self, T value)
{
    T* next;
    int next_cap = self->cap == 0 ? 4 : cminus_checked_int_mul(self->cap, 2);

    if (self->len >= self->cap) {
        next = cminus_gc_calloc(next_cap, sizeof(T));
        if (next == NULL) {
            abort();
        }
        if (self->data != NULL && self->len > 0) {
            memcpy(next, self->data, sizeof(T) * self->len);
            cminus_gc_free(self->data);
        }
        self->data = next;
        self->cap = next_cap;
    }
    self->data[self->len] = value;
    self->len = cminus_checked_int_add(self->len, 1);
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
        cminus_gc_free(self->data[i]);
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
        cminus_gc_free(self->data);
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
    cminus_gc_free(self->data[index]);
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
    return cminus_gc_calloc(1, sizeof(struct OwnedList<T>));
}

generic<T>
void OwnedList_push(struct OwnedList<T>* self, T value)
{
    T* next;
    int next_cap = self->cap == 0 ? 4 : cminus_checked_int_mul(self->cap, 2);

    if (self->len >= self->cap) {
        next = cminus_gc_calloc(next_cap, sizeof(T));
        if (next == NULL) {
            abort();
        }
        if (self->data != NULL && self->len > 0) {
            memcpy(next, self->data, sizeof(T) * self->len);
            cminus_gc_free(self->data);
        }
        self->data = next;
        self->cap = next_cap;
    }
    self->data[self->len] = value;
    self->len = cminus_checked_int_add(self->len, 1);
}

generic<T>
void OwnedList_push_front(struct OwnedList<T>* self, T value)
{
    T* next;
    int next_cap = self->cap == 0 ? 4 : cminus_checked_int_mul(self->cap, 2);
    int i;

    if (self->len >= self->cap) {
        next = cminus_gc_calloc(next_cap, sizeof(T));
        if (next == NULL) {
            abort();
        }
        if (self->data != NULL && self->len > 0) {
            memcpy(next, self->data, sizeof(T) * self->len);
            cminus_gc_free(self->data);
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
    self->len = cminus_checked_int_add(self->len, 1);
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
        cminus_gc_free(self->data[i]);
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
        cminus_gc_free(self->data);
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
    cminus_gc_free(self->data[index]);
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
    return cminus_gc_calloc(1, sizeof(struct OwnedMap<K,V>));
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
    if (self->cap == 0 || cminus_checked_int_mul(cminus_checked_int_add(self->len, 1), 3) >= cminus_checked_int_mul(self->cap, 2)) {
        K* old_keys = self->keys;
        V* old_values = self->values;
        int* old_states = self->states;
        int old_cap = self->cap;
        int next_cap = old_cap == 0 ? 16 : cminus_checked_int_mul(old_cap, 2);
        K* next_keys = cminus_gc_calloc(next_cap, sizeof(K));
        V* next_values = cminus_gc_calloc(next_cap, sizeof(V));
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
    while (i < (int)sizeof(K)) {
        hash ^= bytes[i];
        hash *= 1099511628211UL;
        i++;
    }
    slot = hash - (hash / self->cap) * self->cap;
    while (self->states[slot] != 0) {
        if (self->states[slot] == 1 &&
            memcmp(&self->keys[slot], &key, sizeof(K)) == 0) {
            cminus_gc_free(self->values[slot]);
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
    self->len = cminus_checked_int_add(self->len, 1);
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
            cminus_gc_free(self->values[slot]);
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
            cminus_gc_free(self->values[i]);
        }
        i++;
    }
    cminus_gc_free(self->keys);
    cminus_gc_free(self->values);
    cminus_gc_free(self->states);
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
            cminus_gc_free(self->values[i]);
        }
        i++;
    }
    cminus_gc_free(self->keys);
    cminus_gc_free(self->values);
    cminus_gc_free(self->states);
}
