void cminus_panic(const char* message, const char* file, int line);
int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
__SIZE_TYPE__ cminus_stack_enter_impl(const char* file, int line, void* anchor);
void cminus_stack_leave_impl(__SIZE_TYPE__ id, const char* file, int line);
void* cminus_gc_calloc_impl(__SIZE_TYPE__ count, __SIZE_TYPE__ size, const char* file, int line);
void cminus_gc_free_impl(void* mem, const char* file, int line);

#define __CMINUS_GC_MAGIC 0x434d4743UL
#define __CMINUS_STACK_NOTE_WINDOW (1024UL * 1024UL)
#define CMINUS_MAX_ALLOCATION (1024UL * 1024UL * 1024UL)
#define CMINUS_MAX_STACK_DEPTH 1024UL
#define CMINUS_MAX_STACK_BYTES (2UL * 1024UL * 1024UL)
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
#define CMINUS_THREAD_LOCAL
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
extern char* cminus_string_format(const char* fmt, ...);
extern int backtrace(void** buffer, int size);
extern void backtrace_symbols_fd(void* const* buffer, int size, int fd);
extern void abort(void);
extern void exit(int status);
extern void cminus_panic(const char* message, const char* file, int line);
extern unsigned long cminus_align_up_impl(unsigned long value, unsigned long alignment, const char* file, int line);
extern unsigned long cminus_align_down_impl(unsigned long value, unsigned long alignment, const char* file, int line);
extern int cminus_is_aligned_impl(unsigned long value, unsigned long alignment, const char* file, int line);

#define align_up(value, alignment) cminus_align_up_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#define align_down(value, alignment) cminus_align_down_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)
#define is_aligned(value, alignment) cminus_is_aligned_impl((unsigned long)(value), (unsigned long)(alignment), __FILE__, __LINE__)

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

CMINUS_BARE_API char* cminus_string_format(const char* fmt, ...)
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

    buf = (char*)calloc((size_t)len + 1, sizeof(char));
    if (buf == NULL) {
        return NULL;
    }
    sink.buf = buf;
    sink.cap = (size_t)len + 1;
    sink.len = 0;
    sink.console = 0;
    va_start(ap, fmt);
    cminus_bare_vformat(&sink, fmt, ap);
    va_end(ap);
    buf[len] = '\0';
    return buf;
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

CMINUS_BARE_API unsigned long cminus_align_up_impl(unsigned long value, unsigned long alignment, const char* file, int line)
{
    unsigned long rem;
    unsigned long add;

    if (alignment == 0u) {
        cminus_panic("alignment is zero", file, line);
    }
    rem = value % alignment;
    if (rem == 0u) {
        return value;
    }
    add = alignment - rem;
    if (value > ~0UL - add) {
        cminus_panic("alignment overflow", file, line);
    }
    return value + add;
}

CMINUS_BARE_API unsigned long cminus_align_down_impl(unsigned long value, unsigned long alignment, const char* file, int line)
{
    if (alignment == 0u) {
        cminus_panic("alignment is zero", file, line);
    }
    return value - (value % alignment);
}

CMINUS_BARE_API int cminus_is_aligned_impl(unsigned long value, unsigned long alignment, const char* file, int line)
{
    if (alignment == 0u) {
        cminus_panic("alignment is zero", file, line);
    }
    return value % alignment == 0u;
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
struct Vec_int{
    int* data;
    int len;
    int cap;
};
void Vec_push_int(struct Vec_int* self, int value);
struct __CMinusIndex_int Vec_get_opt_int(struct Vec_int* self, int index);
#ifndef CMINUS_BARE_H
#endif

#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC optimize ("trapv")
#endif
#ifndef CMINUS_MAX_ALLOCATION
#endif
#ifndef CMINUS_MAX_STACK_DEPTH
#endif
#ifndef CMINUS_MAX_STACK_BYTES
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

static __attribute__((unused)) struct __CMinusGCHeader* __CMinusGCHeader_clone(struct __CMinusGCHeader* self)
{
    struct __CMinusGCHeader* copy = calloc(1, sizeof(struct __CMinusGCHeader));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->magic = self->magic;
    copy->allocation_id = self->allocation_id;
    copy->size = self->size;
    copy->capacity = self->capacity;
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
    copy->id = self->id;
    copy->anchor = self->anchor;
    copy->parent_anchor = self->parent_anchor;
    copy->low = self->low;
    copy->high = self->high;
    copy->explicit_low = self->explicit_low;
    copy->explicit_high = self->explicit_high;
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
size_t cminus_checked_size_add_impl(size_t left, size_t right, const char* file, int line);
size_t cminus_checked_size_mul_impl(size_t left, size_t right, const char* file, int line);
int cminus_checked_int_add_impl(int left, int right, const char* file, int line);
int cminus_checked_int_mul_impl(int left, int right, const char* file, int line);
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
static __attribute__((unused)) void cminus_string_require_alive(const char* value);
#ifndef CMINUS_BARE_H
static __attribute__((unused)) unsigned long cminus_align_up_impl(unsigned long value, unsigned long alignment, const char* file, int line);
static __attribute__((unused)) unsigned long cminus_align_down_impl(unsigned long value, unsigned long alignment, const char* file, int line);
static __attribute__((unused)) int cminus_is_aligned_impl(unsigned long value, unsigned long alignment, const char* file, int line);
#endif
#ifndef CMINUS_BARE_H
#endif

struct __CMinusGCHeader* __cminus_gc_live_head = NULL;
struct __CMinusGCHeader* __cminus_gc_dead_head = NULL;
unsigned long __cminus_gc_next_allocation_id = 1UL;
#ifndef CMINUS_BARE_H
int __cminus_gc_lock_word = 0;
#endif
CMINUS_THREAD_LOCAL struct __CMinusStackFrame* __cminus_stack_head = NULL;
CMINUS_THREAD_LOCAL size_t __cminus_stack_next_id = 1;
CMINUS_THREAD_LOCAL size_t __cminus_stack_depth = 0;
CMINUS_THREAD_LOCAL size_t __cminus_stack_root_anchor = 0;
#ifdef CMINUS_BARE_H
struct __CMinusStackFrame __cminus_stack_frames[256];
int __cminus_stack_frame_used[256];
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
    size_t address = {0};
    memset(&address, 0, sizeof(address));

    size_t base = {0};
    memset(&base, 0, sizeof(base));

    size_t span = {0};
    memset(&span, 0, sizeof(span));


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
    struct __CMinusGCHeader* it = {0};
    memset(&it, 0, sizeof(it));

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

int cminus_gc_is_alive(void* mem)
{
    int found = {0};
    memset(&found, 0, sizeof(found));


    __cminus_gc_lock();
    found = __cminus_gc_find_live_containing(mem) != NULL;
    __cminus_gc_unlock();
    return found;
}

int cminus_gc_is_managed(void* mem)
{
    int found = {0};
    memset(&found, 0, sizeof(found));


    __cminus_gc_lock();
    found = __cminus_gc_find_live_containing(mem) != NULL ||
        __cminus_gc_find_dead_containing(mem) != NULL;
    __cminus_gc_unlock();
    return found;
}

int cminus_gc_is_dead(void* mem)
{
    int found = {0};
    memset(&found, 0, sizeof(found));


    __cminus_gc_lock();
    found = __cminus_gc_find_dead_containing(mem) != NULL;
    __cminus_gc_unlock();
    return found;
}

size_t cminus_checked_size_add_impl(size_t left, size_t right, const char* file, int line)
{
    if (left > (size_t)-1 - right) {
        cminus_panic("size addition overflow", file, line);
    }
    return left + right;
}

size_t cminus_checked_size_mul_impl(size_t left, size_t right, const char* file, int line)
{
    size_t result = {0};
    memset(&result, 0, sizeof(result));


    if (__builtin_mul_overflow(left, right, &result)) {
        cminus_panic("size multiplication overflow", file, line);
    }
    return result;
}

int cminus_checked_int_add_impl(int left, int right, const char* file, int line)
{
    int result = {0};
    memset(&result, 0, sizeof(result));


    if (__builtin_add_overflow(left, right, &result)) {
        cminus_panic("integer addition overflow", file, line);
    }
    return result;
}

int cminus_checked_int_mul_impl(int left, int right, const char* file, int line)
{
    int result = {0};
    memset(&result, 0, sizeof(result));


    if (__builtin_mul_overflow(left, right, &result)) {
        cminus_panic("integer multiplication overflow", file, line);
    }
    return result;
}

#ifdef CMINUS_BARE_H
int __addvsi3(int left, int right)
{
    return cminus_checked_int_add_impl(left, right, __FILE__, __LINE__);
}

int __subvsi3(int left, int right)
{
    int result = {0};
    memset(&result, 0, sizeof(result));


    if (__builtin_sub_overflow(left, right, &result)) {
        cminus_panic("integer subtraction overflow", __FILE__, __LINE__);
    }
    return result;
}

int __mulvsi3(int left, int right)
{
    return cminus_checked_int_mul_impl(left, right, __FILE__, __LINE__);
}

long long __addvdi3(long long left, long long right)
{
    long long result = {0};
    memset(&result, 0, sizeof(result));


    if (__builtin_add_overflow(left, right, &result)) {
        cminus_panic("integer addition overflow", __FILE__, __LINE__);
    }
    return result;
}

long long __subvdi3(long long left, long long right)
{
    long long result = {0};
    memset(&result, 0, sizeof(result));


    if (__builtin_sub_overflow(left, right, &result)) {
        cminus_panic("integer subtraction overflow", __FILE__, __LINE__);
    }
    return result;
}

long long __mulvdi3(long long left, long long right)
{
    long long result = {0};
    memset(&result, 0, sizeof(result));


    if (__builtin_mul_overflow(left, right, &result)) {
        cminus_panic("integer multiplication overflow", __FILE__, __LINE__);
    }
    return result;
}
#endif

void* cminus_gc_calloc_impl(size_t count, size_t size, const char* file, int line)
{
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));

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

void cminus_gc_free_impl(void* mem, const char* file, int line)
{
    struct __CMinusGCHeader* header = {0};
    memset(&header, 0, sizeof(header));

    struct __CMinusGCHeader* containing = {0};
    memset(&containing, 0, sizeof(containing));

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
char* cminus_string_format(const char* fmt, ...)
{
    __builtin_va_list ap = {0};
    memset(&ap, 0, sizeof(ap));

    __builtin_va_list copy = {0};
    memset(&copy, 0, sizeof(copy));

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
    size_t prev = {0};
    memset(&prev, 0, sizeof(prev));

    size_t used = {0};
    memset(&used, 0, sizeof(used));


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

    size_t low = {0};
    memset(&low, 0, sizeof(low));

    size_t high = {0};
    memset(&high, 0, sizeof(high));

    size_t anchor = {0};
    memset(&anchor, 0, sizeof(anchor));

    size_t parent_anchor = {0};
    memset(&parent_anchor, 0, sizeof(parent_anchor));

    size_t near_anchor = {0};
    memset(&near_anchor, 0, sizeof(near_anchor));

    size_t near_parent = {0};
    memset(&near_parent, 0, sizeof(near_parent));


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
    size_t low = {0};
    memset(&low, 0, sizeof(low));

    size_t high = {0};
    memset(&high, 0, sizeof(high));


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

    struct __CMinusGCHeader* managed = {0};
    memset(&managed, 0, sizeof(managed));

#ifndef CMINUS_BARE_H
    struct __CMinusStackFrame* owner = NULL;
#endif
    size_t ptr = {0};
    memset(&ptr, 0, sizeof(ptr));


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

void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line)
{
    struct __CMinusGCHeader* managed = {0};
    memset(&managed, 0, sizeof(managed));


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

static __attribute__((unused)) void cminus_string_require_alive(const char* value)
{
    unsigned long allocation_id = (unsigned long)0;
    int kind = {0};
    memset(&kind, 0, sizeof(kind));


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
    int self_len = {0};
    memset(&self_len, 0, sizeof(self_len));

    int needle_len = {0};
    memset(&needle_len, 0, sizeof(needle_len));

    int i = {0};
    memset(&i, 0, sizeof(i));

    int j = {0};
    memset(&j, 0, sizeof(j));


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
    int prefix_len = {0};
    memset(&prefix_len, 0, sizeof(prefix_len));

    int i = {0};
    memset(&i, 0, sizeof(i));


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
    int self_len = {0};
    memset(&self_len, 0, sizeof(self_len));

    int suffix_len = {0};
    memset(&suffix_len, 0, sizeof(suffix_len));


    cminus_string_require_alive(self);
    cminus_string_require_alive(suffix);
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
    int references;
};

static __attribute__((unused)) struct __CMinusThreadState* __CMinusThreadState_clone(struct __CMinusThreadState* self)
{
    struct __CMinusThreadState* copy = calloc(1, sizeof(struct __CMinusThreadState));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->fn = self->fn;
    copy->result = self->result;
    copy->references = self->references;
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
    pthread_mutex_t* native;
    int initialized;
};

static __attribute__((unused)) struct Mutex* Mutex_clone(struct Mutex* self)
{
    struct Mutex* copy = cminus_gc_calloc(1, sizeof(struct Mutex));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->native = self->native;
    copy->initialized = self->initialized;
    return copy;
}


struct Cond {
    pthread_cond_t* native;
    int initialized;
};

static __attribute__((unused)) struct Cond* Cond_clone(struct Cond* self)
{
    struct Cond* copy = cminus_gc_calloc(1, sizeof(struct Cond));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->native = self->native;
    copy->initialized = self->initialized;
    return copy;
}

#endif


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

    state->result = (*(state->fn))();
    __cminus_thread_state_release(state);
    return NULL;
}

static __attribute__((unused)) struct Thread Thread_spawn(CMinusThreadMain fn)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Thread out = {0};
    memset(&out, 0, sizeof(out));

    pthread_t handle = {0};
    memset(&handle, 0, sizeof(handle));

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
    out.state->references = 2;
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

    pthread_t handle = {0};
    memset(&handle, 0, sizeof(handle));

    int rc = {0};
    memset(&rc, 0, sizeof(rc));

    int result = {0};
    memset(&result, 0, sizeof(result));

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
    __typeof__((result)) __cminus_return3 = (result);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return3;
}

static __attribute__((unused)) void Thread_detach(struct Thread* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    pthread_t handle = {0};
    memset(&handle, 0, sizeof(handle));

    int rc = {0};
    memset(&rc, 0, sizeof(rc));

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
    __atomic_store_n(&self->joined, 1, __ATOMIC_RELEASE);    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

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
    __typeof__((out)) __cminus_return4 = (out);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return4;
}

static __attribute__((unused)) void Mutex_lock(struct Mutex* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    if (self == NULL || !self->initialized || self->native == NULL) {
        cminus_panic("mutex is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_mutex_lock(self->native) != 0) {
        cminus_panic("pthread_mutex_lock failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Mutex_unlock(struct Mutex* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    if (self == NULL || !self->initialized || self->native == NULL) {
        cminus_panic("mutex is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_mutex_unlock(self->native) != 0) {
        cminus_panic("pthread_mutex_unlock failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Mutex_destroy(struct Mutex* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    if (self == NULL || !self->initialized) {
        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
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
    self->initialized = 0;    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) struct Cond Cond_init(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    struct Cond out = {0};
    memset(&out, 0, sizeof(out));


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
    __typeof__((out)) __cminus_return5 = (out);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return5;
}

static __attribute__((unused)) void Cond_wait(struct Cond* self, struct Mutex* mutex)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    if (self == NULL || !self->initialized || self->native == NULL ||
        mutex == NULL || !mutex->initialized || mutex->native == NULL) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_cond_wait(self->native, mutex->native) != 0) {
        cminus_panic("pthread_cond_wait failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Cond_signal(struct Cond* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    if (self == NULL || !self->initialized || self->native == NULL) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_cond_signal(self->native) != 0) {
        cminus_panic("pthread_cond_signal failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Cond_broadcast(struct Cond* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    if (self == NULL || !self->initialized || self->native == NULL) {
        cminus_panic("condition variable is uninitialized", __FILE__, __LINE__);
    }
    if (pthread_cond_broadcast(self->native) != 0) {
        cminus_panic("pthread_cond_broadcast failed", __FILE__, __LINE__);
    }    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);

}

static __attribute__((unused)) void Cond_destroy(struct Cond* self)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    if (self == NULL || !self->initialized) {
        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
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

    __typeof__((0)) __cminus_return6 = (0);
    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return __cminus_return6;
}
void Vec_push_int(struct Vec_int* self, int value){
    int* next;
    int next_cap = self->cap == 0 ? 4 : cminus_checked_int_mul(self->cap, 2);

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
    self->data[self->len] = value;
    self->len = cminus_checked_int_add(self->len, 1);
}
struct __CMinusIndex_int Vec_get_opt_int(struct Vec_int* self, int index){
    if (self == NULL || index < 0 || index >= self->len) {
        return __CMinusIndex_int_None();
    }
    return __CMinusIndex_int_Some(self->data[index]);
}
