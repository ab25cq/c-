void cminus_panic(const char* message, const char* file, int line);
int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
void* cminus_gc_calloc_impl(unsigned long count, unsigned long size, const char* file, int line);

#define cminus_gc_calloc(count, size) cminus_gc_calloc_impl((count), (size), __FILE__, __LINE__)
#define cminus_gc_free(mem) cminus_gc_free_impl((mem), __FILE__, __LINE__)
/*
 * c- bare-metal runtime.
 *
 * A tiny freestanding C library that lets `c-` output run with no libc. It
 * implements exactly the libc surface the generated C uses (memory, a few
 * string helpers, printf-family, abort) on top of a single board primitive:
 *
 *     int putchar(int c);
 *
 * This header has two faces, selected by CMINUS_BARE_IMPL:
 *
 *   - Without it (the default) only declarations are visible. `c- -bare`
 *     inlines this into each program source, so the compiler sees printf etc.
 *     as ordinary libc declarations and can fold e.g. printf("...\n") into
 *     puts(), dropping the format engine when it is unused.
 *   - With it, the definitions appear too. The runtime is compiled exactly once
 *     into a separate object (cpm does this automatically; see README) and
 *     linked in. Keeping the definitions out of the program translation units
 *     is what makes those libcall optimizations legal.
 *
 * Heap is a fixed static buffer; override with -DCMINUS_BARE_HEAP_SIZE=<bytes>.
 */
#ifndef CMINUS_BARE_H
#define CMINUS_BARE_H

/* ----------------------------------------------------------------------- */
/* declarations (visible to every translation unit)                        */
/* ----------------------------------------------------------------------- */

typedef __SIZE_TYPE__ size_t;
typedef __PTRDIFF_TYPE__ ptrdiff_t;
typedef __builtin_va_list va_list;
#define va_start(ap, last) __builtin_va_start(ap, last)
#define va_arg(ap, type)   __builtin_va_arg(ap, type)
#define va_end(ap)         __builtin_va_end(ap)
#define va_copy(dst, src)  __builtin_va_copy(dst, src)

#ifndef NULL
#define NULL ((void*)0)
#endif

/* The board provides this; it is the only required external symbol. */
extern int putchar(int c);

/*
 * A FILE is only a stream id here. cminus_panic writes to stderr; both streams
 * end up at putchar on a board with a single console.
 */
typedef struct cminus_bare_file { int fd; } FILE;
extern FILE __cminus_bare_stdout;
extern FILE __cminus_bare_stderr;
#define stdout (&__cminus_bare_stdout)
#define stderr (&__cminus_bare_stderr)

#ifndef CMINUS_BARE_HEAP_SIZE
#define CMINUS_BARE_HEAP_SIZE (64u * 1024u)
#endif

extern void* memset(void* dst, int value, size_t count);
extern void* memcpy(void* dst, const void* src, size_t count);
extern void* memmove(void* dst, const void* src, size_t count);
extern int memcmp(const void* a, const void* b, size_t count);
extern void* malloc(size_t size);
extern void free(void* ptr);
extern void* calloc(size_t count, size_t size);
extern void* realloc(void* ptr, size_t size);
extern size_t strlen(const char* s);
extern int strcmp(const char* a, const char* b);
extern char* strncpy(char* dst, const char* src, size_t count);
extern char* strdup(const char* src);
extern int printf(const char* fmt, ...);
extern int fprintf(FILE* stream, const char* fmt, ...);
extern FILE* fopen(const char* path, const char* mode);
extern int puts(const char* s);
extern int asprintf(char** out, const char* fmt, ...);
extern int backtrace(void** buffer, int size);
extern void backtrace_symbols_fd(void* const* buffer, int size, int fd);
extern void abort(void);
extern void exit(int status);

/* ----------------------------------------------------------------------- */
/* definitions (compiled once into the runtime object)                     */
/* ----------------------------------------------------------------------- */
#ifdef CMINUS_BARE_IMPL

/*
 * weak: the board may override putchar (and _start), and the compiler may emit
 * its own mem* calls that these satisfy.
 */
#define CMINUS_BARE_API __attribute__((weak))

__attribute__((weak)) FILE __cminus_bare_stdout = { 1 };
__attribute__((weak)) FILE __cminus_bare_stderr = { 2 };

/*
 * On a hosted Linux target, write/exit syscalls let the runtime provide a
 * default putchar/_start and a single-write puts with no board code. Real
 * freestanding targets (no __linux__/known arch) get none of this and supply
 * their own putchar (and startup).
 */
#if defined(__linux__)
#if defined(__x86_64__)
static __attribute__((unused)) long cminus_bare_sys_write(long fd, const void* buf, unsigned long n)
{
    long ret;
    __asm__ volatile("syscall" : "=a"(ret)
                     : "a"(1L), "D"(fd), "S"(buf), "d"(n)
                     : "rcx", "r11", "memory");
    return ret;
}
static __attribute__((unused)) void cminus_bare_sys_exit(long code)
{
    __asm__ volatile("syscall" : : "a"(60L), "D"(code) : "memory");
    __builtin_unreachable();
}
#define CMINUS_BARE_HAVE_SYSCALLS 1
#elif defined(__aarch64__)
static __attribute__((unused)) long cminus_bare_sys_write(long fd, const void* buf, unsigned long n)
{
    register long x0 __asm__("x0") = fd;
    register long x1 __asm__("x1") = (long)buf;
    register long x2 __asm__("x2") = (long)n;
    register long x8 __asm__("x8") = 64;
    __asm__ volatile("svc #0" : "+r"(x0) : "r"(x1), "r"(x2), "r"(x8) : "memory");
    return x0;
}
static __attribute__((unused)) void cminus_bare_sys_exit(long code)
{
    register long x0 __asm__("x0") = code;
    register long x8 __asm__("x8") = 93;
    __asm__ volatile("svc #0" : : "r"(x0), "r"(x8) : "memory");
    __builtin_unreachable();
}
#define CMINUS_BARE_HAVE_SYSCALLS 1
#elif defined(__riscv) && (__riscv_xlen == 64)
static __attribute__((unused)) long cminus_bare_sys_write(long fd, const void* buf, unsigned long n)
{
    register long a0 __asm__("a0") = fd;
    register long a1 __asm__("a1") = (long)buf;
    register long a2 __asm__("a2") = (long)n;
    register long a7 __asm__("a7") = 64;
    __asm__ volatile("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a7) : "memory");
    return a0;
}
static __attribute__((unused)) void cminus_bare_sys_exit(long code)
{
    register long a0 __asm__("a0") = code;
    register long a7 __asm__("a7") = 93;
    __asm__ volatile("ecall" : : "r"(a0), "r"(a7) : "memory");
    __builtin_unreachable();
}
#define CMINUS_BARE_HAVE_SYSCALLS 1
#elif defined(__arm__)
static __attribute__((unused)) long cminus_bare_sys_write(long fd, const void* buf, unsigned long n)
{
    register long r0 __asm__("r0") = fd;
    register long r1 __asm__("r1") = (long)buf;
    register long r2 __asm__("r2") = (long)n;
    register long r7 __asm__("r7") = 4;
    __asm__ volatile("svc #0" : "+r"(r0) : "r"(r1), "r"(r2), "r"(r7) : "memory");
    return r0;
}
static __attribute__((unused)) void cminus_bare_sys_exit(long code)
{
    register long r0 __asm__("r0") = code;
    register long r7 __asm__("r7") = 1;
    __asm__ volatile("svc #0" : : "r"(r0), "r"(r7) : "memory");
    __builtin_unreachable();
}
#define CMINUS_BARE_HAVE_SYSCALLS 1
#endif
#endif /* __linux__ */

/* memory -------------------------------------------------------------- */

CMINUS_BARE_API void* memset(void* dst, int value, size_t count)
{
    unsigned char* p = (unsigned char*)dst;
    while (count-- > 0) {
        *p++ = (unsigned char)value;
    }
    return dst;
}

CMINUS_BARE_API void* memcpy(void* dst, const void* src, size_t count)
{
    unsigned char* d = (unsigned char*)dst;
    const unsigned char* s = (const unsigned char*)src;
    while (count-- > 0) {
        *d++ = *s++;
    }
    return dst;
}

CMINUS_BARE_API void* memmove(void* dst, const void* src, size_t count)
{
    unsigned char* d = (unsigned char*)dst;
    const unsigned char* s = (const unsigned char*)src;
    if (d == s || count == 0) {
        return dst;
    }
    if (d < s) {
        while (count-- > 0) {
            *d++ = *s++;
        }
    } else {
        d += count;
        s += count;
        while (count-- > 0) {
            *--d = *--s;
        }
    }
    return dst;
}

CMINUS_BARE_API int memcmp(const void* a, const void* b, size_t count)
{
    const unsigned char* pa = (const unsigned char*)a;
    const unsigned char* pb = (const unsigned char*)b;
    while (count-- > 0) {
        if (*pa != *pb) {
            return (int)*pa - (int)*pb;
        }
        pa++;
        pb++;
    }
    return 0;
}

/*
 * Bump allocator over one static buffer. Each block carries an 8-byte size
 * header so realloc knows how much to copy. free is a no-op; this is meant for
 * small, mostly-static microcontroller programs, not long-running churn.
 */
static unsigned char cminus_bare_heap[CMINUS_BARE_HEAP_SIZE];
static size_t cminus_bare_heap_used = 0;

static size_t cminus_bare_align_up(size_t n)
{
    return (n + 7u) & ~(size_t)7u;
}

CMINUS_BARE_API void* malloc(size_t size)
{
    size_t header = 8u;
    size_t need = cminus_bare_align_up(size);
    size_t offset = cminus_bare_heap_used;
    unsigned char* block;

    if (offset + header + need > CMINUS_BARE_HEAP_SIZE) {
        return NULL;
    }
    block = cminus_bare_heap + offset;
    *(size_t*)block = size;
    cminus_bare_heap_used = offset + header + need;
    return block + header;
}

CMINUS_BARE_API void free(void* ptr)
{
    (void)ptr;
}

CMINUS_BARE_API void* calloc(size_t count, size_t size)
{
    size_t total = count * size;
    void* p;

    if (size != 0 && total / size != count) {
        return NULL;
    }
    p = malloc(total);
    if (p != NULL) {
        memset(p, 0, total);
    }
    return p;
}

CMINUS_BARE_API void* realloc(void* ptr, size_t size)
{
    void* next;
    size_t old;

    if (ptr == NULL) {
        return malloc(size);
    }
    old = *((size_t*)ptr - 1);
    if (size <= old) {
        return ptr;
    }
    next = malloc(size);
    if (next == NULL) {
        return NULL;
    }
    memcpy(next, ptr, old);
    return next;
}

/* strings ------------------------------------------------------------- */

CMINUS_BARE_API size_t strlen(const char* s)
{
    const char* p = s;
    while (*p != '\0') {
        p++;
    }
    return (size_t)(p - s);
}

CMINUS_BARE_API int strcmp(const char* a, const char* b)
{
    while (*a != '\0' && *a == *b) {
        a++;
        b++;
    }
    return (int)(unsigned char)*a - (int)(unsigned char)*b;
}

CMINUS_BARE_API char* strncpy(char* dst, const char* src, size_t count)
{
    size_t i = 0;
    while (i < count && src[i] != '\0') {
        dst[i] = src[i];
        i++;
    }
    while (i < count) {
        dst[i] = '\0';
        i++;
    }
    return dst;
}

CMINUS_BARE_API char* strdup(const char* src)
{
    size_t len = strlen(src);
    char* copy = (char*)malloc(len + 1);
    if (copy == NULL) {
        return NULL;
    }
    memcpy(copy, src, len + 1);
    return copy;
}

/* formatted output, routed through putchar ---------------------------- */

struct cminus_bare_sink {
    char* buf;    /* destination buffer when in buffer mode */
    size_t cap;   /* capacity of buf including space for terminator */
    size_t len;   /* count of characters formatted (excludes terminator) */
    int console;  /* nonzero: emit through putchar; zero: buffer or measure */
};

static void cminus_bare_put(struct cminus_bare_sink* sink, char c)
{
    if (sink->console) {
        putchar((int)(unsigned char)c);
    } else if (sink->buf != NULL && sink->len + 1 < sink->cap) {
        sink->buf[sink->len] = c;
    }
    sink->len++;
}

static void cminus_bare_pad(struct cminus_bare_sink* sink, char pad, int count)
{
    while (count-- > 0) {
        cminus_bare_put(sink, pad);
    }
}

static int cminus_bare_utoa(unsigned long long value, unsigned base, int upper,
                            char* out)
{
    const char* digits = upper ? "0123456789ABCDEF" : "0123456789abcdef";
    char tmp[24];
    int n = 0;
    int i;

    if (value == 0) {
        tmp[n++] = '0';
    }
    while (value != 0) {
        tmp[n++] = digits[value % base];
        value /= base;
    }
    for (i = 0; i < n; i++) {
        out[i] = tmp[n - 1 - i];
    }
    return n;
}

static void cminus_bare_emit_number(struct cminus_bare_sink* sink, int negative,
                                    const char* body, int body_len,
                                    int width, int zero, int left)
{
    int sign_len = negative ? 1 : 0;
    int pad = width - body_len - sign_len;

    if (pad < 0) {
        pad = 0;
    }
    if (!left && !zero) {
        cminus_bare_pad(sink, ' ', pad);
    }
    if (negative) {
        cminus_bare_put(sink, '-');
    }
    if (!left && zero) {
        cminus_bare_pad(sink, '0', pad);
    }
    while (body_len-- > 0) {
        cminus_bare_put(sink, *body++);
    }
    if (left) {
        cminus_bare_pad(sink, ' ', pad);
    }
}

static int cminus_bare_vformat(struct cminus_bare_sink* sink, const char* fmt,
                               va_list ap)
{
    char num[24];

    while (*fmt != '\0') {
        int left = 0;
        int zero = 0;
        int width = 0;
        int longs = 0;

        if (*fmt != '%') {
            cminus_bare_put(sink, *fmt++);
            continue;
        }
        fmt++;
        for (;;) {
            if (*fmt == '-') {
                left = 1;
                fmt++;
            } else if (*fmt == '0') {
                zero = 1;
                fmt++;
            } else {
                break;
            }
        }
        while (*fmt >= '0' && *fmt <= '9') {
            width = width * 10 + (*fmt - '0');
            fmt++;
        }
        while (*fmt == 'l') {
            longs++;
            fmt++;
        }
        if (*fmt == 'z' || *fmt == 'h') {
            fmt++;
        }
        switch (*fmt) {
        case 'd':
        case 'i': {
            long long v = longs ? va_arg(ap, long long) : (long long)va_arg(ap, int);
            int negative = v < 0;
            unsigned long long mag = negative ? (unsigned long long)(-v)
                                              : (unsigned long long)v;
            int len = cminus_bare_utoa(mag, 10, 0, num);
            cminus_bare_emit_number(sink, negative, num, len, width, zero, left);
            break;
        }
        case 'u': {
            unsigned long long v = longs ? va_arg(ap, unsigned long long)
                                         : (unsigned long long)va_arg(ap, unsigned);
            int len = cminus_bare_utoa(v, 10, 0, num);
            cminus_bare_emit_number(sink, 0, num, len, width, zero, left);
            break;
        }
        case 'x':
        case 'X': {
            unsigned long long v = longs ? va_arg(ap, unsigned long long)
                                         : (unsigned long long)va_arg(ap, unsigned);
            int len = cminus_bare_utoa(v, 16, *fmt == 'X', num);
            cminus_bare_emit_number(sink, 0, num, len, width, zero, left);
            break;
        }
        case 'p': {
            unsigned long long v = (unsigned long long)(size_t)va_arg(ap, void*);
            int len = cminus_bare_utoa(v, 16, 0, num);
            cminus_bare_put(sink, '0');
            cminus_bare_put(sink, 'x');
            cminus_bare_emit_number(sink, 0, num, len, 0, 0, 0);
            break;
        }
        case 'c': {
            char c = (char)va_arg(ap, int);
            cminus_bare_emit_number(sink, 0, &c, 1, width, 0, left);
            break;
        }
        case 's': {
            const char* s = va_arg(ap, const char*);
            int len;
            if (s == NULL) {
                s = "(null)";
            }
            len = (int)strlen(s);
            if (!left) {
                cminus_bare_pad(sink, ' ', width - len);
            }
            while (*s != '\0') {
                cminus_bare_put(sink, *s++);
            }
            if (left) {
                cminus_bare_pad(sink, ' ', width - len);
            }
            break;
        }
        case '%':
            cminus_bare_put(sink, '%');
            break;
        case '\0':
            cminus_bare_put(sink, '%');
            return (int)sink->len;
        default:
            cminus_bare_put(sink, '%');
            cminus_bare_put(sink, *fmt);
            break;
        }
        fmt++;
    }
    return (int)sink->len;
}

CMINUS_BARE_API int printf(const char* fmt, ...)
{
    struct cminus_bare_sink sink;
    va_list ap;
    int n;

    sink.buf = NULL;
    sink.cap = 0;
    sink.len = 0;
    sink.console = 1;
    va_start(ap, fmt);
    n = cminus_bare_vformat(&sink, fmt, ap);
    va_end(ap);
    return n;
}

CMINUS_BARE_API int fprintf(FILE* stream, const char* fmt, ...)
{
    struct cminus_bare_sink sink;
    va_list ap;
    int n;

    (void)stream;
    sink.buf = NULL;
    sink.cap = 0;
    sink.len = 0;
    sink.console = 1;
    va_start(ap, fmt);
    n = cminus_bare_vformat(&sink, fmt, ap);
    va_end(ap);
    return n;
}

CMINUS_BARE_API int puts(const char* s)
{
#if defined(CMINUS_BARE_HAVE_SYSCALLS)
    /* One write for the body, one for the newline: small and few syscalls. */
    const char* p = s;
    while (*p != '\0') {
        p++;
    }
    cminus_bare_sys_write(1, s, (unsigned long)(p - s));
    cminus_bare_sys_write(1, "\n", 1);
#else
    while (*s != '\0') {
        putchar((int)(unsigned char)*s++);
    }
    putchar('\n');
#endif
    return 0;
}

CMINUS_BARE_API int asprintf(char** out, const char* fmt, ...)
{
    struct cminus_bare_sink sink;
    va_list ap;
    int len;
    char* buf;

    sink.buf = NULL;
    sink.cap = 0;
    sink.len = 0;
    sink.console = 0;
    va_start(ap, fmt);
    len = cminus_bare_vformat(&sink, fmt, ap);
    va_end(ap);

    buf = (char*)malloc((size_t)len + 1);
    if (buf == NULL) {
        *out = NULL;
        return -1;
    }
    sink.buf = buf;
    sink.cap = (size_t)len + 1;
    sink.len = 0;
    sink.console = 0;
    va_start(ap, fmt);
    cminus_bare_vformat(&sink, fmt, ap);
    va_end(ap);
    buf[len] = '\0';
    *out = buf;
    return len;
}

/* control ------------------------------------------------------------- */

/*
 * No stack unwinding on bare metal: cminus_panic still prints the source file
 * and line, then calls these no-ops where it would have dumped a backtrace.
 */
CMINUS_BARE_API int backtrace(void** buffer, int size)
{
    (void)buffer;
    (void)size;
    return 0;
}

CMINUS_BARE_API void backtrace_symbols_fd(void* const* buffer, int size, int fd)
{
    (void)buffer;
    (void)size;
    (void)fd;
}

CMINUS_BARE_API void abort(void)
{
    for (;;) {
    }
}

CMINUS_BARE_API void exit(int status)
{
    (void)status;
    for (;;) {
    }
}

/*
 * Linux host startup: provide a default putchar and _start so a -bare program
 * runs with no board code. Both are weak, so a board that links its own
 * putchar/_start (in a separate source) simply overrides them.
 */
#if defined(CMINUS_BARE_HAVE_SYSCALLS)
__attribute__((weak)) int putchar(int c)
{
    unsigned char ch = (unsigned char)c;
    cminus_bare_sys_write(1, &ch, 1);
    return c;
}

extern int main(void);
__attribute__((weak)) void _start(void)
{
    cminus_bare_sys_exit((long)main());
}
#endif /* CMINUS_BARE_HAVE_SYSCALLS */

#endif /* CMINUS_BARE_IMPL */

#endif /* CMINUS_BARE_H */
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
struct Vec_int{
    int* data;
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
struct __CMinusIndex_int Vec_get_opt_int(struct Vec_int* self, int index){
    if (self == NULL || index < 0 || index >= self->len) {
        return __CMinusIndex_int_None();
    }
    return __CMinusIndex_int_Some(self->data[index]);
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

static __attribute__((unused)) struct __CMinusGCHeader* __cminus_gc_find_live(void* mem)
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

static __attribute__((unused)) struct __CMinusGCHeader* __cminus_gc_find_dead(void* mem)
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

int main(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Vec_int *nums = {0};
    memset(&nums, 0, sizeof(nums));


    Vec_push_int(nums, 11);
    Vec_push_int(nums, 22);

    printf("first = %d\n", ({ struct __CMinusIndex_int __index_result0 = Vec_get_opt_int(nums, 0); if (__index_result0.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/bare_metal.c-", 10); } __index_result0.payload.Some; }));

    /* Out-of-range index still panics with source file and line. */
    printf("bad = %d\n", ({ struct __CMinusIndex_int __index_result1 = Vec_get_opt_int(nums, 9); if (__index_result1.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/bare_metal.c-", 13); } __index_result1.payload.Some; }));

    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return 0;
}