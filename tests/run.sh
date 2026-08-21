set -eu
ROOT=$(pwd)

./c- tests/good.c- > tests/good.out.c
grep 'int\* a = calloc(1, sizeof(int));' tests/good.out.c >/dev/null
if grep 'cminus_gc_free(a);' tests/good.out.c >/dev/null; then
    echo "raw calloc unexpectedly became managed" >&2
    exit 1
fi
cc -std=c99 -Wall -Wextra -pedantic tests/good.out.c -o tests/good.out
./tests/good.out

./c- tests/no_return.c- > tests/no_return.out.c
if grep 'cminus_gc_free(a);' tests/no_return.out.c >/dev/null; then
    echo "raw calloc unexpectedly became managed" >&2
    exit 1
fi
cc -std=c99 -Wall -Wextra -pedantic -c tests/no_return.out.c -o tests/no_return.out.o

./c- tests/types_ok.c- > tests/types_ok.out.c
grep 'struct Pair \*p = cminus_gc_calloc(1, sizeof(struct Pair));' tests/types_ok.out.c >/dev/null
grep 'cminus_gc_free(p);' tests/types_ok.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/types_ok.out.c -o tests/types_ok.out
./tests/types_ok.out

./c- tests/local_zero.c- > tests/local_zero.out.c
grep '#include <string.h>' tests/local_zero.out.c >/dev/null
grep 'int value = {0};' tests/local_zero.out.c >/dev/null
grep 'struct Pair \*pair = cminus_gc_calloc(1, sizeof(struct Pair));' tests/local_zero.out.c >/dev/null
grep 'int\* ptr = {0};' tests/local_zero.out.c >/dev/null
grep 'memset(&value, 0, sizeof(value));' tests/local_zero.out.c >/dev/null
grep 'memset(&ptr, 0, sizeof(ptr));' tests/local_zero.out.c >/dev/null
grep 'int initialized = 7;' tests/local_zero.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/local_zero.out.c -o tests/local_zero.out
./tests/local_zero.out

./c- -c-compat tests/c_compat_macros.c- > tests/c_compat_macros.out.c
grep '#ifdef CCOMPAT_VALUE' tests/c_compat_macros.out.c >/dev/null
grep '#pragma GCC diagnostic push' tests/c_compat_macros.out.c >/dev/null
grep '#undef CCOMPAT_VALUE' tests/c_compat_macros.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/c_compat_macros.out.c -o tests/c_compat_macros.out
test "$(./tests/c_compat_macros.out)" = "c compat macros"

./c- -c-compat tests/c_compat_typedefs.c- > tests/c_compat_typedefs.out.c
grep 'typedef struct CPoint' tests/c_compat_typedefs.out.c >/dev/null
grep 'typedef int (\*CBinaryOp)(int, int);' tests/c_compat_typedefs.out.c >/dev/null
grep 'CPoint p = { .x = 10, .y = 20 };' tests/c_compat_typedefs.out.c >/dev/null
cc -std=gnu11 -Wall -Wextra tests/c_compat_typedefs.out.c -o tests/c_compat_typedefs.out
./tests/c_compat_typedefs.out

./c- tests/inline_c_block.c- > tests/inline_c_block.out.c
grep '#define INLINE_C_SCALE 4' tests/inline_c_block.out.c >/dev/null
grep 'static inline int inline_c_mul' tests/inline_c_block.out.c >/dev/null
grep 'local = inline_c_mul(local);' tests/inline_c_block.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/inline_c_block.out.c -o tests/inline_c_block.out
./tests/inline_c_block.out

./c- -c-compat tests/c_compat_c99_features.c- > tests/c_compat_c99_features.out.c
grep 'int values\[static 1\]' tests/c_compat_c99_features.out.c >/dev/null
grep 'int \* restrict values' tests/c_compat_c99_features.out.c >/dev/null
grep 'C99Inner literal = (C99Inner){ .x = 6, .y = 7 };' tests/c_compat_c99_features.out.c >/dev/null
grep 'int values\[\];' tests/c_compat_c99_features.out.c >/dev/null
cc -std=c99 -Wall -Wextra tests/c_compat_c99_features.out.c -o tests/c_compat_c99_features.out
test "$(./tests/c_compat_c99_features.out)" = "34"

./c- tests/struct_finalizer.c- > tests/struct_finalizer.out.c
grep 'struct Holder \*stack = cminus_gc_calloc(1, sizeof(struct Holder));' tests/struct_finalizer.out.c >/dev/null
grep 'struct Holder \*heap = cminus_gc_calloc(1, sizeof(struct Holder));' tests/struct_finalizer.out.c >/dev/null
grep 'static __attribute__((unused)) struct Holder\* Holder_clone(struct Holder\* self)' tests/struct_finalizer.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/struct_finalizer.out.c -o tests/struct_finalizer.out
./tests/struct_finalizer.out

./c- tests/new_operator.c- > tests/new_operator.out.c
grep 'int\* owned_value = calloc(1, sizeof(int));' tests/new_operator.out.c >/dev/null
grep 'struct Item \*item = cminus_gc_calloc(1, sizeof(struct Item));' tests/new_operator.out.c >/dev/null
if grep 'cminus_gc_free(owned_value);' tests/new_operator.out.c >/dev/null; then
    echo "raw calloc unexpectedly became managed" >&2
    exit 1
fi
grep 'cminus_gc_free(item);' tests/new_operator.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/new_operator.out.c -o tests/new_operator.out
./tests/new_operator.out

./c- tests/division_ok.c- > tests/division_ok.out.c
grep 'division by zero' tests/division_ok.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/division_ok.out.c -o tests/division_ok.out
./tests/division_ok.out

./c- tests/os_attributes.c- > tests/os_attributes.out.c
grep '__attribute__((section(".vectors"), used)) int vectors\[4\];' tests/os_attributes.out.c >/dev/null
grep '__attribute__((aligned(4096))) int page_table\[1024\];' tests/os_attributes.out.c >/dev/null
grep '__attribute__((naked)) void trampoline(void)' tests/os_attributes.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra -c tests/os_attributes.out.c -o tests/os_attributes.out.o

./c- tests/os_compile_time.c- > tests/os_compile_time.out.c
grep '_Static_assert(sizeof(struct TrapFrame) == 12, "trap frame size");' tests/os_compile_time.out.c >/dev/null
grep '_Static_assert(__builtin_offsetof(struct TrapFrame, pc) == 8, "pc offset");' tests/os_compile_time.out.c >/dev/null
grep '__attribute__((noreturn)) void halt_forever(void)' tests/os_compile_time.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra -c tests/os_compile_time.out.c -o tests/os_compile_time.out.o

./c- tests/bitflags_safe.c- > tests/bitflags_safe.out.c
grep 'typedef unsigned int PageFlags;' tests/bitflags_safe.out.c >/dev/null
grep 'PageFlags_Present = 1u' tests/bitflags_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/bitflags_safe.out.c -o tests/bitflags_safe.out
./tests/bitflags_safe.out

./c- tests/export_weak_symbols.c- > tests/export_weak_symbols.out.c
grep '__attribute__((used, externally_visible, section(".init.text"))) void kernel_entry(void)' tests/export_weak_symbols.out.c >/dev/null
grep '__attribute__((weak)) int board_timer_init(void)' tests/export_weak_symbols.out.c >/dev/null
grep '__attribute__((used, externally_visible, weak)) int board_magic = 42;' tests/export_weak_symbols.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/export_weak_symbols.out.c -o tests/export_weak_symbols.out
./tests/export_weak_symbols.out

./c- tests/linker_symbols.c- > tests/linker_symbols.out.c
grep 'extern char __kernel_start\[\];' tests/linker_symbols.out.c >/dev/null
grep '((unsigned long)(__kernel_start))' tests/linker_symbols.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/linker_symbols.out.c -o tests/linker_symbols.out
./tests/linker_symbols.out

./c- tests/alignment_helpers.c- > tests/alignment_helpers.out.c
grep 'cminus_align_up_impl' tests/alignment_helpers.out.c | grep '"tests/alignment_helpers.c-"' >/dev/null
cc -std=gnu99 -Wall -Wextra tests/alignment_helpers.out.c -o tests/alignment_helpers.out
./tests/alignment_helpers.out

./c- tests/ring_buffer_safe.c- > tests/ring_buffer_safe.out.c
grep 'struct RingBuffer_unsigned_char q = {0};' tests/ring_buffer_safe.out.c >/dev/null
grep 'RingBuffer_from_unsigned_char(owner->bytes, (int)sizeof(owner->bytes), 0)' tests/ring_buffer_safe.out.c >/dev/null
grep 'RingBuffer_from_unsigned_char(storage.bytes, 4, 0)' tests/ring_buffer_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/ring_buffer_safe.out.c -o tests/ring_buffer_safe.out
./tests/ring_buffer_safe.out

./c- tests/generic_default_params.c- > tests/generic_default_params.out.c
grep '#define choose_int(...)' tests/generic_default_params.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/generic_default_params.out.c -o tests/generic_default_params.out
test "$(./tests/generic_default_params.out)" = "62 14 22 102 141"

./c- tests/bitmap_safe.c- > tests/bitmap_safe.out.c
grep 'Bitmap map = {0};' tests/bitmap_safe.out.c >/dev/null
grep 'Bitmap_from(pages.words, (int)(sizeof(pages.words) \* 8))' tests/bitmap_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/bitmap_safe.out.c -o tests/bitmap_safe.out
./tests/bitmap_safe.out

./c- tests/alignment_panic.c- > tests/alignment_panic.out.c
cc -std=gnu99 -Wall -Wextra tests/alignment_panic.out.c -o tests/alignment_panic.out
if ./tests/alignment_panic.out > tests/alignment_panic.out.log 2> tests/alignment_panic.err; then
    echo "alignment zero did not panic" >&2
    exit 1
fi
grep 'panic: alignment is zero at tests/alignment_panic.c-:' tests/alignment_panic.err >/dev/null

if ./c- tests/bad_linker_addr_unknown.c- > /dev/null 2> tests/bad_linker_addr_unknown.err; then
    echo "unknown linker symbol addr_of unexpectedly succeeded" >&2
    exit 1
fi
grep 'addr_of(__missing_symbol) requires `linker_symbol __missing_symbol;` first' tests/bad_linker_addr_unknown.err >/dev/null

if ./c- tests/bad_ring_buffer_field_len.c- > /dev/null 2> tests/bad_ring_buffer_field_len.err; then
    echo "bad ring buffer length unexpectedly succeeded" >&2
    exit 1
fi
grep "buffer from length 4 exceeds array 'storage.values' length 3" tests/bad_ring_buffer_field_len.err >/dev/null

if ./c- tests/bad_bitmap_field_len.c- > /dev/null 2> tests/bad_bitmap_field_len.err; then
    echo "bad bitmap length unexpectedly succeeded" >&2
    exit 1
fi
grep "Bitmap.from bit length" tests/bad_bitmap_field_len.err >/dev/null

if ./c- tests/bad_bitflags_mismatch.c- > /dev/null 2> tests/bad_bitflags_mismatch.err; then
    echo "bad bitflags assignment unexpectedly succeeded" >&2
    exit 1
fi
grep "cannot assign IrqFlags to PageFlags" tests/bad_bitflags_mismatch.err >/dev/null

./c- tests/division_panic.c- > tests/division_panic.out.c
grep 'division by zero' tests/division_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/division_panic.out.c -o tests/division_panic.out
if ./tests/division_panic.out > tests/division_panic.out.log 2> tests/division_panic.err; then
    echo "division by zero did not panic" >&2
    exit 1
fi
grep 'panic: division by zero at tests/division_panic.c-:' tests/division_panic.err >/dev/null

rm -rf /tmp/cpm-smoke
./cpm new /tmp/cpm-smoke
(cd /tmp/cpm-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" run > run.out)
grep 'value 123' /tmp/cpm-smoke/run.out >/dev/null
test -x /tmp/cpm-smoke/target/debug/cpm-smoke
test -f /tmp/cpm-smoke/lib/c-.h
(cd /tmp/cpm-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" leak > leak.out 2> leak.err)
(cd /tmp/cpm-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" val > val.out 2> val.err)
grep -- ' -g ' /tmp/cpm-smoke/val.out >/dev/null

rm -rf /tmp/cpm-compat-smoke
./cpm new /tmp/cpm-compat-smoke
cat >> /tmp/cpm-compat-smoke/C-.toml <<'EOF'
std = "gnu11"
c_compat = true
EOF
cp tests/c_compat_macros.c- /tmp/cpm-compat-smoke/src/main.c-
cat > /tmp/cpm-compat-smoke/src/local_compat.h <<'EOF'
#define LOCAL_COMPAT_VALUE 5
int native_add(int a, int b);
EOF
cat > /tmp/cpm-compat-smoke/src/native.c <<'EOF'
#include "local_compat.h"

int native_add(int a, int b)
{
    return a + b;
}
EOF
cat >> /tmp/cpm-compat-smoke/src/main.c- <<'SRC'
#include "local_compat.h"
int cpm_local_header_check(void)
{
    return LOCAL_COMPAT_VALUE == 5 && native_add(2, 3) == 5 ? 0 : 1;
}
SRC
(cd /tmp/cpm-compat-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" run > run.out 2>&1)
grep -- '-std=gnu11' /tmp/cpm-compat-smoke/run.out >/dev/null
grep -- '-c-compat' /tmp/cpm-compat-smoke/run.out >/dev/null
grep -- '-Isrc' /tmp/cpm-compat-smoke/run.out >/dev/null
grep "'src/native.c'" /tmp/cpm-compat-smoke/run.out >/dev/null
grep 'c compat macros' /tmp/cpm-compat-smoke/run.out >/dev/null

rm -rf /tmp/cpm-common-smoke
./cpm new /tmp/cpm-common-smoke
cat > /tmp/cpm-common-smoke/src/main.c- <<'SRC'
#include <stdio.h>

int main(void)
{
    printf("%d\n", square(7));
    return 0;
}
SRC
cat > /tmp/cpm-common-smoke/src/math.c- <<'SRC'
int square(int value)
{
    return value * value;
}
SRC
(cd /tmp/cpm-common-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" run > run.out)
grep '^49$' /tmp/cpm-common-smoke/run.out >/dev/null
grep 'int square(int value);' /tmp/cpm-common-smoke/target/debug/common.h >/dev/null
test -f /tmp/cpm-common-smoke/target/debug/src_math.c

rm -rf /tmp/cpm-uniq-smoke
./cpm new /tmp/cpm-uniq-smoke
cat > /tmp/cpm-uniq-smoke/src/main.c- <<'SRC'
#include <stdio.h>

int main(void)
{
    printf("%d\n", sub(1, 2));
    return 0;
}
SRC
cat > /tmp/cpm-uniq-smoke/src/sub.c- <<'SRC'
int sub(int x, int y)
{
    return x + y;
}
SRC
(cd /tmp/cpm-uniq-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" run > run.out)
grep '^3$' /tmp/cpm-uniq-smoke/run.out >/dev/null
grep '^void cminus_panic' /tmp/cpm-uniq-smoke/target/debug/cpm-uniq-smoke.c | grep -v ';$' >/dev/null
grep 'extern void cminus_panic' /tmp/cpm-uniq-smoke/target/debug/src_sub.c >/dev/null
test "$(grep -h '^void cminus_panic' /tmp/cpm-uniq-smoke/target/debug/*.c | grep -v ';$' | wc -l)" = "1"

# Project-level bare build on Linux needs no board code: the runtime supplies a
# weak putchar/_start through syscalls. Single source, no putchar/_start written.
rm -rf /tmp/cpm-bare-smoke
CPM_BARE="$ROOT/lib/c-bare.h" ./cpm new /tmp/cpm-bare-smoke
printf '\nbare = true\n' >> /tmp/cpm-bare-smoke/C-.toml
cat > /tmp/cpm-bare-smoke/src/main.c- <<'SRC'
#include <c-.h>
#include <c-bare.h>

int main(void)
{
    printf("bare %d\n", 6 * 7);
    return 0;
}
SRC
if [ "$(uname -m)" = "x86_64" ]; then
    (cd /tmp/cpm-bare-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" build > build.out 2>&1)
    # No system header leaks into the program sources. The generated runtime
    # object source (c-bare-runtime.c) does include <c-bare.h> on purpose.
    if ls /tmp/cpm-bare-smoke/target/debug/*.c | grep -v c-bare-runtime.c \
        | xargs grep -E '#include[[:space:]]*<' >/dev/null 2>&1; then
        echo "bare project still includes a system header" >&2
        exit 1
    fi
    # Built executable must not depend on libc (no dynamic NEEDED entries).
    if readelf -d /tmp/cpm-bare-smoke/target/debug/cpm-bare-smoke 2>/dev/null | grep -q NEEDED; then
        echo "bare executable unexpectedly links a shared library" >&2
        exit 1
    fi
    test "$(/tmp/cpm-bare-smoke/target/debug/cpm-bare-smoke)" = "bare 42"
fi

# Overriding the defaults: a board source defines its own putchar/_start. Since
# the runtime is a separate object, the strong board symbols simply override the
# weak runtime ones, with no macros. Also exercises one cminus_panic across TUs.
rm -rf /tmp/cpm-bare-override
CPM_BARE="$ROOT/lib/c-bare.h" ./cpm new /tmp/cpm-bare-override
printf '\nbare = true\n' >> /tmp/cpm-bare-override/C-.toml
cat > /tmp/cpm-bare-override/src/main.c- <<'SRC'
#include <c-.h>

int main(void)
{
    printf("override %d\n", 21 + 21);
    return 0;
}
SRC
cat > /tmp/cpm-bare-override/src/board.c- <<'SRC'
int putchar(int c)
{
    unsafe {
        unsigned char ch = (unsigned char)c;
        __asm__ volatile("syscall" : : "a"(1L), "D"(1L), "S"(&ch), "d"(1L) : "rcx", "r11", "memory");
    }
    return c;
}

void _start(void)
{
    unsafe {
        int code = main();
        __asm__ volatile("syscall" : : "a"(60L), "D"((long)code) : "memory");
    }
}
SRC
if [ "$(uname -m)" = "x86_64" ]; then
    (cd /tmp/cpm-bare-override && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" build > build.out 2>&1)
    test "$(grep -h '^void cminus_panic' /tmp/cpm-bare-override/target/debug/*.c | grep -v ';$' | wc -l)" = "1"
    test "$(/tmp/cpm-bare-override/target/debug/cpm-bare-override)" = "override 42"
fi

rm -rf /tmp/cpm-leak-smoke
./cpm new /tmp/cpm-leak-smoke
cat > /tmp/cpm-leak-smoke/src/main.c- <<'SRC'
unsafe {
#include <stdlib.h>

void* raw_alloc(size_t size)
{
    return malloc(size);
}
}

int main(void)
{
    unsafe {
        raw_alloc(16);
    }
    return 0;
}
SRC
if (cd /tmp/cpm-leak-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" val > val.out 2> val.err); then
    echo "cpm val unexpectedly missed a leak" >&2
    exit 1
fi
grep 'definitely lost' /tmp/cpm-leak-smoke/val.err >/dev/null

./c- tests/object_initializer.c- > tests/object_initializer.out.c
grep 'struct Person \*person = ({ struct Person\* __right_value' tests/object_initializer.out.c >/dev/null
grep 'cminus_gc_calloc(1, sizeof(struct Person))' tests/object_initializer.out.c >/dev/null
grep '__right_value[0-9]* = cminus_string_format("aaa");' tests/object_initializer.out.c >/dev/null
grep '__right_value[0-9]*->name = __right_value[0-9]*;' tests/object_initializer.out.c >/dev/null
grep '__right_value[0-9]*->age = 48;' tests/object_initializer.out.c >/dev/null
grep 'Person_finalize(person);' tests/object_initializer.out.c >/dev/null
grep 'cminus_gc_free(person);' tests/object_initializer.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/object_initializer.out.c -o tests/object_initializer.out
./tests/object_initializer.out

./c- tests/default_params.c- > tests/default_params.out.c
grep 'void fun(int a, int b, int c);' tests/default_params.out.c >/dev/null
grep 'void fun(int a, int b, int c)' tests/default_params.out.c >/dev/null
grep 'fun(b + 1, 22, 33);' tests/default_params.out.c >/dev/null
grep 'fun(7, 22, 9);' tests/default_params.out.c >/dev/null
grep 'fun(1, 22, 3);' tests/default_params.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/default_params.out.c -o tests/default_params.out
./tests/default_params.out

./c- tests/generics_foreach.c- > tests/generics_foreach.out.c
grep 'struct Vec_int' tests/generics_foreach.out.c >/dev/null
grep 'struct Vec_Item_ptr' tests/generics_foreach.out.c >/dev/null
grep 'Vec_first_int' tests/generics_foreach.out.c >/dev/null
grep 'Vec_len_int' tests/generics_foreach.out.c >/dev/null
grep 'Vec_pop_opt_int' tests/generics_foreach.out.c >/dev/null
grep 'Vec_get_opt_int' tests/generics_foreach.out.c >/dev/null
grep 'List_push_front_int' tests/generics_foreach.out.c >/dev/null
grep 'List_pop_front_opt_int' tests/generics_foreach.out.c >/dev/null
grep 'List_get_opt_int' tests/generics_foreach.out.c >/dev/null
grep 'struct Map_int_int' tests/generics_foreach.out.c >/dev/null
grep 'Map_get_opt_int_int' tests/generics_foreach.out.c >/dev/null
grep '__CMinusIndex_int_TAG_None' tests/generics_foreach.out.c >/dev/null
grep '__foreach' tests/generics_foreach.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/generics_foreach.out.c -o tests/generics_foreach.out
./tests/generics_foreach.out

./c- tests/field_collection_methods.c- > tests/field_collection_methods.out.c
grep 'Vec_push_int(holder->values, 10)' tests/field_collection_methods.out.c >/dev/null
grep 'List_push_int(holder->lines, 30)' tests/field_collection_methods.out.c >/dev/null
grep 'Map_set_int_int(holder->lookup, 7, 70)' tests/field_collection_methods.out.c >/dev/null
grep 'Vec_get_opt_int(holder->values, 1)' tests/field_collection_methods.out.c >/dev/null
grep 'List_get_opt_int(holder->lines, 0)' tests/field_collection_methods.out.c >/dev/null
grep 'Map_get_opt_int_int(holder->lookup, 7)' tests/field_collection_methods.out.c >/dev/null
grep 'Bitmap_set(&(slots->bits), 3)' tests/field_collection_methods.out.c >/dev/null
grep 'Bitmap_test(&(slots->bits), 3)' tests/field_collection_methods.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/field_collection_methods.out.c -o tests/field_collection_methods.out
./tests/field_collection_methods.out

./c- tests/span_language.c- > tests/span_language.out.c
grep 'struct Span_int Span_from_int' tests/span_language.out.c >/dev/null
grep 'struct Span_int Span_from_bytes_int' tests/span_language.out.c >/dev/null
grep 'Span_from_int(data, 3, 0)' tests/span_language.out.c >/dev/null
grep 'Span_from_bytes_int(data, sizeof(data), 0)' tests/span_language.out.c >/dev/null
grep 'Span_fill_int(&values, 7)' tests/span_language.out.c >/dev/null
grep 'Span_slice_int(&values, 1, 2)' tests/span_language.out.c >/dev/null
grep 'Span_copy_from_count_int(&out, tail, 2)' tests/span_language.out.c >/dev/null
grep 'Span_copy_cstr_from_int(&name, src_name)' tests/span_language.out.c >/dev/null
grep 'Span_cstr_eq_int(&name, src_name)' tests/span_language.out.c >/dev/null
grep 'Span_ptr_at_int(&(values), 1' tests/span_language.out.c >/dev/null
grep '__foreach' tests/span_language.out.c >/dev/null
grep 'values.len' tests/span_language.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_language.out.c -o tests/span_language.out
test "$(./tests/span_language.out)" = "60"

./c- tests/span_set_safe.c- > tests/span_set_safe.out.c
grep 'Span_set_int(&values, 0, 11)' tests/span_set_safe.out.c >/dev/null
grep 'Span_get_int(&values, 2)' tests/span_set_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_set_safe.out.c -o tests/span_set_safe.out
./tests/span_set_safe.out

./c- tests/string_methods.c- > tests/string_methods.out.c
grep 'cminus_string_len(text)' tests/string_methods.out.c >/dev/null
grep 'cminus_string_eq(text, "hello")' tests/string_methods.out.c >/dev/null
grep 'cminus_string_contains(text, "ell")' tests/string_methods.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/string_methods.out.c -o tests/string_methods.out
./tests/string_methods.out

if ./c- tests/bad_span_stack_len.c- > /dev/null 2> tests/bad_span_stack_len.err; then
    echo "oversized stack Span unexpectedly succeeded" >&2
    exit 1
fi
grep "buffer from length 4 exceeds array 'data' length 3" tests/bad_span_stack_len.err >/dev/null

if ./c- tests/bad_span_stack_bytes.c- > /dev/null 2> tests/bad_span_stack_bytes.err; then
    echo "oversized byte stack Span unexpectedly succeeded" >&2
    exit 1
fi
grep "buffer from_bytes length 16 exceeds array 'data' size 12 bytes" tests/bad_span_stack_bytes.err >/dev/null

./c- tests/span_field_ok.c- > tests/span_field_ok.out.c
grep 'Span_from_int(holder->data, 3, 0)' tests/span_field_ok.out.c >/dev/null
grep 'Span_from_bytes_int(holder->data, sizeof(holder->data), 0)' tests/span_field_ok.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_field_ok.out.c -o tests/span_field_ok.out
test "$(./tests/span_field_ok.out)" = "3"

./c- tests/fixed_array_safe.c- > tests/fixed_array_safe.out.c
grep 'Span_from_int(buf->data, 4, 0)' tests/fixed_array_safe.out.c >/dev/null
grep 'FixedVec_from_int(buf->data, 4, 0)' tests/fixed_array_safe.out.c >/dev/null
grep 'struct FixedVec_int FixedVec_from_int' tests/fixed_array_safe.out.c >/dev/null
grep 'FixedVec_get_opt_int' tests/fixed_array_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/fixed_array_safe.out.c -o tests/fixed_array_safe.out
./tests/fixed_array_safe.out

if ./c- tests/bad_array_const_index_safe.c- > /dev/null 2> tests/bad_array_const_index_safe.err; then
    echo "out-of-range fixed array index unexpectedly succeeded" >&2
    exit 1
fi
grep "array index 3 is out of range for 'data' length 3" tests/bad_array_const_index_safe.err >/dev/null

if ./c- tests/bad_array_var_index_safe.c- > /dev/null 2> tests/bad_array_var_index_safe.err; then
    echo "variable fixed array index unexpectedly succeeded" >&2
    exit 1
fi
grep "variable index into fixed array 'data' is not allowed in safe mode" tests/bad_array_var_index_safe.err >/dev/null

if ./c- tests/bad_span_field_len.c- > /dev/null 2> tests/bad_span_field_len.err; then
    echo "oversized field Span unexpectedly succeeded" >&2
    exit 1
fi
grep "buffer from length 4 exceeds array 'holder.data' length 3" tests/bad_span_field_len.err >/dev/null

if ./c- tests/bad_span_field_bytes.c- > /dev/null 2> tests/bad_span_field_bytes.err; then
    echo "oversized byte field Span unexpectedly succeeded" >&2
    exit 1
fi
grep "buffer from_bytes length 16 exceeds array 'holder.data' size 12 bytes" tests/bad_span_field_bytes.err >/dev/null

./c- tests/span_map_struct.c- > tests/span_map_struct.out.c
grep 'Span_map_from_Data(raw, sizeof(raw), 1, 0)' tests/span_map_struct.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_map_struct.out.c -o tests/span_map_struct.out
test "$(./tests/span_map_struct.out)" = "3 4"

./c- tests/span_map_stack_escape.c- > tests/span_map_stack_escape.out.c
grep 'Span_map_from_Data(raw, sizeof(raw), 1, 0)' tests/span_map_stack_escape.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_map_stack_escape.out.c -o tests/span_map_stack_escape.out
if ./tests/span_map_stack_escape.out > tests/span_map_stack_escape.out.log 2> tests/span_map_stack_escape.err; then
    echo "escaped mapped stack Span unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference at tests/span_map_stack_escape.c-:' tests/span_map_stack_escape.err >/dev/null

./c- tests/span_stack_escape.c- > tests/span_stack_escape.out.c
cc -std=gnu99 -Wall -Wextra tests/span_stack_escape.out.c -o tests/span_stack_escape.out
if ./tests/span_stack_escape.out > tests/span_stack_escape.out.log 2> tests/span_stack_escape.err; then
    echo "escaped stack Span unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/span_stack_escape.err >/dev/null

./c- tests/span_from_bytes_stack_escape.c- > tests/span_from_bytes_stack_escape.out.c
cc -std=gnu99 -Wall -Wextra tests/span_from_bytes_stack_escape.out.c -o tests/span_from_bytes_stack_escape.out
if ./tests/span_from_bytes_stack_escape.out > tests/span_from_bytes_stack_escape.out.log 2> tests/span_from_bytes_stack_escape.err; then
    echo "escaped stack Span.from_bytes unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/span_from_bytes_stack_escape.err >/dev/null

./c- tests/ref_stack_escape.c- > tests/ref_stack_escape.out.c
grep 'Ref_from_int(&value, 0)' tests/ref_stack_escape.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/ref_stack_escape.out.c -o tests/ref_stack_escape.out
if ./tests/ref_stack_escape.out > tests/ref_stack_escape.out.log 2> tests/ref_stack_escape.err; then
    echo "escaped stack Ref unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/ref_stack_escape.err >/dev/null

./c- tests/fixedvec_stack_escape.c- > tests/fixedvec_stack_escape.out.c
grep 'FixedVec_from_int(raw, 2, 0)' tests/fixedvec_stack_escape.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/fixedvec_stack_escape.out.c -o tests/fixedvec_stack_escape.out
if ./tests/fixedvec_stack_escape.out > tests/fixedvec_stack_escape.out.log 2> tests/fixedvec_stack_escape.err; then
    echo "escaped stack FixedVec unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/fixedvec_stack_escape.err >/dev/null

./c- tests/fixedvec_from_bytes_stack_escape.c- > tests/fixedvec_from_bytes_stack_escape.out.c
cc -std=gnu99 -Wall -Wextra tests/fixedvec_from_bytes_stack_escape.out.c -o tests/fixedvec_from_bytes_stack_escape.out
if ./tests/fixedvec_from_bytes_stack_escape.out > tests/fixedvec_from_bytes_stack_escape.out.log 2> tests/fixedvec_from_bytes_stack_escape.err; then
    echo "escaped stack FixedVec.from_bytes unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/fixedvec_from_bytes_stack_escape.err >/dev/null

./c- tests/ringbuffer_stack_escape.c- > tests/ringbuffer_stack_escape.out.c
grep 'RingBuffer_from_int(raw, 2, 0)' tests/ringbuffer_stack_escape.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/ringbuffer_stack_escape.out.c -o tests/ringbuffer_stack_escape.out
if ./tests/ringbuffer_stack_escape.out > tests/ringbuffer_stack_escape.out.log 2> tests/ringbuffer_stack_escape.err; then
    echo "escaped stack RingBuffer unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/ringbuffer_stack_escape.err >/dev/null

./c- tests/ringbuffer_from_bytes_stack_escape.c- > tests/ringbuffer_from_bytes_stack_escape.out.c
cc -std=gnu99 -Wall -Wextra tests/ringbuffer_from_bytes_stack_escape.out.c -o tests/ringbuffer_from_bytes_stack_escape.out
if ./tests/ringbuffer_from_bytes_stack_escape.out > tests/ringbuffer_from_bytes_stack_escape.out.log 2> tests/ringbuffer_from_bytes_stack_escape.err; then
    echo "escaped stack RingBuffer.from_bytes unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/ringbuffer_from_bytes_stack_escape.err >/dev/null

./c- tests/bitmap_stack_escape.c- > tests/bitmap_stack_escape.out.c
grep 'Bitmap_from_words(words, 1)' tests/bitmap_stack_escape.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/bitmap_stack_escape.out.c -o tests/bitmap_stack_escape.out
if ./tests/bitmap_stack_escape.out > tests/bitmap_stack_escape.out.log 2> tests/bitmap_stack_escape.err; then
    echo "escaped stack Bitmap unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/bitmap_stack_escape.err >/dev/null

./c- tests/bitmap_from_bits_stack_escape.c- > tests/bitmap_from_bits_stack_escape.out.c
cc -std=gnu99 -Wall -Wextra tests/bitmap_from_bits_stack_escape.out.c -o tests/bitmap_from_bits_stack_escape.out
if ./tests/bitmap_from_bits_stack_escape.out > tests/bitmap_from_bits_stack_escape.out.log 2> tests/bitmap_from_bits_stack_escape.err; then
    echo "escaped stack Bitmap.from unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/bitmap_from_bits_stack_escape.err >/dev/null

./c- tests/bitmap_from_bytes_stack_escape.c- > tests/bitmap_from_bytes_stack_escape.out.c
cc -std=gnu99 -Wall -Wextra tests/bitmap_from_bytes_stack_escape.out.c -o tests/bitmap_from_bytes_stack_escape.out
if ./tests/bitmap_from_bytes_stack_escape.out > tests/bitmap_from_bytes_stack_escape.out.log 2> tests/bitmap_from_bytes_stack_escape.err; then
    echo "escaped stack Bitmap.from_bytes unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/bitmap_from_bytes_stack_escape.err >/dev/null

./c- tests/span_panic.c- > tests/span_panic.out.c
grep 'Span_ptr_at_int(&(values), 2, "tests/span_panic.c-",' tests/span_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_panic.out.c -o tests/span_panic.out
if ./tests/span_panic.out > tests/span_panic.out.log 2> tests/span_panic.err; then
    echo "out-of-range Span index unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: index out of range at tests/span_panic.c-:' tests/span_panic.err >/dev/null

./c- tests/span_operator.c- > tests/span_operator.out.c
grep 'Span_offset_int(&values, 1, "tests/span_operator.c-",' tests/span_operator.out.c >/dev/null
grep 'Span_offset_int(&tail, -(1), "tests/span_operator.c-",' tests/span_operator.out.c >/dev/null
grep 'Span_ptr_at_int(&(tail), 0, "tests/span_operator.c-",' tests/span_operator.out.c >/dev/null
grep 'Span_ptr_at_int(&(tail), 1, "tests/span_operator.c-",' tests/span_operator.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_operator.out.c -o tests/span_operator.out
test "$(./tests/span_operator.out)" = "55"

./c- tests/span_operator_panic.c- > tests/span_operator_panic.out.c
grep 'cminus_panic("span offset out of range", file, line)' tests/span_operator_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_operator_panic.out.c -o tests/span_operator_panic.out
if ./tests/span_operator_panic.out > tests/span_operator_panic.out.log 2> tests/span_operator_panic.err; then
    echo "out-of-range Span offset unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: span offset out of range at tests/span_operator_panic.c-:' tests/span_operator_panic.err >/dev/null

./c- tests/collection_span.c- > tests/collection_span.out.c
grep 'Vec_as_span_int(vec)' tests/collection_span.out.c >/dev/null
grep 'List_to_span_int(list, list_buf, 4)' tests/collection_span.out.c >/dev/null
grep 'Map_keys_to_span_int_int(map, key_buf, 4)' tests/collection_span.out.c >/dev/null
grep 'Map_values_to_span_int_int(map, value_buf, 4)' tests/collection_span.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/collection_span.out.c -o tests/collection_span.out
test "$(./tests/collection_span.out)" = "600"

./c- tests/collection_convert.c- > tests/collection_convert.out.c
grep 'Vec_to_list_int(vec)' tests/collection_convert.out.c >/dev/null
grep 'List_to_vec_int(from_vec)' tests/collection_convert.out.c >/dev/null
grep 'Map_keys_to_vec_int_int(map)' tests/collection_convert.out.c >/dev/null
grep 'Map_values_to_list_int_int(map)' tests/collection_convert.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/collection_convert.out.c -o tests/collection_convert.out
test "$(./tests/collection_convert.out)" = "340"

./c- tests/iterator_interface.c- > tests/iterator_interface.out.c
grep 'struct Iterator_int' tests/iterator_interface.out.c >/dev/null
grep 'Vec_iter_int' tests/iterator_interface.out.c >/dev/null
grep 'List_iter_int' tests/iterator_interface.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/iterator_interface.out.c -o tests/iterator_interface.out
test "$(./tests/iterator_interface.out)" = "36"

./c- tests/register_safe.c- > tests/register_safe.out.c
grep 'struct Register_unsigned_int reg = {0};' tests/register_safe.out.c >/dev/null
grep 'volatile unsigned int\* addr;' tests/register_safe.out.c >/dev/null
grep 'Register_from_addr_unsigned_int((unsigned long)&cell)' tests/register_safe.out.c >/dev/null
grep 'Register_replace_bits_unsigned_int(&reg, 0x30u, 0x20u)' tests/register_safe.out.c >/dev/null
grep 'Register_has_bits_unsigned_int(&reg, 0x02u)' tests/register_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/register_safe.out.c -o tests/register_safe.out
./tests/register_safe.out

./c- tests/register_field_safe.c- > tests/register_field_safe.out.c
grep 'struct Register_unsigned_int status;' tests/register_field_safe.out.c >/dev/null
grep 'struct Uart uart = {0};' tests/register_field_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/register_field_safe.out.c -o tests/register_field_safe.out
./tests/register_field_safe.out

./c- tests/mmio_struct_safe.c- > tests/mmio_struct_safe.out.c
grep 'struct Register_unsigned_int status;' tests/mmio_struct_safe.out.c >/dev/null
grep 'struct Register_unsigned_int data;' tests/mmio_struct_safe.out.c >/dev/null
if grep 'mmio struct' tests/mmio_struct_safe.out.c >/dev/null; then
    echo "mmio modifier leaked into generated C" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/mmio_struct_safe.out.c -o tests/mmio_struct_safe.out
./tests/mmio_struct_safe.out

if ./c- tests/bad_mmio_pointer_field.c- > /dev/null 2> tests/bad_mmio_pointer_field.err; then
    echo "bad mmio array field unexpectedly succeeded" >&2
    exit 1
fi
grep "mmio struct fields must be scalar register values" tests/bad_mmio_pointer_field.err >/dev/null

if ./c- tests/bad_register_from_addr_safe.c- > /dev/null 2> tests/bad_register_from_addr_safe.err; then
    echo "safe Register.from_addr unexpectedly succeeded" >&2
    exit 1
fi
grep 'from_addr can only be called inside unsafe' tests/bad_register_from_addr_safe.err >/dev/null

./c- tests/interrupt_handler.c- > tests/interrupt_handler.out.c
grep '__attribute__((interrupt))' tests/interrupt_handler.out.c >/dev/null
grep 'void timer_irq(void)' tests/interrupt_handler.out.c >/dev/null
grep 'Register_set_bits_unsigned_int(&IRQ_STATUS, 0x01u)' tests/interrupt_handler.out.c >/dev/null
if sed -n '/void timer_irq(void)/,/^}/p' tests/interrupt_handler.out.c | grep 'cminus_stack_enter_impl' >/dev/null; then
    echo "interrupt handler unexpectedly has stack lifetime guard" >&2
    exit 1
fi

if ./c- tests/bad_interrupt_param.c- > /dev/null 2> tests/bad_interrupt_param.err; then
    echo "interrupt function with parameter unexpectedly succeeded" >&2
    exit 1
fi
grep 'interrupt functions must be `interrupt void name(void)`' tests/bad_interrupt_param.err >/dev/null

if ./c- tests/bad_interrupt_return.c- > /dev/null 2> tests/bad_interrupt_return.err; then
    echo "interrupt function with non-void return unexpectedly succeeded" >&2
    exit 1
fi
grep 'interrupt functions must be `interrupt void name(void)`' tests/bad_interrupt_return.err >/dev/null

if ./c- tests/bad_interrupt_new.c- > /dev/null 2> tests/bad_interrupt_new.err; then
    echo "interrupt function allocation unexpectedly succeeded" >&2
    exit 1
fi
grep 'managed heap allocation is not allowed in interrupt functions' tests/bad_interrupt_new.err >/dev/null

./c- tests/atomic_safe.c- > tests/atomic_safe.out.c
grep 'struct Atomic_unsigned_int counter = Atomic_init_unsigned_int(1u);' tests/atomic_safe.out.c >/dev/null
grep '__atomic_fetch_add' tests/atomic_safe.out.c >/dev/null
grep '__atomic_fetch_xor' tests/atomic_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/atomic_safe.out.c -o tests/atomic_safe.out
./tests/atomic_safe.out

./c- tests/thread_safe.c- > tests/thread_safe.out.c
grep 'Thread t1 = {0};' tests/thread_safe.out.c >/dev/null
grep 'Thread_spawn(worker)' tests/thread_safe.out.c >/dev/null
grep 'Mutex_lock(&gate)' tests/thread_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/thread_safe.out.c -o tests/thread_safe.out -pthread
./tests/thread_safe.out

./c- tests/critical_safe.c- > tests/critical_safe.out.c
grep 'struct Critical guard = Critical_enter();' tests/critical_safe.out.c >/dev/null
grep 'Critical_leave(&guard)' tests/critical_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/critical_safe.out.c -o tests/critical_safe.out
./tests/critical_safe.out

./c- tests/static_cell_safe.c- > tests/static_cell_safe.out.c
grep 'struct StaticCell_int cell = StaticCell_uninit_int();' tests/static_cell_safe.out.c >/dev/null
grep 'StaticCell_set_int(&cell, 10)' tests/static_cell_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/static_cell_safe.out.c -o tests/static_cell_safe.out
./tests/static_cell_safe.out

./c- tests/volatile_safe.c- > tests/volatile_safe.out.c
grep 'struct Volatile_unsigned_int cell = {0};' tests/volatile_safe.out.c >/dev/null
grep 'Volatile_from_addr_unsigned_int((unsigned long)&raw)' tests/volatile_safe.out.c >/dev/null
grep 'Volatile_write_unsigned_int(&cell, 42u)' tests/volatile_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/volatile_safe.out.c -o tests/volatile_safe.out
./tests/volatile_safe.out

if ./c- tests/bad_volatile_from_addr_safe.c- > /dev/null 2> tests/bad_volatile_from_addr_safe.err; then
    echo "safe Volatile.from_addr unexpectedly succeeded" >&2
    exit 1
fi
grep 'from_addr can only be called inside unsafe' tests/bad_volatile_from_addr_safe.err >/dev/null

./c- tests/safe_reference_surface.c- > tests/safe_reference_surface.out.c
grep 'struct Data \*make_data(void)' tests/safe_reference_surface.out.c >/dev/null
grep 'char\* text' tests/safe_reference_surface.out.c >/dev/null
grep 'struct Vec_int \*values' tests/safe_reference_surface.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/safe_reference_surface.out.c -o tests/safe_reference_surface.out
test "$(./tests/safe_reference_surface.out)" = "ok 42 42"

if ./c- tests/bad_pointer_decl_safe.c- > tests/bad_pointer_decl_safe.out.c 2> tests/bad_pointer_decl_safe.err; then
    echo "pointer declaration outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'pointer declarations are only allowed inside unsafe' tests/bad_pointer_decl_safe.err >/dev/null

if ./c- tests/bad_pointer_deref_safe.c- > tests/bad_pointer_deref_safe.out.c 2> tests/bad_pointer_deref_safe.err; then
    echo "pointer dereference outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'pointer dereference is only allowed inside unsafe' tests/bad_pointer_deref_safe.err >/dev/null

if ./c- tests/bad_pointer_deref_call_safe.c- > /dev/null 2> tests/bad_pointer_deref_call_safe.err; then
    echo "pointer return dereference outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'pointer dereference is only allowed inside unsafe' tests/bad_pointer_deref_call_safe.err >/dev/null

if ./c- tests/bad_c_string_call_safe.c- > /dev/null 2> tests/bad_c_string_call_safe.err; then
    echo "C string function outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep "C function 'strlen' can only be called inside unsafe" tests/bad_c_string_call_safe.err >/dev/null

if ./c- tests/bad_ref_raw_safe.c- > tests/bad_ref_raw_safe.out.c 2> tests/bad_ref_raw_safe.err; then
    echo "raw pointer Ref input outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'raw pointer cannot be stored in Ref in safe mode' tests/bad_ref_raw_safe.err >/dev/null

if ./c- tests/bad_span_raw_safe.c- > tests/bad_span_raw_safe.out.c 2> tests/bad_span_raw_safe.err; then
    echo "raw pointer Span input outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'raw pointer cannot be stored in Span in safe mode' tests/bad_span_raw_safe.err >/dev/null

if ./c- tests/bad_optional_raw_safe.c- > tests/bad_optional_raw_safe.out.c 2> tests/bad_optional_raw_safe.err; then
    echo "raw pointer Optional input outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'raw pointer cannot be stored in Optional in safe mode' tests/bad_optional_raw_safe.err >/dev/null

if ./c- tests/bad_raw_return_taint_safe.c- > tests/bad_raw_return_taint_safe.out.c 2> tests/bad_raw_return_taint_safe.err; then
    echo "raw pointer return taint unexpectedly reached safe Ref" >&2
    exit 1
fi
grep 'raw pointer cannot be stored in Ref in safe mode' tests/bad_raw_return_taint_safe.err >/dev/null

if ./c- tests/bad_raw_arg_taint_safe.c- > tests/bad_raw_arg_taint_safe.out.c 2> tests/bad_raw_arg_taint_safe.err; then
    echo "raw pointer argument taint unexpectedly reached safe function call" >&2
    exit 1
fi
grep "raw pointer taint cannot be passed to function 'take' in safe mode" tests/bad_raw_arg_taint_safe.err >/dev/null

if ./c- tests/bad_raw_field_taint_safe.c- > tests/bad_raw_field_taint_safe.out.c 2> tests/bad_raw_field_taint_safe.err; then
    echo "raw pointer field taint unexpectedly reached safe Span" >&2
    exit 1
fi
grep "raw pointer field 'Holder.raw' cannot be accessed in safe mode" tests/bad_raw_field_taint_safe.err >/dev/null

./c- tests/safe_to_unsafe_ok.c- > tests/safe_to_unsafe_ok.out.c
grep 'read_value(&local)' tests/safe_to_unsafe_ok.out.c >/dev/null
grep 'sum_span(data, 3)' tests/safe_to_unsafe_ok.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/safe_to_unsafe_ok.out.c -o tests/safe_to_unsafe_ok.out
test "$(./tests/safe_to_unsafe_ok.out)" = "9 11 6"

if ./c- tests/bad_unsafe_call_safe.c- > /dev/null 2> tests/bad_unsafe_call_safe.err; then
    echo "unsafe function call outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep "unsafe function 'read_raw' can only be called inside unsafe" tests/bad_unsafe_call_safe.err >/dev/null

if ./c- tests/bad_raw_return_assignment_taint_safe.c- > tests/bad_raw_return_assignment_taint_safe.out.c 2> tests/bad_raw_return_assignment_taint_safe.err; then
    echo "raw pointer return taint unexpectedly crossed safe return" >&2
    exit 1
fi
grep "raw pointer taint cannot be returned from safe function 'pass_raw'" tests/bad_raw_return_assignment_taint_safe.err >/dev/null

if ./c- tests/bad_raw_param_return_taint_safe.c- > tests/bad_raw_param_return_taint_safe.out.c 2> tests/bad_raw_param_return_taint_safe.err; then
    echo "raw pointer parameter return taint unexpectedly reached safe Ref" >&2
    exit 1
fi
grep 'raw pointer cannot be stored in Ref in safe mode' tests/bad_raw_param_return_taint_safe.err >/dev/null

if ./c- tests/bad_raw_field_arg_taint_safe.c- > tests/bad_raw_field_arg_taint_safe.out.c 2> tests/bad_raw_field_arg_taint_safe.err; then
    echo "raw pointer field taint unexpectedly crossed safe call" >&2
    exit 1
fi
grep "raw pointer field 'Holder.raw' cannot be accessed in safe mode" tests/bad_raw_field_arg_taint_safe.err >/dev/null

if ./c- tests/bad_raw_optional_return_taint_safe.c- > tests/bad_raw_optional_return_taint_safe.out.c 2> tests/bad_raw_optional_return_taint_safe.err; then
    echo "raw pointer optional taint unexpectedly crossed safe return" >&2
    exit 1
fi
grep 'raw pointer cannot be stored in Optional in safe mode' tests/bad_raw_optional_return_taint_safe.err >/dev/null

./c- tests/unsafe_pointer_deref.c- > tests/unsafe_pointer_deref.out.c
grep '\\*p' tests/unsafe_pointer_deref.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/unsafe_pointer_deref.out.c -o tests/unsafe_pointer_deref.out
test "$(./tests/unsafe_pointer_deref.out)" = "7"

./c- tests/safe_pointer_arith.c- > tests/safe_pointer_arith.out.c
grep 'ref.data++;' tests/safe_pointer_arith.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/safe_pointer_arith.out.c -o tests/safe_pointer_arith.out
./tests/safe_pointer_arith.out

if ./c- tests/cast_forbidden.c- > tests/cast_forbidden.out.c 2> tests/cast_forbidden.err; then
    echo "cast outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'cast is only allowed inside unsafe' tests/cast_forbidden.err >/dev/null

./c- tests/cast_unsafe.c- > tests/cast_unsafe.out.c
grep '(int)value' tests/cast_unsafe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/cast_unsafe.out.c -o tests/cast_unsafe.out
test "$(./tests/cast_unsafe.out)" = "8"

./c- tests/sizeof_struct_safe.c- > tests/sizeof_struct_safe.out.c
grep 'sizeof(struct Data)' tests/sizeof_struct_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/sizeof_struct_safe.out.c -o tests/sizeof_struct_safe.out
./tests/sizeof_struct_safe.out

./c- tests/gc_double_free_reuse.c- > tests/gc_double_free_reuse.out.c
grep '__cminus_gc_take_dead_fit' tests/gc_double_free_reuse.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/gc_double_free_reuse.out.c -o tests/gc_double_free_reuse.out
test "$(./tests/gc_double_free_reuse.out)" = "ok"

./c- tests/gc_header_offset.c- > tests/gc_header_offset.out.c
grep '__cminus_gc_header_from_payload(first)' tests/gc_header_offset.out.c >/dev/null
grep 'first_header->magic != __CMINUS_GC_MAGIC' tests/gc_header_offset.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/gc_header_offset.out.c -o tests/gc_header_offset.out
./tests/gc_header_offset.out

./c- tests/ref_language.c- > tests/ref_language.out.c
grep 'struct Ref_int Ref_from_int' tests/ref_language.out.c >/dev/null
grep 'struct Ref_int ref = ({ cminus_stack_note_caller_range(&value, sizeof(value)); Ref_from_int(&value' tests/ref_language.out.c >/dev/null
grep 'Ref_get_int(&ref)' tests/ref_language.out.c >/dev/null
grep 'Ref_set_int(&ref, 25)' tests/ref_language.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/ref_language.out.c -o tests/ref_language.out
test "$(./tests/ref_language.out)" = "25"

./c- tests/owned_vec_delete.c- > tests/owned_vec_delete.out.c
grep 'void OwnedVec_clear_int_ptr(struct OwnedVec_int_ptr\* self)' tests/owned_vec_delete.out.c >/dev/null
grep 'OwnedVec_clear_int_ptr(self);' tests/owned_vec_delete.out.c >/dev/null
grep 'OwnedVec_delete_int_ptr(a);' tests/owned_vec_delete.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra -Werror tests/owned_vec_delete.out.c -o tests/owned_vec_delete.out
test "$(./tests/owned_vec_delete.out)" = "1"

./c- tests/index_string_literal.c- > tests/index_string_literal.out.c
grep 'printf("a\[0\] x\[1\] = %d' tests/index_string_literal.out.c >/dev/null
grep 'Vec_get_opt_int(nums, 1)' tests/index_string_literal.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra -Werror tests/index_string_literal.out.c -o tests/index_string_literal.out
test "$(./tests/index_string_literal.out)" = "$(printf 'a[0] x[1] = 20\na')"

C_MINUS_LIB="$ROOT/lib" ./c- -bare tests/bare_metal.c- > tests/bare_metal.out.c
# -bare output must not pull in any libc header.
if grep -E '#include[[:space:]]*<' tests/bare_metal.out.c >/dev/null; then
    echo "bare output still includes a system header" >&2
    exit 1
fi
grep 'cminus_panic("index out of range", "tests/bare_metal.c-", 13)' tests/bare_metal.out.c >/dev/null
# The runtime must compile freestanding with no libc and no builtins.
cc -std=gnu99 -ffreestanding -fno-builtin -Wall -Wextra -c tests/bare_metal.out.c -o tests/bare_metal.out.o

./c- tests/index_panic.c- > tests/index_panic.out.c
cc -std=gnu99 -Wall -Wextra tests/index_panic.out.c -o tests/index_panic.out
if ./tests/index_panic.out > tests/index_panic.out.log 2> tests/index_panic.err; then
    echo "out-of-range index unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: index out of range at tests/index_panic.c-:' tests/index_panic.err >/dev/null

./c- tests/payload_enum.c- > tests/payload_enum.out.c
grep 'struct Option_int' tests/payload_enum.out.c >/dev/null
grep 'struct Option_int\* Option_int_Some' tests/payload_enum.out.c >/dev/null
grep 'Option_int_Some(123)' tests/payload_enum.out.c >/dev/null
grep 'Option_int_None()' tests/payload_enum.out.c >/dev/null
grep 'Option_int_is_Some(some)' tests/payload_enum.out.c >/dev/null
grep 'Option_int_get_Some(some)' tests/payload_enum.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/payload_enum.out.c -o tests/payload_enum.out
./tests/payload_enum.out

./c- tests/optional_language.c- > tests/optional_language.out.c
grep 'struct Optional_int make_some' tests/optional_language.out.c >/dev/null
grep 'struct Optional_int some = make_some(42);' tests/optional_language.out.c >/dev/null
grep 'Optional_int_Some(7)' tests/optional_language.out.c >/dev/null
grep 'Optional_int_is_Some(&some)' tests/optional_language.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/optional_language.out.c -o tests/optional_language.out
./tests/optional_language.out

./c- tests/clone.c- > tests/clone.out.c
grep 'Pair_clone(struct Pair\* self)' tests/clone.out.c >/dev/null
grep 'left_copy =({' tests/clone.out.c >/dev/null
grep 'right_copy =({' tests/clone.out.c >/dev/null
grep 'q =({' tests/clone.out.c >/dev/null
grep 'Pair_clone(' tests/clone.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/clone.out.c -o tests/clone.out
./tests/clone.out

./c- tests/string_clone.c- > tests/string_clone.out.c
grep 'cminus_gc_free(self->name);' tests/string_clone.out.c >/dev/null
grep 'struct Person\* Person_clone(struct Person\* self)' tests/string_clone.out.c >/dev/null
grep 'strncpy(copy->name, self->name, strlen(self->name) + 1);' tests/string_clone.out.c >/dev/null
grep 'Person_finalize(person);' tests/string_clone.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/string_clone.out.c -o tests/string_clone.out
./tests/string_clone.out

./c- tests/string_typedef.c- > tests/string_typedef.out.c
if grep 'typedef char\* string;' tests/string_typedef.out.c >/dev/null; then
    echo "string typedef unexpectedly emitted" >&2
    exit 1
fi
grep 'cminus_gc_free(self->name);' tests/string_typedef.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/string_typedef.out.c -o tests/string_typedef.out
./tests/string_typedef.out

./c- tests/borrow_string.c- > tests/borrow_string.out.c
grep 'int borrowed_len(char\* text)' tests/borrow_string.out.c >/dev/null
grep 'char\* literal = "abc";' tests/borrow_string.out.c >/dev/null
if grep 'cminus_gc_free(literal);' tests/borrow_string.out.c >/dev/null; then
    echo "borrow string unexpectedly owned" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/borrow_string.out.c -o tests/borrow_string.out
./tests/borrow_string.out

./c- tests/owned_reassign.c- > tests/owned_reassign.out.c
grep 'owned_value = calloc(1, sizeof(int));' tests/owned_reassign.out.c >/dev/null
grep 'value = calloc(1, sizeof(int));' tests/owned_reassign.out.c >/dev/null
if grep 'void\* __owned_old' tests/owned_reassign.out.c >/dev/null; then
    echo "raw calloc unexpectedly became managed" >&2
    exit 1
fi
if grep 'cminus_gc_free(__owned_old' tests/owned_reassign.out.c >/dev/null; then
    echo "raw calloc unexpectedly became managed" >&2
    exit 1
fi
cc -std=c99 -Wall -Wextra -pedantic tests/owned_reassign.out.c -o tests/owned_reassign.out
./tests/owned_reassign.out

./c- tests/owned_field_finalizer_reassign.c- > tests/owned_field_finalizer_reassign.out.c
grep 'holder->text = cminus_string_format("bbb");' tests/owned_field_finalizer_reassign.out.c >/dev/null
grep 'cminus_gc_free(__owned_old' tests/owned_field_finalizer_reassign.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/owned_field_finalizer_reassign.out.c -o tests/owned_field_finalizer_reassign.out
./tests/owned_field_finalizer_reassign.out

./c- tests/strdup_owned_reassign.c- > tests/strdup_owned_reassign.out.c
grep 'data->text = cminus_string_format("bbb");' tests/strdup_owned_reassign.out.c >/dev/null
grep 'cminus_gc_free(__owned_old' tests/strdup_owned_reassign.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/strdup_owned_reassign.out.c -o tests/strdup_owned_reassign.out
./tests/strdup_owned_reassign.out

./c- tests/owned_rvalue_call.c- > tests/owned_rvalue_call.out.c
grep 'char\* __right_value[0-9]* = x();' tests/owned_rvalue_call.out.c >/dev/null
grep 'char\* p = __right_value[0-9]* + 1;' tests/owned_rvalue_call.out.c >/dev/null
grep 'if (({ char\* __right_value[0-9]* = x(); int __right_value_cond[0-9]* = (__right_value[0-9]*) != 0;' tests/owned_rvalue_call.out.c >/dev/null
grep 'cminus_gc_free(__right_value' tests/owned_rvalue_call.out.c >/dev/null
if grep 'free(p);' tests/owned_rvalue_call.out.c >/dev/null; then
    echo "owned rvalue offset unexpectedly freed through borrowed lvalue" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/owned_rvalue_call.out.c -o tests/owned_rvalue_call.out
./tests/owned_rvalue_call.out

./c- tests/method_calls.c- > tests/method_calls.out.c
grep 'struct data \*d = cminus_gc_calloc(1, sizeof(struct data));' tests/method_calls.out.c >/dev/null
grep 'struct data \*p = cminus_gc_calloc(1, sizeof(struct data));' tests/method_calls.out.c >/dev/null
grep 'data_show(d);' tests/method_calls.out.c >/dev/null
grep 'data_show(p);' tests/method_calls.out.c >/dev/null
grep 'cminus_string_cmp("aaa", "aaa") != 0' tests/method_calls.out.c >/dev/null
grep '__typeof__((cminus_string_cmp("aaa", "aaa"))) __cminus_return' tests/method_calls.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/method_calls.out.c -o tests/method_calls.out
./tests/method_calls.out

./c- tests/dot_pointer_field.c- > tests/dot_pointer_field.out.c
grep 'child->value = 11;' tests/dot_pointer_field.out.c >/dev/null
grep 'parent->child = child;' tests/dot_pointer_field.out.c >/dev/null
grep 'parent->count = child_value(parent->child) + 1;' tests/dot_pointer_field.out.c >/dev/null
grep 'parent->child->value != 11' tests/dot_pointer_field.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/dot_pointer_field.out.c -o tests/dot_pointer_field.out
./tests/dot_pointer_field.out

if ./c- tests/bad_unknown_field.c- > /dev/null 2> tests/bad_unknown_field.err; then
    echo "unknown field unexpectedly succeeded" >&2
    exit 1
fi
grep "unknown field 'missing' in struct Data" tests/bad_unknown_field.err >/dev/null

if ./c- tests/bad_null_safe.c- > /dev/null 2> tests/bad_null_safe.err; then
    echo "safe NULL assignment unexpectedly succeeded" >&2
    exit 1
fi
grep "NULL is only allowed for Optional in safe mode" tests/bad_null_safe.err >/dev/null

if ./c- tests/bad_raw_heap_safe.c- > /dev/null 2> tests/bad_raw_heap_safe.err; then
    echo "safe raw heap call unexpectedly succeeded" >&2
    exit 1
fi
grep "raw heap function 'malloc' is only allowed inside unsafe" tests/bad_raw_heap_safe.err >/dev/null

if ./c- tests/bad_alloc_attr_safe.c- > /dev/null 2> tests/bad_alloc_attr_safe.err; then
    echo "safe alloc-attributed call unexpectedly succeeded" >&2
    exit 1
fi
grep "alloc-attributed function 'raw_alloc' is only allowed inside unsafe" tests/bad_alloc_attr_safe.err >/dev/null

if ./c- tests/bad_return_null_safe.c- > /dev/null 2> tests/bad_return_null_safe.err; then
    echo "safe return NULL unexpectedly succeeded" >&2
    exit 1
fi
grep "return NULL is only allowed for Optional in safe mode" tests/bad_return_null_safe.err >/dev/null

if ./c- tests/bad_field_null_safe.c- > /dev/null 2> tests/bad_field_null_safe.err; then
    echo "safe field NULL assignment unexpectedly succeeded" >&2
    exit 1
fi
grep "NULL is only allowed for Optional in safe mode" tests/bad_field_null_safe.err >/dev/null

if ./c- tests/bad_arg_null_safe.c- > /dev/null 2> tests/bad_arg_null_safe.err; then
    echo "safe NULL argument unexpectedly succeeded" >&2
    exit 1
fi
grep "NULL argument for parameter 'data'" tests/bad_arg_null_safe.err >/dev/null

./c- tests/optional_null_safe.c- > tests/optional_null_safe.out.c
grep 'Optional_int_None()' tests/optional_null_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/optional_null_safe.out.c -o tests/optional_null_safe.out
./tests/optional_null_safe.out

if ./c- tests/bad_use_after_move.c- > /dev/null 2> tests/bad_use_after_move.err; then
    echo "use after move unexpectedly succeeded" >&2
    exit 1
fi
grep "use of moved value 'left'" tests/bad_use_after_move.err >/dev/null

if ./c- tests/bad_borrow_after_owner_reassign.c- > /dev/null 2> tests/bad_borrow_after_owner_reassign.err; then
    echo "borrow after owner reassign unexpectedly succeeded" >&2
    exit 1
fi
grep "borrowed value 'view' is used after owner 'text' was released" tests/bad_borrow_after_owner_reassign.err >/dev/null

if ./c- tests/bad_borrow_after_owner_move.c- > /dev/null 2> tests/bad_borrow_after_owner_move.err; then
    echo "borrow after owner move unexpectedly succeeded" >&2
    exit 1
fi
grep "borrowed value 'view' is used after owner 'text' was released" tests/bad_borrow_after_owner_move.err >/dev/null

if ./c- tests/bad_borrow_after_owner_reassign_condition.c- > /dev/null 2> tests/bad_borrow_after_owner_reassign_condition.err; then
    echo "borrow after owner reassign in condition unexpectedly succeeded" >&2
    exit 1
fi
grep "borrowed value 'view' is used after owner 'text' was released" tests/bad_borrow_after_owner_reassign_condition.err >/dev/null

if ./c- tests/bad_borrow_field_after_reassign.c- > /dev/null 2> tests/bad_borrow_field_after_reassign.err; then
    echo "borrow after owned field reassign unexpectedly succeeded" >&2
    exit 1
fi
grep "borrowed value 'view' is used after owner 'holder' was released" tests/bad_borrow_field_after_reassign.err >/dev/null

if ./c- tests/bad_return_stack_ref_safe.c- > /dev/null 2> tests/bad_return_stack_ref_safe.err; then
    echo "return stack Ref unexpectedly succeeded" >&2
    exit 1
fi
grep "value 'value' cannot escape through returned safe reference" tests/bad_return_stack_ref_safe.err >/dev/null

if ./c- tests/bad_return_stack_span_safe.c- > /dev/null 2> tests/bad_return_stack_span_safe.err; then
    echo "return stack Span unexpectedly succeeded" >&2
    exit 1
fi
grep "value 'values' cannot escape through returned safe reference" tests/bad_return_stack_span_safe.err >/dev/null

if ./c- tests/bad_return_owned_borrow_safe.c- > /dev/null 2> tests/bad_return_owned_borrow_safe.err; then
    echo "return owned borrow unexpectedly succeeded" >&2
    exit 1
fi
grep "borrowed value 'view' from 'text' cannot be returned" tests/bad_return_owned_borrow_safe.err >/dev/null

if ./c- tests/bad_return_owned_field_borrow_safe.c- > /dev/null 2> tests/bad_return_owned_field_borrow_safe.err; then
    echo "return owned field borrow unexpectedly succeeded" >&2
    exit 1
fi
grep "borrowed value 'view' from 'holder' cannot be returned" tests/bad_return_owned_field_borrow_safe.err >/dev/null

if ./c- tests/bad_ref_field_safe.c- > /dev/null 2> tests/bad_ref_field_safe.err; then
    echo "Ref field in safe struct unexpectedly succeeded" >&2
    exit 1
fi
grep "Ref/Span fields are not allowed in safe structs" tests/bad_ref_field_safe.err >/dev/null

if ./c- tests/bad_span_field_safe.c- > /dev/null 2> tests/bad_span_field_safe.err; then
    echo "Span field in safe struct unexpectedly succeeded" >&2
    exit 1
fi
grep "Ref/Span fields are not allowed in safe structs" tests/bad_span_field_safe.err >/dev/null

if ./c- tests/bad_raw_arg_condition_safe.c- > /dev/null 2> tests/bad_raw_arg_condition_safe.err; then
    echo "raw pointer condition argument unexpectedly succeeded" >&2
    exit 1
fi
grep "raw pointer taint cannot be passed to function 'present' in safe mode" tests/bad_raw_arg_condition_safe.err >/dev/null

if ./c- tests/bad_raw_field_access_safe.c- > /dev/null 2> tests/bad_raw_field_access_safe.err; then
    echo "raw pointer field access unexpectedly succeeded" >&2
    exit 1
fi
grep "raw pointer field 'Holder.raw' cannot be accessed in safe mode" tests/bad_raw_field_access_safe.err >/dev/null

if ./c- tests/bad.c- > /dev/null 2> tests/borrow_new.err; then
    echo "borrow new unexpectedly succeeded" >&2
    exit 1
fi
grep "pointer declarations are only allowed inside unsafe" tests/borrow_new.err >/dev/null

./c- tests/owned_return.c- > tests/owned_return.out.c
grep 'struct Pair \*make_pair(void);' tests/owned_return.out.c >/dev/null
grep 'struct Pair \*p = make_pair();' tests/owned_return.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/owned_return.out.c -o tests/owned_return.out
./tests/owned_return.out

./c- tests/attr_malloc_return.c- > tests/attr_malloc_return.out.c
grep 'int\* p = raw_alloc(sizeof(int));' tests/attr_malloc_return.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/attr_malloc_return.out.c -o tests/attr_malloc_return.out
./tests/attr_malloc_return.out

./c- tests/attr_malloc_owned_reassign.c- > tests/attr_malloc_owned_reassign.out.c
grep 'p = raw_alloc(sizeof(int));' tests/attr_malloc_owned_reassign.out.c >/dev/null
grep 'value = raw_alloc(sizeof(int));' tests/attr_malloc_owned_reassign.out.c >/dev/null
if grep 'cminus_gc_free(__owned_old' tests/attr_malloc_owned_reassign.out.c >/dev/null; then
    echo "raw malloc unexpectedly became managed" >&2
    exit 1
fi
cc -std=c99 -Wall -Wextra -pedantic tests/attr_malloc_owned_reassign.out.c -o tests/attr_malloc_owned_reassign.out
./tests/attr_malloc_owned_reassign.out

./c- tests/s_string_owned.c- > tests/s_string_owned.out.c
grep 'char\* text;' tests/s_string_owned.out.c >/dev/null
grep 'text = cminus_string_format("aaa %d", 1+1);' tests/s_string_owned.out.c >/dev/null
grep 'cminus_gc_free(text);' tests/s_string_owned.out.c >/dev/null
test "$(grep -c 'cminus_gc_free(text);' tests/s_string_owned.out.c)" = "1"
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_owned.out.c -o tests/s_string_owned.out
./tests/s_string_owned.out

./c- tests/s_string_unbound.c- > tests/s_string_unbound.out.c
grep 'char\* text;' tests/s_string_unbound.out.c >/dev/null
grep 'text = cminus_string_format("abc");' tests/s_string_unbound.out.c >/dev/null
grep 'cminus_gc_free(text);' tests/s_string_unbound.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_unbound.out.c -o tests/s_string_unbound.out
./tests/s_string_unbound.out

./c- tests/s_string_rvalue.c- > tests/s_string_rvalue.out.c
grep 'char\* text;' tests/s_string_rvalue.out.c >/dev/null
grep 'text = cminus_string_format("abc");' tests/s_string_rvalue.out.c >/dev/null
grep 'cminus_string_eq(text, "abc")' tests/s_string_rvalue.out.c >/dev/null
grep 'cminus_gc_free(text);' tests/s_string_rvalue.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_rvalue.out.c -o tests/s_string_rvalue.out
./tests/s_string_rvalue.out

./c- tests/s_string_conditions.c- > tests/s_string_conditions.out.c
grep 'if (({' tests/s_string_conditions.out.c >/dev/null
grep 'while (({' tests/s_string_conditions.out.c >/dev/null
grep 'cminus_gc_free(__right_value' tests/s_string_conditions.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/s_string_conditions.out.c -o tests/s_string_conditions.out
./tests/s_string_conditions.out

./c- tests/generic_early_return_cleanup.c- > tests/generic_early_return_cleanup.out.c
grep 'cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);' tests/generic_early_return_cleanup.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/generic_early_return_cleanup.out.c -o tests/generic_early_return_cleanup.out
test "$(./tests/generic_early_return_cleanup.out)" = "30"

./c- tests/stack_struct.c- > tests/stack_struct.out.c
grep 'struct Data data = {0};' tests/stack_struct.out.c >/dev/null
if grep 'struct Data \*data = cminus_gc_calloc' tests/stack_struct.out.c >/dev/null; then
    echo "stack struct unexpectedly allocated managed heap" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/stack_struct.out.c -o tests/stack_struct.out
./tests/stack_struct.out

./c- -no-heap tests/no_heap_stack_ok.c- > tests/no_heap_stack_ok.out.c
grep 'struct Data data = {0};' tests/no_heap_stack_ok.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/no_heap_stack_ok.out.c -o tests/no_heap_stack_ok.out
./tests/no_heap_stack_ok.out

./c- -no-heap tests/no_heap_span_fixedvec_ok.c- > tests/no_heap_span_fixedvec_ok.out.c
grep 'struct Span_unsigned_char all = {0};' tests/no_heap_span_fixedvec_ok.out.c >/dev/null
grep 'struct FixedVec_unsigned_char used = {0};' tests/no_heap_span_fixedvec_ok.out.c >/dev/null
if grep 'cminus_gc_calloc(1, sizeof(struct Span_unsigned_char))' tests/no_heap_span_fixedvec_ok.out.c >/dev/null; then
    echo "no-heap Span metadata unexpectedly allocated managed heap" >&2
    exit 1
fi
if grep 'cminus_gc_calloc(1, sizeof(struct FixedVec_unsigned_char))' tests/no_heap_span_fixedvec_ok.out.c >/dev/null; then
    echo "no-heap FixedVec metadata unexpectedly allocated managed heap" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/no_heap_span_fixedvec_ok.out.c -o tests/no_heap_span_fixedvec_ok.out
./tests/no_heap_span_fixedvec_ok.out

./c- -no-heap tests/no_heap_ring_buffer_ok.c- > tests/no_heap_ring_buffer_ok.out.c
grep 'struct RingBuffer_int q = {0};' tests/no_heap_ring_buffer_ok.out.c >/dev/null
grep 'RingBuffer_from_int(storage.values, 3, 0)' tests/no_heap_ring_buffer_ok.out.c >/dev/null
if grep 'cminus_gc_calloc(1, sizeof(struct RingBuffer_int))' tests/no_heap_ring_buffer_ok.out.c >/dev/null; then
    echo "no-heap RingBuffer metadata unexpectedly allocated managed heap" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/no_heap_ring_buffer_ok.out.c -o tests/no_heap_ring_buffer_ok.out
./tests/no_heap_ring_buffer_ok.out

./c- -no-heap tests/no_heap_bitmap_ok.c- > tests/no_heap_bitmap_ok.out.c
grep 'Bitmap map = {0};' tests/no_heap_bitmap_ok.out.c >/dev/null
grep 'Bitmap_from_words(pages.words, 1)' tests/no_heap_bitmap_ok.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/no_heap_bitmap_ok.out.c -o tests/no_heap_bitmap_ok.out
./tests/no_heap_bitmap_ok.out

./c- -no-heap tests/no_heap_register_ok.c- > tests/no_heap_register_ok.out.c
grep 'struct Register_unsigned_int reg = {0};' tests/no_heap_register_ok.out.c >/dev/null
if grep 'cminus_gc_calloc(1, sizeof(struct Register_unsigned_int))' tests/no_heap_register_ok.out.c >/dev/null; then
    echo "no-heap Register metadata unexpectedly allocated managed heap" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/no_heap_register_ok.out.c -o tests/no_heap_register_ok.out
./tests/no_heap_register_ok.out

./c- -no-heap tests/no_heap_atomic_critical_ok.c- > tests/no_heap_atomic_critical_ok.out.c
grep 'struct Atomic_unsigned_int value = Atomic_init_unsigned_int(0u);' tests/no_heap_atomic_critical_ok.out.c >/dev/null
grep 'struct Critical guard = Critical_enter();' tests/no_heap_atomic_critical_ok.out.c >/dev/null
if grep 'cminus_gc_calloc(1, sizeof(struct Atomic_unsigned_int))' tests/no_heap_atomic_critical_ok.out.c >/dev/null; then
    echo "no-heap Atomic metadata unexpectedly allocated managed heap" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/no_heap_atomic_critical_ok.out.c -o tests/no_heap_atomic_critical_ok.out
./tests/no_heap_atomic_critical_ok.out

./c- -no-heap tests/no_heap_static_volatile_ok.c- > tests/no_heap_static_volatile_ok.out.c
grep 'struct StaticCell_int cell = StaticCell_init_int(5);' tests/no_heap_static_volatile_ok.out.c >/dev/null
grep 'struct Volatile_unsigned_int vol = {0};' tests/no_heap_static_volatile_ok.out.c >/dev/null
if grep 'cminus_gc_calloc(1, sizeof(struct StaticCell_int))' tests/no_heap_static_volatile_ok.out.c >/dev/null; then
    echo "no-heap StaticCell metadata unexpectedly allocated managed heap" >&2
    exit 1
fi
if grep 'cminus_gc_calloc(1, sizeof(struct Volatile_unsigned_int))' tests/no_heap_static_volatile_ok.out.c >/dev/null; then
    echo "no-heap Volatile metadata unexpectedly allocated managed heap" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/no_heap_static_volatile_ok.out.c -o tests/no_heap_static_volatile_ok.out
./tests/no_heap_static_volatile_ok.out

./c- -no-heap tests/no_heap_optional_ref_ok.c- > tests/no_heap_optional_ref_ok.out.c
grep 'struct Optional_int maybe = make_value(9);' tests/no_heap_optional_ref_ok.out.c >/dev/null
grep 'struct Ref_int ref = ({ cminus_stack_note_caller_range(&value, sizeof(value)); Ref_from_int(&value' tests/no_heap_optional_ref_ok.out.c >/dev/null
if grep 'cminus_gc_calloc(1, sizeof(struct Optional_int))' tests/no_heap_optional_ref_ok.out.c >/dev/null; then
    echo "no-heap Optional unexpectedly allocated managed heap" >&2
    exit 1
fi
if grep 'cminus_gc_calloc(1, sizeof(struct Ref_int))' tests/no_heap_optional_ref_ok.out.c >/dev/null; then
    echo "no-heap Ref unexpectedly allocated managed heap" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/no_heap_optional_ref_ok.out.c -o tests/no_heap_optional_ref_ok.out
./tests/no_heap_optional_ref_ok.out

if ./c- -no-heap tests/bad_no_heap_new.c- > /dev/null 2> tests/bad_no_heap_new.err; then
    echo "no-heap new unexpectedly succeeded" >&2
    exit 1
fi
grep "managed heap allocation is not allowed in no-heap functions" tests/bad_no_heap_new.err >/dev/null

if ./c- -no-heap tests/bad_no_heap_s_string.c- > /dev/null 2> tests/bad_no_heap_s_string.err; then
    echo "no-heap s string unexpectedly succeeded" >&2
    exit 1
fi
grep "s strings allocate managed heap" tests/bad_no_heap_s_string.err >/dev/null

if ./c- -no-heap tests/bad_no_heap_vec.c- > /dev/null 2> tests/bad_no_heap_vec.err; then
    echo "no-heap Vec unexpectedly succeeded" >&2
    exit 1
fi
grep "managed heap allocation is not allowed in no-heap functions" tests/bad_no_heap_vec.err >/dev/null

if ./c- -no-heap tests/bad_no_heap_clone.c- > /dev/null 2> tests/bad_no_heap_clone.err; then
    echo "no-heap clone unexpectedly succeeded" >&2
    exit 1
fi
grep "managed heap allocation is not allowed in no-heap functions" tests/bad_no_heap_clone.err >/dev/null

if ./c- tests/bad_ring_buffer_raw_safe.c- > /dev/null 2> tests/bad_ring_buffer_raw_safe.err; then
    echo "bad raw RingBuffer input unexpectedly succeeded" >&2
    exit 1
fi
grep "raw pointer cannot be stored in RingBuffer" tests/bad_ring_buffer_raw_safe.err >/dev/null

if ./c- tests/bad_bitmap_raw_safe.c- > /dev/null 2> tests/bad_bitmap_raw_safe.err; then
    echo "bad raw Bitmap input unexpectedly succeeded" >&2
    exit 1
fi
grep "raw pointer cannot be stored in Bitmap" tests/bad_bitmap_raw_safe.err >/dev/null

rm -rf /tmp/cpm-no-heap-smoke
./cpm new /tmp/cpm-no-heap-smoke
printf '\nno_heap = true\n' >> /tmp/cpm-no-heap-smoke/C-.toml
cat > /tmp/cpm-no-heap-smoke/src/main.c- <<'SRC'
struct Data {
    int value;
};

int main(void)
{
    stack Data data;

    data.value = 12;
    return data.value == 12 ? 0 : 1;
}
SRC
(cd /tmp/cpm-no-heap-smoke && CPM_C_MINUS="$ROOT/c-" "$ROOT/cpm" build > build.out 2>&1)
grep -- ' -no-heap ' /tmp/cpm-no-heap-smoke/build.out >/dev/null
/tmp/cpm-no-heap-smoke/target/debug/cpm-no-heap-smoke

if ./c- tests/bad_owned_non_pointer.c- > /dev/null 2> tests/bad_owned_non_pointer.err; then
    echo "bad owned non-pointer unexpectedly succeeded" >&2
    exit 1
fi
grep "new is only allowed for struct types" tests/bad_owned_non_pointer.err >/dev/null

if ./c- tests/bad_type_pointer_to_int.c- > /dev/null 2> tests/bad_type_pointer_to_int.err; then
    echo "bad pointer-to-int assignment unexpectedly succeeded" >&2
    exit 1
fi
grep "pointer declarations are only allowed inside unsafe" tests/bad_type_pointer_to_int.err >/dev/null

if ./c- tests/bad_type_struct.c- > /dev/null 2> tests/bad_type_struct.err; then
    echo "bad struct assignment unexpectedly succeeded" >&2
    exit 1
fi
grep "cannot assign struct B\\* to struct A\\*" tests/bad_type_struct.err >/dev/null

if ./c- tests/bad_owned_arith.c- > /dev/null 2> tests/bad_owned_arith.err; then
    echo "bad owned pointer declaration unexpectedly succeeded" >&2
    exit 1
fi
grep "pointer declarations are only allowed inside unsafe" tests/bad_owned_arith.err >/dev/null

./c- tests/unsafe_pointer_arith.c- > tests/unsafe_pointer_arith.out.c
grep 'p++;' tests/unsafe_pointer_arith.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/unsafe_pointer_arith.out.c -o tests/unsafe_pointer_arith.out
./tests/unsafe_pointer_arith.out

if ./c- tests/bad_borrow_pointer_arith.c- > /dev/null 2> tests/bad_borrow_pointer_arith.err; then
    echo "bad borrowed pointer declaration unexpectedly succeeded" >&2
    exit 1
fi
grep "pointer declarations are only allowed inside unsafe" tests/bad_borrow_pointer_arith.err >/dev/null

if ./c- tests/bad_s_string_type.c- > /dev/null 2> tests/bad_s_string_type.err; then
    echo "bad s string type unexpectedly succeeded" >&2
    exit 1
fi
grep "s string requires a char pointer declaration" tests/bad_s_string_type.err >/dev/null

echo "ok"
