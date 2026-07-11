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
#include <stdlib.h>

void* raw_alloc(size_t size)
{
    return malloc(size);
}

int main(void)
{
    raw_alloc(16);
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
grep 'asprintf(&__right_value[0-9]*, "aaa");' tests/object_initializer.out.c >/dev/null
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
cc -std=gnu99 -Wall -Wextra tests/field_collection_methods.out.c -o tests/field_collection_methods.out
./tests/field_collection_methods.out

./c- tests/span_language.c- > tests/span_language.out.c
grep 'struct Span_int\* Span_from_int' tests/span_language.out.c >/dev/null
grep 'struct Span_int\* Span_from_bytes_int' tests/span_language.out.c >/dev/null
grep 'Span_from_int(data, 3)' tests/span_language.out.c >/dev/null
grep 'Span_from_bytes_int(data, sizeof(data))' tests/span_language.out.c >/dev/null
grep 'Span_ptr_at_int(values, 1' tests/span_language.out.c >/dev/null
grep '__foreach' tests/span_language.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_language.out.c -o tests/span_language.out
test "$(./tests/span_language.out)" = "60"

./c- tests/span_panic.c- > tests/span_panic.out.c
grep 'Span_ptr_at_int(values, 2, "tests/span_panic.c-",' tests/span_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/span_panic.out.c -o tests/span_panic.out
if ./tests/span_panic.out > tests/span_panic.out.log 2> tests/span_panic.err; then
    echo "out-of-range Span index unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: index out of range at tests/span_panic.c-:' tests/span_panic.err >/dev/null

./c- tests/span_operator.c- > tests/span_operator.out.c
grep 'Span_offset_int(values, 1, "tests/span_operator.c-",' tests/span_operator.out.c >/dev/null
grep 'Span_offset_int(tail, -(1), "tests/span_operator.c-",' tests/span_operator.out.c >/dev/null
grep 'Span_ptr_at_int(tail, 0, "tests/span_operator.c-",' tests/span_operator.out.c >/dev/null
grep 'Span_ptr_at_int(tail, 1, "tests/span_operator.c-",' tests/span_operator.out.c >/dev/null
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

./c- tests/unsafe_pointer_deref.c- > tests/unsafe_pointer_deref.out.c
grep '\\*p' tests/unsafe_pointer_deref.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/unsafe_pointer_deref.out.c -o tests/unsafe_pointer_deref.out
test "$(./tests/unsafe_pointer_deref.out)" = "7"

./c- tests/safe_pointer_arith.c- > tests/safe_pointer_arith.out.c
grep 'ref->data++;' tests/safe_pointer_arith.out.c >/dev/null
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

./c- tests/ref_language.c- > tests/ref_language.out.c
grep 'struct Ref_int\* Ref_from_int' tests/ref_language.out.c >/dev/null
grep 'struct Ref_int \*ref = Ref_from_int(&value)' tests/ref_language.out.c >/dev/null
grep 'Ref_get_int(ref)' tests/ref_language.out.c >/dev/null
grep 'Ref_set_int(ref, 25)' tests/ref_language.out.c >/dev/null
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
grep 'struct Optional_int \*make_some' tests/optional_language.out.c >/dev/null
grep 'struct Optional_int \*some = make_some(42);' tests/optional_language.out.c >/dev/null
grep 'Optional_int_Some(7)' tests/optional_language.out.c >/dev/null
grep 'Optional_int_is_Some(some)' tests/optional_language.out.c >/dev/null
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
grep 'asprintf(&holder->text, "bbb");' tests/owned_field_finalizer_reassign.out.c >/dev/null
grep 'cminus_gc_free(__owned_old' tests/owned_field_finalizer_reassign.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/owned_field_finalizer_reassign.out.c -o tests/owned_field_finalizer_reassign.out
./tests/owned_field_finalizer_reassign.out

./c- tests/strdup_owned_reassign.c- > tests/strdup_owned_reassign.out.c
grep 'asprintf(&data->text, "bbb");' tests/strdup_owned_reassign.out.c >/dev/null
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
grep 'strcmp("aaa", "aaa") != 0' tests/method_calls.out.c >/dev/null
grep 'return strcmp("aaa", "aaa");' tests/method_calls.out.c >/dev/null
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
grep 'asprintf(&text, "aaa %d", 1+1);' tests/s_string_owned.out.c >/dev/null
grep 'cminus_gc_free(text);' tests/s_string_owned.out.c >/dev/null
test "$(grep -c 'cminus_gc_free(text);' tests/s_string_owned.out.c)" = "1"
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_owned.out.c -o tests/s_string_owned.out
./tests/s_string_owned.out

./c- tests/s_string_unbound.c- > tests/s_string_unbound.out.c
grep 'char\* text;' tests/s_string_unbound.out.c >/dev/null
grep 'asprintf(&text, "abc");' tests/s_string_unbound.out.c >/dev/null
grep 'cminus_gc_free(text);' tests/s_string_unbound.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_unbound.out.c -o tests/s_string_unbound.out
./tests/s_string_unbound.out

./c- tests/s_string_rvalue.c- > tests/s_string_rvalue.out.c
grep 'char\* __right_value0 = NULL;' tests/s_string_rvalue.out.c >/dev/null
grep 'asprintf(&__right_value0, "abc");' tests/s_string_rvalue.out.c >/dev/null
grep 'strcmp(__right_value0, "abc") == 0' tests/s_string_rvalue.out.c >/dev/null
grep 'cminus_gc_free(__right_value0);' tests/s_string_rvalue.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_rvalue.out.c -o tests/s_string_rvalue.out
./tests/s_string_rvalue.out

./c- tests/s_string_conditions.c- > tests/s_string_conditions.out.c
grep 'if (({' tests/s_string_conditions.out.c >/dev/null
grep 'while (({' tests/s_string_conditions.out.c >/dev/null
grep 'cminus_gc_free(__right_value' tests/s_string_conditions.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/s_string_conditions.out.c -o tests/s_string_conditions.out
./tests/s_string_conditions.out

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
