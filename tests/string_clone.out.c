void cminus_panic(const char* message, const char* file, int line);
int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);
void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);
void* cminus_gc_calloc_impl(unsigned long count, unsigned long size, const char* file, int line);

#define cminus_gc_calloc(count, size) cminus_gc_calloc_impl((count), (size), __FILE__, __LINE__)
#define cminus_gc_free(mem) cminus_gc_free_impl((mem), __FILE__, __LINE__)

#define _GNU_SOURCE
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>

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

struct Person {
    char* name;
    int age;
};

static void Person_finalize(struct Person* self)
{
    if (self == NULL) {
        return;
    }
    if (self->name != NULL) {
        cminus_gc_free(self->name);
    }

}


static __attribute__((unused)) struct Person* Person_clone(struct Person* self)
{
    struct Person* copy = cminus_gc_calloc(1, sizeof(struct Person));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    if (self->name != NULL) {
        copy->name = cminus_gc_calloc(strlen(self->name) + 1, sizeof(char));
        strncpy(copy->name, self->name, strlen(self->name) + 1);
    }
    copy->age = self->age;
    return copy;
}


int main(void)
{    char __cminus_stack_anchor;
    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);

    char* source;
    asprintf(&source, "Alice");
    struct Person *person = cminus_gc_calloc(1, sizeof(struct Person));    void* __owned_old2 = person->name;


    person->name =({ char* __right_value_src0 = source; char* __right_value1 = NULL; if (__right_value_src0 != NULL) { __right_value1 = cminus_gc_calloc(strlen(__right_value_src0) + 1, sizeof(char)); strncpy(__right_value1, __right_value_src0, strlen(__right_value_src0) + 1); } __right_value1; });
    if (__owned_old2 != NULL) {
        cminus_gc_free(__owned_old2);
    }


    person->age = 42;
    struct Person *copy =({ struct Person* __right_value_src3 = person; struct Person* __right_value4 = NULL; if (__right_value_src3 != NULL) { __right_value4 = Person_clone(__right_value_src3); } __right_value4; });

    if (person->name == NULL || copy == NULL || copy->name == NULL) {
        if (copy != NULL) {
            Person_finalize(copy);
            cminus_gc_free(copy);
        }

        if (person != NULL) {
            Person_finalize(person);
            cminus_gc_free(person);
        }

        if (source != NULL) {
            cminus_gc_free(source);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 1;
    }
    if (copy->name == person->name) {
        if (copy != NULL) {
            Person_finalize(copy);
            cminus_gc_free(copy);
        }

        if (person != NULL) {
            Person_finalize(person);
            cminus_gc_free(person);
        }

        if (source != NULL) {
            cminus_gc_free(source);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 2;
    }
    if (strcmp(copy->name, "Alice") != 0 || copy->age != 42) {
        if (copy != NULL) {
            Person_finalize(copy);
            cminus_gc_free(copy);
        }

        if (person != NULL) {
            Person_finalize(person);
            cminus_gc_free(person);
        }

        if (source != NULL) {
            cminus_gc_free(source);
        }

        cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
        return 3;
    }
    if (copy != NULL) {
        Person_finalize(copy);
        cminus_gc_free(copy);
    }

    if (person != NULL) {
        Person_finalize(person);
        cminus_gc_free(person);
    }

    if (source != NULL) {
        cminus_gc_free(source);
    }

    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);
    return 0;
}