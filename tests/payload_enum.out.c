
#define xassert(name, cond) do { if (!(cond)) { puts(name); return 1; } } while (0)
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
struct Option_int{
    int tag;
    union {
        int Some;
    } payload;
};
enum {
    Option_int_TAG_Some,
    Option_int_TAG_None
};
static __attribute__((unused)) struct Option_int Option_int_Some(int value)
{
    struct Option_int out = {0};
    out.tag = Option_int_TAG_Some;
    out.payload.Some = value;
    return out;
}
static __attribute__((unused)) int Option_int_is_Some(struct Option_int* self)
{
    return self->tag == Option_int_TAG_Some;
}
static __attribute__((unused)) int Option_int_get_Some(struct Option_int* self)
{
    return self->payload.Some;
}
static __attribute__((unused)) struct Option_int Option_int_None(void)
{
    struct Option_int out = {0};
    out.tag = Option_int_TAG_None;
    return out;
}
static __attribute__((unused)) int Option_int_is_None(struct Option_int* self)
{
    return self->tag == Option_int_TAG_None;
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
    struct Option_int some = Option_int_Some(123);
    struct Option_int none = Option_int_None();

    xassert("some", Option_int_is_Some(&some));
    xassert("none", Option_int_is_None(&none));
    xassert("payload", Option_int_get_Some(&some) == 123);
    return 0;
}