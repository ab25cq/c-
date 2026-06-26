/*
 * c- bare-metal runtime.
 *
 * A tiny freestanding C library that lets `c-` output run with no libc. It
 * implements exactly the libc surface the generated C uses (memory, a few
 * string helpers, printf-family, abort) on top of a single user-provided
 * primitive:
 *
 *     int putchar(int c);
 *
 * Write that for your board (UART, semihosting, ...) and link it in. Everything
 * else here is `weak`, so it merges across translation units and satisfies the
 * mem* calls the compiler itself may emit.
 *
 * Build a generated file produced with `c- -bare` like:
 *
 *     cc -ffreestanding -nostdlib -fno-builtin program.c putchar.c -o program
 *
 * Heap size is a fixed static buffer; override with
 * -DCMINUS_BARE_HEAP_SIZE=<bytes>.
 */
#ifndef CMINUS_BARE_H
#define CMINUS_BARE_H

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

/* The host provides this; it is the only required symbol. */
extern int putchar(int c);

/*
 * A FILE is only a stream id here. cminus_panic writes to stderr; both streams
 * end up at putchar on a board with a single console.
 */
typedef struct cminus_bare_file { int fd; } FILE;
/* weak: the runtime is inlined into every -bare translation unit, so these
   definitions must merge instead of colliding at link time. */
__attribute__((weak)) FILE __cminus_bare_stdout = { 1 };
__attribute__((weak)) FILE __cminus_bare_stderr = { 2 };
#define stdout (&__cminus_bare_stdout)
#define stderr (&__cminus_bare_stderr)

#define CMINUS_BARE_API __attribute__((weak))

#ifndef CMINUS_BARE_HEAP_SIZE
#define CMINUS_BARE_HEAP_SIZE (64u * 1024u)
#endif

/* ----------------------------------------------------------------------- */
/* Linux syscall primitives                                                */
/* ----------------------------------------------------------------------- */

/*
 * On a hosted Linux target, write/exit syscalls let the runtime provide a
 * default putchar/_start (see the bottom of this file) and a one-call puts,
 * with no board code. Defining CMINUS_BARE_HAVE_SYSCALLS also tells puts below
 * to emit the whole line in a single write instead of a putchar loop. Real
 * freestanding targets (no __linux__/known arch) get none of this and supply
 * their own putchar.
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

/* ----------------------------------------------------------------------- */
/* memory                                                                  */
/* ----------------------------------------------------------------------- */

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

/* ----------------------------------------------------------------------- */
/* strings                                                                 */
/* ----------------------------------------------------------------------- */

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

/* ----------------------------------------------------------------------- */
/* formatted output, all routed through putchar                            */
/* ----------------------------------------------------------------------- */

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

/* ----------------------------------------------------------------------- */
/* control                                                                 */
/* ----------------------------------------------------------------------- */

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

/* ----------------------------------------------------------------------- */
/* Linux host startup                                                      */
/* ----------------------------------------------------------------------- */

/*
 * On a hosted Linux target, provide putchar and _start through raw syscalls so
 * a -bare program builds and runs with no board code at all. Both are weak, but
 * because the runtime is inlined into every translation unit a *strong*
 * override in the same file would collide; to supply your own, compile with
 * -DCMINUS_BARE_NO_DEFAULT_PUTCHAR and/or -DCMINUS_BARE_NO_DEFAULT_START.
 *
 * Real freestanding targets (e.g. arm-none-eabi) do not define __linux__, so
 * nothing is emitted here and the board provides putchar and startup itself.
 */

#if defined(CMINUS_BARE_HAVE_SYSCALLS)

#if !defined(CMINUS_BARE_NO_DEFAULT_PUTCHAR)
__attribute__((weak)) int putchar(int c)
{
    unsigned char ch = (unsigned char)c;
    cminus_bare_sys_write(1, &ch, 1);
    return c;
}
#endif

#if !defined(CMINUS_BARE_NO_DEFAULT_START)
extern int main(void);
__attribute__((weak)) void _start(void)
{
    cminus_bare_sys_exit((long)main());
}
#endif

#endif /* CMINUS_BARE_HAVE_SYSCALLS */


#endif /* CMINUS_BARE_H */
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

int main(void)
{
    struct Vec_int nums = {0};
    memset(&nums, 0, sizeof(nums));


    Vec_push_int(&nums, 11);
    Vec_push_int(&nums, 22);

    printf("first = %d\n", ({ struct __CMinusIndex_int __index_result0 = Vec_get_opt_int(&nums, 0); if (__index_result0.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/bare_metal.c-", 10); } __index_result0.payload.Some; }));

    /* Out-of-range index still panics with source file and line. */
    printf("bad = %d\n", ({ struct __CMinusIndex_int __index_result1 = Vec_get_opt_int(&nums, 9); if (__index_result1.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/bare_metal.c-", 13); } __index_result1.payload.Some; }));

    return 0;
}