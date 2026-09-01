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

./c- tests/value_reference_syntax.c- > tests/value_reference_syntax.out.c
grep 'struct Data local = {0};' tests/value_reference_syntax.out.c >/dev/null
grep 'const struct Data \*data' tests/value_reference_syntax.out.c >/dev/null
grep 'struct Data \*data, int value' tests/value_reference_syntax.out.c >/dev/null
grep 'struct Data \*boxed = ' tests/value_reference_syntax.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/value_reference_syntax.out.c -o tests/value_reference_syntax.out
./tests/value_reference_syntax.out

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

./c- tests/aggregate_zero_init.c- > tests/aggregate_zero_init.out.c
grep 'struct State state = {0};' tests/aggregate_zero_init.out.c >/dev/null
grep 'int values\[2\] = {0};' tests/aggregate_zero_init.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/aggregate_zero_init.out.c -o tests/aggregate_zero_init.out
./tests/aggregate_zero_init.out

./c- tests/integer_overflow_panic.c- > tests/integer_overflow_panic.out.c
cc -std=gnu99 -O0 -Wall -Wextra tests/integer_overflow_panic.out.c -o tests/integer_overflow_panic.out
if ./tests/integer_overflow_panic.out > tests/integer_overflow_panic.out.log 2> tests/integer_overflow_panic.err; then
    echo "signed integer overflow unexpectedly succeeded" >&2
    exit 1
fi

./c- tests/size_overflow_panic.c- > tests/size_overflow_panic.out.c
cc -std=gnu99 -O0 -Wall -Wextra tests/size_overflow_panic.out.c -o tests/size_overflow_panic.out
if ./tests/size_overflow_panic.out > tests/size_overflow_panic.out.log 2> tests/size_overflow_panic.err; then
    echo "allocation size overflow unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: size multiplication overflow' tests/size_overflow_panic.err >/dev/null

./c- tests/stack_depth_panic.c- > tests/stack_depth_panic.out.c
cc -std=gnu99 -O0 -Wall -Wextra tests/stack_depth_panic.out.c -o tests/stack_depth_panic.out
if ./tests/stack_depth_panic.out > tests/stack_depth_panic.out.log 2> tests/stack_depth_panic.err; then
    echo "safe recursion depth limit unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: safe stack depth exceeded' tests/stack_depth_panic.err >/dev/null

./c- tests/stack_bytes_panic.c- > tests/stack_bytes_panic.out.c
grep 'CMINUS_MAX_STACK_BYTES' tests/stack_bytes_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/stack_bytes_panic.out.c \
    -o tests/stack_bytes_panic.out
if ./tests/stack_bytes_panic.out > tests/stack_bytes_panic.out.log \
    2> tests/stack_bytes_panic.err; then
    echo "stack byte budget overflow unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: safe stack byte budget exceeded' \
    tests/stack_bytes_panic.err >/dev/null

if ./c- tests/bad_large_stack_array_safe.c- > /dev/null \
    2> tests/bad_large_stack_array_safe.err; then
    echo "oversized safe local array unexpectedly succeeded" >&2
    exit 1
fi
grep "local array 'data' exceeds the safe stack object limit" \
    tests/bad_large_stack_array_safe.err >/dev/null

./c- tests/allocation_limit_panic.c- > tests/allocation_limit_panic.out.c
cc -std=gnu99 -O0 -Wall -Wextra tests/allocation_limit_panic.out.c -o tests/allocation_limit_panic.out
if ./tests/allocation_limit_panic.out > tests/allocation_limit_panic.out.log 2> tests/allocation_limit_panic.err; then
    echo "safe allocation limit unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: allocation exceeds safe limit' tests/allocation_limit_panic.err >/dev/null

if ./c- tests/bad_vla_safe.c- > /dev/null 2> tests/bad_vla_safe.err; then
    echo "safe variable-length array unexpectedly succeeded" >&2
    exit 1
fi
grep "variable-length or unsized array 'values' is only allowed inside unsafe" tests/bad_vla_safe.err >/dev/null

if ./c- tests/bad_owned_alias_safe.c- > /dev/null 2> tests/bad_owned_alias_safe.err; then
    echo "owned alias declaration unexpectedly succeeded" >&2
    exit 1
fi
grep "owned value 'first' cannot be aliased by 'second'" tests/bad_owned_alias_safe.err >/dev/null

if ./c- tests/bad_owned_grouped_alias_safe.c- > /dev/null 2> tests/bad_owned_grouped_alias_safe.err; then
    echo "parenthesized owned alias unexpectedly succeeded" >&2
    exit 1
fi
grep "owned value 'first' cannot be aliased by 'second'" tests/bad_owned_grouped_alias_safe.err >/dev/null

if ./c- tests/bad_grouped_borrow_after_move.c- > /dev/null 2> tests/bad_grouped_borrow_after_move.err; then
    echo "parenthesized borrow survived owner move" >&2
    exit 1
fi
grep "borrowed value 'view' is used after owner 'text' was released" tests/bad_grouped_borrow_after_move.err >/dev/null

if ./c- tests/bad_generic_reference_after_move.c- > /dev/null 2> tests/bad_generic_reference_after_move.err; then
    echo "generic reference to a local value unexpectedly escaped" >&2
    exit 1
fi
grep "value 'value' cannot escape through returned safe reference" tests/bad_generic_reference_after_move.err >/dev/null

if ./c- tests/bad_owned_reassign_alias_safe.c- > /dev/null 2> tests/bad_owned_reassign_alias_safe.err; then
    echo "owned alias assignment unexpectedly succeeded" >&2
    exit 1
fi
grep "owned value 'first' cannot be assigned by alias to 'second'" tests/bad_owned_reassign_alias_safe.err >/dev/null

if ./c- tests/bad_unsafe_prototype_call_safe.c- > /dev/null 2> tests/bad_unsafe_prototype_call_safe.err; then
    echo "unsafe prototype call from safe mode unexpectedly succeeded" >&2
    exit 1
fi
grep "unsafe function 'raw_value' can only be called inside unsafe" tests/bad_unsafe_prototype_call_safe.err >/dev/null

if ./c- tests/bad_variadic_function_safe.c- > /dev/null 2> tests/bad_variadic_function_safe.err; then
    echo "safe variadic function unexpectedly succeeded" >&2
    exit 1
fi
grep 'variadic functions are only allowed inside unsafe' tests/bad_variadic_function_safe.err >/dev/null

if ./c- tests/bad_union_safe.c- > /dev/null 2> tests/bad_union_safe.err; then
    echo "safe union unexpectedly succeeded" >&2
    exit 1
fi
grep 'unions are only allowed inside unsafe' tests/bad_union_safe.err >/dev/null

sh tests/fuzz_safe_mode.sh ./c- | grep 'safe-mode-fuzz-ok' >/dev/null

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

./c- --dump-typed-ast tests/inline_c_block.c- \
    > tests/inline_c_block.out.c \
    2> tests/inline_c_block.ast
grep '^    inline-c$' tests/inline_c_block.ast >/dev/null
grep '^      inline-c$' tests/inline_c_block.ast >/dev/null
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

./c- --dump-typed-ast tests/os_compile_time.c- \
    > tests/os_compile_time.out.c \
    2> tests/os_compile_time.ast
grep '_Static_assert(sizeof(struct TrapFrame) == 12, "trap frame size");' tests/os_compile_time.out.c >/dev/null
grep '_Static_assert(__builtin_offsetof(struct TrapFrame, pc) == 8, "pc offset");' tests/os_compile_time.out.c >/dev/null
grep '__attribute__((noreturn)) void halt_forever(void)' tests/os_compile_time.out.c >/dev/null
grep '^      static-assert expression=binary$' tests/os_compile_time.ast >/dev/null
grep '^          lhs offsetof name=r1 target="struct TrapFrame" type=size_t$' \
    tests/os_compile_time.ast >/dev/null
cc -std=gnu99 -Wall -Wextra -c tests/os_compile_time.out.c -o tests/os_compile_time.out.o

./c- --dump-typed-ast tests/bitflags_safe.c- \
    > tests/bitflags_safe.out.c \
    2> tests/bitflags_safe.ast
grep '^    bitflags PageFlags base=unsigned int$' tests/bitflags_safe.ast >/dev/null
grep '^      bitflag-member Present expression=literal$' tests/bitflags_safe.ast >/dev/null
grep '^      bitflag-member Write expression=literal$' tests/bitflags_safe.ast >/dev/null
grep '^      bitflag-member User expression=literal$' tests/bitflags_safe.ast >/dev/null
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

if ./c- tests/bad_ring_buffer_drain_bounds_safe.c- > /dev/null 2> tests/bad_ring_buffer_drain_bounds_safe.err; then
    echo "oversized RingBuffer drain unexpectedly succeeded" >&2
    exit 1
fi
grep "output capacity 3 exceeds array 'output' length 2" tests/bad_ring_buffer_drain_bounds_safe.err >/dev/null

./c- --dump-typed-ast tests/generic_default_params.c- \
    > tests/generic_default_params.out.c \
    2> tests/generic_default_params.ast
grep '^generic-function-template choose$' tests/generic_default_params.ast >/dev/null
grep '^  type-parameter T type=T$' tests/generic_default_params.ast >/dev/null
grep '^  return-type type=T$' tests/generic_default_params.ast >/dev/null
grep '^  parameter a type=T$' tests/generic_default_params.ast >/dev/null
grep '^  parameter b type=T default=literal$' tests/generic_default_params.ast >/dev/null
grep '^    expr literal value=20 type=int$' tests/generic_default_params.ast >/dev/null
grep '^    expr binary op=+ type=T$' tests/generic_default_params.ast >/dev/null
test "$(grep -c '^default-macro choose_int$' tests/generic_default_params.ast)" -eq 2
if grep 'type=unknown reason=' tests/generic_default_params.ast >/dev/null; then
    echo "generic default-parameter AST retained an unknown expression type" >&2
    exit 1
fi
if grep 'struct __CMinusIndex_T' tests/generic_default_params.out.c >/dev/null; then
    echo "uninstantiated generic payload helper was emitted" >&2
    exit 1
fi
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

./c- --dump-typed-ast tests/default_params.c- \
    > tests/default_params.out.c \
    2> tests/default_params.ast
grep '^    function-declaration fun$' tests/default_params.ast >/dev/null
grep '^    function fun$' tests/default_params.ast >/dev/null
test "$(grep -c '^      parameter a type=int default=binary$' tests/default_params.ast)" -eq 2
test "$(grep -c '^      parameter b type=int default=literal$' tests/default_params.ast)" -eq 2
test "$(grep -c '^      parameter c type=int default=literal$' tests/default_params.ast)" -eq 2
grep 'void fun(int a, int b, int c);' tests/default_params.out.c >/dev/null
grep 'void fun(int a, int b, int c)' tests/default_params.out.c >/dev/null
grep '^          lhs identifier name=b type=int$' tests/default_params.ast >/dev/null
if grep 'type=unknown reason=' tests/default_params.ast >/dev/null; then
    echo "default-parameter AST retained an unknown expression type" >&2
    exit 1
fi
grep 'fun(b + 1, 22, 33);' tests/default_params.out.c >/dev/null
grep 'fun(7, 22, 9);' tests/default_params.out.c >/dev/null
grep 'fun(1, 22, 3);' tests/default_params.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/default_params.out.c -o tests/default_params.out
./tests/default_params.out

./c- --dump-typed-ast tests/generics_foreach.c- \
    > tests/generics_foreach.out.c \
    2> tests/generics_foreach.ast
grep '^runtime-prelude declarations$' tests/generics_foreach.ast >/dev/null
grep '^runtime-prelude system-includes$' tests/generics_foreach.ast >/dev/null
grep '^generic-struct-template Vec$' tests/generics_foreach.ast >/dev/null
grep -A1 '^generic-struct-template Vec$' tests/generics_foreach.ast \
    | grep '^  type-parameter T type=T$' >/dev/null
grep '^generic-function-template Vec_push$' tests/generics_foreach.ast >/dev/null
grep -A2 '^generic-function-template Vec_push$' tests/generics_foreach.ast \
    | grep '^  return-type type=void$' >/dev/null
grep '^payload-enum-template Optional parameter=T$' tests/generics_foreach.ast >/dev/null
grep -A3 '^payload-enum-template Optional parameter=T$' tests/generics_foreach.ast \
    | grep '^  type-parameter T type=T$' >/dev/null
grep -A3 '^payload-enum-template Optional parameter=T$' tests/generics_foreach.ast \
    | grep '^  payload-variant Some type=T$' >/dev/null
grep -A3 '^payload-enum-template Optional parameter=T$' tests/generics_foreach.ast \
    | grep '^  payload-variant None$' >/dev/null
grep -A2 '^generic-struct-template Map$' tests/generics_foreach.ast \
    | grep '^  type-parameter K type=K$' >/dev/null
grep -A2 '^generic-struct-template Map$' tests/generics_foreach.ast \
    | grep '^  type-parameter V type=V$' >/dev/null
grep -A3 '^      declaration map expression=call$' tests/generics_foreach.ast \
    | grep '^        type type=struct Map_int_int\*% application=Map$' >/dev/null
test "$(grep -A3 '^      declaration map expression=call$' tests/generics_foreach.ast \
    | grep -c '^          type-argument type=int$')" -eq 2
if grep 'type type=Vec_push<T> application=Vec_push' tests/generics_foreach.ast >/dev/null; then
    echo "generic function call was misclassified as a declaration type" >&2
    exit 1
fi
grep '^generic-struct Vec_int$' tests/generics_foreach.ast >/dev/null
grep '^  struct Vec_int$' tests/generics_foreach.ast >/dev/null
grep '^    field data$' tests/generics_foreach.ast >/dev/null
grep -A1 '^    field data$' tests/generics_foreach.ast \
    | grep '^      type type=int\*$' >/dev/null
grep '^generic-prototype Vec_new_int$' tests/generics_foreach.ast >/dev/null
grep '^  function-declaration Vec_new_int$' tests/generics_foreach.ast >/dev/null
grep '^generic-function Vec_new_int$' tests/generics_foreach.ast >/dev/null
grep '^  function Vec_new_int$' tests/generics_foreach.ast >/dev/null
grep '^generic-function Vec_push_int$' tests/generics_foreach.ast >/dev/null
grep -A20 '^generic-function Vec_push_int$' tests/generics_foreach.ast \
    | grep '^            receiver identifier name=self type=struct Vec_int\*$' >/dev/null
grep -A20 '^generic-function Vec_push_int$' tests/generics_foreach.ast \
    | grep '^          callee identifier name=cminus_checked_int_mul type=fn()->int$' >/dev/null
grep '^          callee identifier name=Vec_push_int type=fn()->void$' \
    tests/generics_foreach.ast >/dev/null
grep '^              callee identifier name=Vec_len_int type=fn()->int$' \
    tests/generics_foreach.ast >/dev/null
grep '^          callee identifier name=Map_set_int_int type=fn()->int$' \
    tests/generics_foreach.ast >/dev/null
if grep -E 'callee identifier name=(Vec|List|Map)_[A-Za-z0-9_]+ type=unknown' \
    tests/generics_foreach.ast >/dev/null; then
    echo "concrete generic call remained unresolved in final AST" >&2
    exit 1
fi
grep '^    function Bitmap_from_impl$' tests/generics_foreach.ast >/dev/null
grep '^      parameter words type=long\*$' tests/generics_foreach.ast >/dev/null
grep '^          callee identifier name=Bitmap_word_shift type=fn()->int$' \
    tests/generics_foreach.ast >/dev/null
grep '^          callee identifier name=Bitmap_find_zero type=fn()->struct __CMinusIndex_int$' \
    tests/generics_foreach.ast >/dev/null
grep '^          callee identifier name=__CMinusIndex_int_is_Some type=fn()->int$' \
    tests/generics_foreach.ast >/dev/null
grep '^              callee identifier name=__CMinusIndex_int_get_Some type=fn()->int$' \
    tests/generics_foreach.ast >/dev/null
if grep -E 'callee identifier name=(Bitmap_|__CMinusIndex_int_)[A-Za-z0-9_]* type=unknown' \
    tests/generics_foreach.ast >/dev/null; then
    echo "Bitmap or payload helper call remained unresolved in final AST" >&2
    exit 1
fi
grep '^      callee identifier name=__atomic_store_n type=fn()->void$' \
    tests/generics_foreach.ast >/dev/null
grep '^      callee identifier name=__atomic_load_n type=fn()->T$' \
    tests/generics_foreach.ast >/dev/null
grep '^      callee identifier name=__atomic_compare_exchange_n type=fn()->int$' \
    tests/generics_foreach.ast >/dev/null
grep '^          callee identifier name=__builtin_va_start type=fn()->void$' \
    tests/generics_foreach.ast >/dev/null
grep '^            callee identifier name=vsnprintf type=fn()->int$' \
    tests/generics_foreach.ast >/dev/null
grep '^          callee identifier name=fopen type=fn()->FILE\* raw$' \
    tests/generics_foreach.ast >/dev/null
grep '^      operand alignof target="T" op=_Alignof type=size_t$' \
    tests/generics_foreach.ast >/dev/null
grep '^      rhs identifier name=NULL type=struct Atomic\* raw$' \
    tests/generics_foreach.ast >/dev/null
grep '^      expr identifier name=NULL type=struct __CMinusGCHeader\* raw$' \
    tests/generics_foreach.ast >/dev/null
grep '^            argument identifier name=NULL type=pthread_attr_t\* raw$' \
    tests/generics_foreach.ast >/dev/null
grep '^            argument identifier name=NULL type=void\*\* raw$' \
    tests/generics_foreach.ast >/dev/null
if grep 'identifier name=NULL type=unknown reason=unresolved-symbol' \
    tests/generics_foreach.ast >/dev/null; then
    echo "NULL was classified as an unresolved symbol instead of a contextual literal" >&2
    exit 1
fi
grep '^  field next_fn$' tests/generics_foreach.ast >/dev/null
grep '^    type type=fn()->struct __CMinusIndex$' \
    tests/generics_foreach.ast >/dev/null
grep '^  parameter next_fn type=fn()->struct __CMinusIndex$' \
    tests/generics_foreach.ast >/dev/null
grep '^      callee member name=next_fn op=-> type=fn()->struct __CMinusIndex$' \
    tests/generics_foreach.ast >/dev/null
grep -A8 '^generic-function-template Map_clear$' tests/generics_foreach.ast \
    | grep '^  parameter self type=struct Map\* raw$' >/dev/null
grep -A18 '^generic-function-template Map_clear$' tests/generics_foreach.ast \
    | grep '^      argument member name=keys op=-> type=K\* raw$' >/dev/null
if grep 'identifier name=NULL type=unknown' tests/generics_foreach.ast >/dev/null; then
    echo "contextual NULL remained unresolved after member typing" >&2
    exit 1
fi
grep '^      callee member name=from op=. type=fn()->struct Span$' \
    tests/generics_foreach.ast >/dev/null
grep '^          callee member name=get op=. type=fn()->T$' \
    tests/generics_foreach.ast >/dev/null
grep '^            body-expression member name=Some op=. result=yes type=int$' \
    tests/generics_foreach.ast >/dev/null
grep '^          lhs statement-expression type=int$' \
    tests/generics_foreach.ast >/dev/null
grep '^              receiver identifier name=item type=struct Item\*$' \
    tests/generics_foreach.ast >/dev/null
grep '^        receiver generic generic=T type=type Span$' \
    tests/generics_foreach.ast >/dev/null
grep '^          lhs identifier name=Span type=type Span$' \
    tests/generics_foreach.ast >/dev/null
grep '^          argument identifier name=stderr type=FILE\* raw$' \
    tests/generics_foreach.ast >/dev/null
grep '^            rhs identifier name=__CMINUS_GC_MAGIC type=long$' \
    tests/generics_foreach.ast >/dev/null
grep '^          expr identifier name=__cminus_return0 type=struct Optional_FILE_ptr$' \
    tests/generics_foreach.ast >/dev/null
if grep -E 'type=unknown reason=(unresolved-member-type|unresolved-call-return|unresolved-statement-result|unknown-operand-type)' \
    tests/generics_foreach.ast >/dev/null; then
    echo "resolvable expression type remained unknown in final AST" >&2
    exit 1
fi
if grep 'type=unknown reason=' tests/generics_foreach.ast >/dev/null; then
    echo "expression type remained unknown in final AST" >&2
    exit 1
fi
if grep 'callee identifier name=.* type=unknown' tests/generics_foreach.ast >/dev/null; then
    echo "function call remained unresolved in final AST" >&2
    exit 1
fi
grep '^    declaration next_cap expression=conditional$' tests/generics_foreach.ast >/dev/null
grep '^    if expression=binary$' tests/generics_foreach.ast >/dev/null
grep '^payload-helpers payload-enums$' tests/generics_foreach.ast >/dev/null
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

./c- tests/ast_nested_method_lowering.c- > tests/ast_nested_method_lowering.out.c
grep 'cminus_string_eq(text, cminus_string_starts_with(text, "a") ? "abc" : "")' tests/ast_nested_method_lowering.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/ast_nested_method_lowering.out.c -o tests/ast_nested_method_lowering.out
./tests/ast_nested_method_lowering.out

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

./c- --dump-typed-ast tests/fixed_array_safe.c- \
    > tests/fixed_array_safe.out.c \
    2> tests/fixed_array_safe.ast
grep -A3 '^    struct Buffer$' tests/fixed_array_safe.ast \
    | grep '^      field data$' >/dev/null
grep -A3 '^    struct Buffer$' tests/fixed_array_safe.ast \
    | grep '^          array-dimension length=4$' >/dev/null
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

if ./c- tests/bad_array_parenthesized_var_index_safe.c- > /dev/null 2> tests/bad_array_parenthesized_var_index_safe.err; then
    echo "parenthesized variable fixed array index unexpectedly succeeded" >&2
    exit 1
fi
grep "variable index into fixed array 'values' is not allowed in safe mode" tests/bad_array_parenthesized_var_index_safe.err >/dev/null

if ./c- tests/bad_array_nested_parenthesized_var_index_safe.c- > /dev/null 2> tests/bad_array_nested_parenthesized_var_index_safe.err; then
    echo "nested parenthesized variable fixed array index unexpectedly succeeded" >&2
    exit 1
fi
grep "variable index into fixed array 'values' is not allowed in safe mode" tests/bad_array_nested_parenthesized_var_index_safe.err >/dev/null

if ./c- tests/bad_array_pointer_arithmetic_safe.c- > /dev/null 2> tests/bad_array_pointer_arithmetic_safe.err; then
    echo "fixed array pointer arithmetic unexpectedly succeeded" >&2
    exit 1
fi
grep "fixed array 'values' cannot decay to a raw pointer in safe mode" tests/bad_array_pointer_arithmetic_safe.err >/dev/null

if ./c- tests/bad_array_address_subscript_safe.c- > /dev/null 2> tests/bad_array_address_subscript_safe.err; then
    echo "fixed array element address subscript unexpectedly succeeded" >&2
    exit 1
fi
grep "taking the raw address of fixed array 'values' element is only allowed inside unsafe" tests/bad_array_address_subscript_safe.err >/dev/null

if ./c- tests/bad_array_comma_decay_safe.c- > /dev/null 2> tests/bad_array_comma_decay_safe.err; then
    echo "fixed array comma decay unexpectedly succeeded" >&2
    exit 1
fi
grep "fixed array 'values' cannot decay to a raw pointer in safe mode" tests/bad_array_comma_decay_safe.err >/dev/null

if ./c- tests/bad_initialized_array_var_index_safe.c- > /dev/null 2> tests/bad_initialized_array_var_index_safe.err; then
    echo "initialized fixed array variable index unexpectedly succeeded" >&2
    exit 1
fi
grep "variable index into fixed array 'values' is not allowed in safe mode" tests/bad_initialized_array_var_index_safe.err >/dev/null

if ./c- tests/bad_array_comment_index_safe.c- > /dev/null 2> tests/bad_array_comment_index_safe.err; then
    echo "comment-separated fixed array variable index unexpectedly succeeded" >&2
    exit 1
fi
grep "variable index into fixed array 'values' is not allowed in safe mode" tests/bad_array_comment_index_safe.err >/dev/null

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

./c- tests/optional_ref_language.c- > tests/optional_ref_language.out.c
test "$(grep -c '^struct Optional_Ref_int{' tests/optional_ref_language.out.c)" = "1"
cc -std=gnu99 -Wall -Wextra tests/optional_ref_language.out.c -o tests/optional_ref_language.out
./tests/optional_ref_language.out

./c- tests/optional_ref_stack_escape.c- > tests/optional_ref_stack_escape.out.c
test "$(grep -c '^struct Optional_Ref_int{' tests/optional_ref_stack_escape.out.c)" = "1"
cc -std=gnu99 -Wall -Wextra tests/optional_ref_stack_escape.out.c -o tests/optional_ref_stack_escape.out
if ./tests/optional_ref_stack_escape.out > tests/optional_ref_stack_escape.out.log 2> tests/optional_ref_stack_escape.err; then
    echo "escaped stack Ref inside Optional unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/optional_ref_stack_escape.err >/dev/null

./c- tests/optional_span_stack_escape.c- > tests/optional_span_stack_escape.out.c
test "$(grep -c '^struct Optional_Span_int{' tests/optional_span_stack_escape.out.c)" = "1"
cc -std=gnu99 -Wall -Wextra tests/optional_span_stack_escape.out.c -o tests/optional_span_stack_escape.out
if ./tests/optional_span_stack_escape.out > tests/optional_span_stack_escape.out.log 2> tests/optional_span_stack_escape.err; then
    echo "escaped stack Span inside Optional unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: dangling stack reference' tests/optional_span_stack_escape.err >/dev/null

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

if ./c- tests/bad_list_to_span_var_capacity_safe.c- > /dev/null 2> tests/bad_list_to_span_var_capacity_safe.err; then
    echo "variable List output capacity unexpectedly succeeded" >&2
    exit 1
fi
grep "variable output capacity for fixed array 'output' is not allowed in safe mode" tests/bad_list_to_span_var_capacity_safe.err >/dev/null

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

./c- tests/atomic_invalid_order_panic.c- \
    > tests/atomic_invalid_order_panic.out.c
grep 'cminus_atomic_require_load_order(order)' \
    tests/atomic_invalid_order_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/atomic_invalid_order_panic.out.c \
    -o tests/atomic_invalid_order_panic.out
if ./tests/atomic_invalid_order_panic.out \
    > tests/atomic_invalid_order_panic.out.log \
    2> tests/atomic_invalid_order_panic.err; then
    echo "invalid atomic load order unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: invalid atomic load memory order' \
    tests/atomic_invalid_order_panic.err >/dev/null

./c- tests/thread_safe.c- > tests/thread_safe.out.c
grep 'Thread t1 = {0};' tests/thread_safe.out.c >/dev/null
grep 'Thread_spawn(worker)' tests/thread_safe.out.c >/dev/null
grep 'Mutex_lock(&gate)' tests/thread_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/thread_safe.out.c -o tests/thread_safe.out -pthread
./tests/thread_safe.out

./c- tests/thread_owned_send_safe.c- > tests/thread_owned_send_safe.out.c
grep 'Thread_spawn_context((void\*)work, __cminus_thread_owned_entry_' \
    tests/thread_owned_send_safe.out.c >/dev/null
grep 'return consume((struct Work\*)__cminus_raw);' \
    tests/thread_owned_send_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/thread_owned_send_safe.out.c \
    -o tests/thread_owned_send_safe.out -pthread
./tests/thread_owned_send_safe.out

./c- tests/thread_nested_send_safe.c- > tests/thread_nested_send_safe.out.c
cc -std=gnu99 -Wall -Wextra tests/thread_nested_send_safe.out.c \
    -o tests/thread_nested_send_safe.out -pthread
./tests/thread_nested_send_safe.out

./c- tests/thread_recursive_send_safe.c- \
    > tests/thread_recursive_send_safe.out.c
cc -std=gnu99 -Wall -Wextra tests/thread_recursive_send_safe.out.c \
    -o tests/thread_recursive_send_safe.out -pthread
./tests/thread_recursive_send_safe.out

./c- tests/thread_multiple_send_safe.c- \
    > tests/thread_multiple_send_safe.out.c
grep '__cminus_thread_owned_spawn_' \
    tests/thread_multiple_send_safe.out.c >/dev/null
grep 'cminus_gc_free(__cminus_context);' \
    tests/thread_multiple_send_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/thread_multiple_send_safe.out.c \
    -o tests/thread_multiple_send_safe.out -pthread
./tests/thread_multiple_send_safe.out

if ./c- tests/bad_thread_owned_without_move_safe.c- > /dev/null \
    2> tests/bad_thread_owned_without_move_safe.err; then
    echo "owned thread argument without move unexpectedly succeeded" >&2
    exit 1
fi
grep "capture 1 requires 'move value'" \
    tests/bad_thread_owned_without_move_safe.err >/dev/null

if ./c- tests/bad_thread_multiple_missing_move_safe.c- > /dev/null \
    2> tests/bad_thread_multiple_missing_move_safe.err; then
    echo "thread capture without move unexpectedly succeeded" >&2
    exit 1
fi
grep "capture 2 requires 'move value'" \
    tests/bad_thread_multiple_missing_move_safe.err >/dev/null

if ./c- tests/bad_thread_multiple_duplicate_move_safe.c- > /dev/null \
    2> tests/bad_thread_multiple_duplicate_move_safe.err; then
    echo "duplicate thread capture move unexpectedly succeeded" >&2
    exit 1
fi
grep "cannot move 'work' more than once" \
    tests/bad_thread_multiple_duplicate_move_safe.err >/dev/null

if ./c- tests/bad_thread_multiple_worker_order_safe.c- > /dev/null \
    2> tests/bad_thread_multiple_worker_order_safe.err; then
    echo "out-of-order thread worker parameters unexpectedly succeeded" >&2
    exit 1
fi
grep "parameter 1 must be owned and match moved value 'left'" \
    tests/bad_thread_multiple_worker_order_safe.err >/dev/null

if ./c- tests/bad_thread_non_send_safe.c- > /dev/null \
    2> tests/bad_thread_non_send_safe.err; then
    echo "non-Send thread argument unexpectedly succeeded" >&2
    exit 1
fi
grep "is not Send" tests/bad_thread_non_send_safe.err >/dev/null

if ./c- tests/bad_thread_nested_non_send_safe.c- > /dev/null \
    2> tests/bad_thread_nested_non_send_safe.err; then
    echo "nested non-Send thread argument unexpectedly succeeded" >&2
    exit 1
fi
grep "moved value 'work'.*is not Send" \
    tests/bad_thread_nested_non_send_safe.err >/dev/null

if ./c- tests/bad_thread_owned_use_after_move_safe.c- > /dev/null \
    2> tests/bad_thread_owned_use_after_move_safe.err; then
    echo "thread argument remained usable after move" >&2
    exit 1
fi
grep "use of moved value 'work'" \
    tests/bad_thread_owned_use_after_move_safe.err >/dev/null

if ./c- tests/bad_thread_owned_worker_type_safe.c- > /dev/null \
    2> tests/bad_thread_owned_worker_type_safe.err; then
    echo "mismatched owned thread worker unexpectedly succeeded" >&2
    exit 1
fi
grep "parameter 1 must be owned and match moved value 'work'" \
    tests/bad_thread_owned_worker_type_safe.err >/dev/null

if ./c- tests/bad_thread_owned_global_access_safe.c- > /dev/null \
    2> tests/bad_thread_owned_global_access_safe.err; then
    echo "owned thread worker ordinary global access unexpectedly succeeded" >&2
    exit 1
fi
grep "Thread.spawn entry 'consume' accesses ordinary global 'shared_value'" \
    tests/bad_thread_owned_global_access_safe.err >/dev/null

./c- tests/gc_thread_stress.c- > tests/gc_thread_stress.out.c
grep '__cminus_gc_lock' tests/gc_thread_stress.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/gc_thread_stress.out.c \
    -o tests/gc_thread_stress.out -pthread
./tests/gc_thread_stress.out

./c- tests/thread_detach_safe.c- > tests/thread_detach_safe.out.c
grep '__cminus_thread_state_release' tests/thread_detach_safe.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/thread_detach_safe.out.c \
    -o tests/thread_detach_safe.out -pthread
./tests/thread_detach_safe.out

if ./c- tests/bad_thread_global_access_safe.c- > /dev/null \
    2> tests/bad_thread_global_access_safe.err; then
    echo "thread entry ordinary global access unexpectedly succeeded" >&2
    exit 1
fi
grep "Thread.spawn entry 'worker' accesses ordinary global 'shared_value'" \
    tests/bad_thread_global_access_safe.err >/dev/null

if ./c- tests/bad_thread_transitive_global_safe.c- > /dev/null \
    2> tests/bad_thread_transitive_global_safe.err; then
    echo "transitive thread global access unexpectedly succeeded" >&2
    exit 1
fi
grep "Thread.spawn entry 'worker' accesses ordinary global 'shared_value'" \
    tests/bad_thread_transitive_global_safe.err >/dev/null

if ./c- tests/bad_thread_copy_safe.c- > /dev/null \
    2> tests/bad_thread_copy_safe.err; then
    echo "Thread resource copy unexpectedly succeeded" >&2
    exit 1
fi
grep "runtime resource 'first' cannot be copied" \
    tests/bad_thread_copy_safe.err >/dev/null

if ./c- tests/bad_mutex_copy_safe.c- > /dev/null \
    2> tests/bad_mutex_copy_safe.err; then
    echo "Mutex resource copy unexpectedly succeeded" >&2
    exit 1
fi
grep "runtime resource 'first' cannot be copied" \
    tests/bad_mutex_copy_safe.err >/dev/null

if ./c- tests/bad_resource_parameter_safe.c- > /dev/null \
    2> tests/bad_resource_parameter_safe.err; then
    echo "runtime resource value parameter unexpectedly succeeded" >&2
    exit 1
fi
grep "runtime resource parameter 'value' must use ref or mut ref" \
    tests/bad_resource_parameter_safe.err >/dev/null

if ./c- tests/bad_resource_field_safe.c- > /dev/null \
    2> tests/bad_resource_field_safe.err; then
    echo "runtime resource struct field unexpectedly succeeded" >&2
    exit 1
fi
grep "runtime resource fields are not allowed in safe structs for field 'WorkerState.gate'" \
    tests/bad_resource_field_safe.err >/dev/null

if ./c- tests/bad_owning_struct_copy_safe.c- > /dev/null \
    2> tests/bad_owning_struct_copy_safe.err; then
    echo "owning struct copy unexpectedly succeeded" >&2
    exit 1
fi
grep "owning struct 'first' cannot be copied in safe mode" \
    tests/bad_owning_struct_copy_safe.err >/dev/null

./c- tests/owning_struct_return.c- > tests/owning_struct_return.out.c
grep 'Message_finalize(&message)' tests/owning_struct_return.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/owning_struct_return.out.c \
    -o tests/owning_struct_return.out
./tests/owning_struct_return.out

if ./c- tests/bad_owning_struct_parameter_safe.c- > /dev/null \
    2> tests/bad_owning_struct_parameter_safe.err; then
    echo "owning struct value parameter unexpectedly succeeded" >&2
    exit 1
fi
grep "owning struct parameter 'value' must use ref or mut ref" \
    tests/bad_owning_struct_parameter_safe.err >/dev/null

if ./c- tests/bad_extern_function_safe.c- > /dev/null \
    2> tests/bad_extern_function_safe.err; then
    echo "safe extern function declaration unexpectedly succeeded" >&2
    exit 1
fi
grep "extern functions must be declared inside unsafe" \
    tests/bad_extern_function_safe.err >/dev/null

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

if ./c- tests/bad_pointer_deref_parenthesized_safe.c- > /dev/null 2> tests/bad_pointer_deref_parenthesized_safe.err; then
    echo "parenthesized pointer dereference outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'pointer dereference is only allowed inside unsafe' tests/bad_pointer_deref_parenthesized_safe.err >/dev/null

if ./c- tests/bad_pointer_deref_nested_parenthesized_safe.c- > /dev/null 2> tests/bad_pointer_deref_nested_parenthesized_safe.err; then
    echo "nested parenthesized pointer dereference outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'pointer dereference is only allowed inside unsafe' tests/bad_pointer_deref_nested_parenthesized_safe.err >/dev/null

if ./c- tests/bad_pointer_deref_address_safe.c- > /dev/null 2> tests/bad_pointer_deref_address_safe.err; then
    echo "address-of pointer dereference outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'pointer dereference is only allowed inside unsafe' tests/bad_pointer_deref_address_safe.err >/dev/null

if ./c- tests/bad_array_decay_deref_safe.c- > /dev/null 2> tests/bad_array_decay_deref_safe.err; then
    echo "array decay dereference outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'pointer dereference is only allowed inside unsafe' tests/bad_array_decay_deref_safe.err >/dev/null

if ./c- tests/bad_pointer_subscript_safe.c- > /dev/null 2> tests/bad_pointer_subscript_safe.err; then
    echo "raw pointer subscript outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'raw pointer dereference is only allowed inside unsafe' tests/bad_pointer_subscript_safe.err >/dev/null

if ./c- tests/bad_raw_pointer_arrow_safe.c- > /dev/null 2> tests/bad_raw_pointer_arrow_safe.err; then
    echo "raw pointer arrow access outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'raw pointer dereference is only allowed inside unsafe' tests/bad_raw_pointer_arrow_safe.err >/dev/null

if ./c- tests/bad_parenthesized_pointer_subscript_safe.c- > /dev/null 2> tests/bad_parenthesized_pointer_subscript_safe.err; then
    echo "parenthesized raw pointer subscript outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'raw pointer dereference is only allowed inside unsafe' tests/bad_parenthesized_pointer_subscript_safe.err >/dev/null

if ./c- tests/bad_parenthesized_raw_pointer_arrow_safe.c- > /dev/null 2> tests/bad_parenthesized_raw_pointer_arrow_safe.err; then
    echo "parenthesized raw pointer arrow access outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'raw pointer dereference is only allowed inside unsafe' tests/bad_parenthesized_raw_pointer_arrow_safe.err >/dev/null

if ./c- tests/bad_c_string_call_safe.c- > /dev/null 2> tests/bad_c_string_call_safe.err; then
    echo "C string function outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep "C function 'strlen' can only be called inside unsafe" tests/bad_c_string_call_safe.err >/dev/null

if ./c- tests/bad_parenthesized_c_call_safe.c- > /dev/null 2> tests/bad_parenthesized_c_call_safe.err; then
    echo "parenthesized C function call outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep "C function 'memcpy' can only be called inside unsafe" tests/bad_parenthesized_c_call_safe.err >/dev/null

if ./c- tests/bad_ref_raw_safe.c- > tests/bad_ref_raw_safe.out.c 2> tests/bad_ref_raw_safe.err; then
    echo "raw pointer Ref input outside unsafe unexpectedly succeeded" >&2
    exit 1
fi
grep 'raw pointer cannot be stored in Ref in safe mode' tests/bad_ref_raw_safe.err >/dev/null

if ./c- tests/bad_raw_pointer_comma_input_safe.c- > /dev/null 2> tests/bad_raw_pointer_comma_input_safe.err; then
    echo "raw pointer hidden in comma expression unexpectedly entered Ref" >&2
    exit 1
fi
grep 'raw pointer cannot be stored in Ref in safe mode' tests/bad_raw_pointer_comma_input_safe.err >/dev/null

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

./c- --dump-typed-ast tests/safe_to_unsafe_ok.c- \
    > tests/safe_to_unsafe_ok.out.c \
    2> tests/safe_to_unsafe_ok.ast
grep '^    unsafe$' tests/safe_to_unsafe_ok.ast >/dev/null
grep '^      function read_value$' tests/safe_to_unsafe_ok.ast >/dev/null
grep '^        parameter value type=int\* raw$' tests/safe_to_unsafe_ok.ast >/dev/null
grep '^          expr dereference op=\* type=int$' tests/safe_to_unsafe_ok.ast >/dev/null
grep '^      function sum_span$' tests/safe_to_unsafe_ok.ast >/dev/null
grep '^            lhs identifier name=i type=int$' tests/safe_to_unsafe_ok.ast >/dev/null
grep '^                receiver identifier name=values type=int\* raw$' \
    tests/safe_to_unsafe_ok.ast >/dev/null
grep '^      unsafe$' tests/safe_to_unsafe_ok.ast >/dev/null
grep '^        assignment expression=binary$' tests/safe_to_unsafe_ok.ast >/dev/null
if grep 'type=unknown reason=' tests/safe_to_unsafe_ok.ast >/dev/null; then
    echo "unsafe-boundary AST retained an unknown expression type" >&2
    exit 1
fi
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
grep 'reference.data++;' tests/safe_pointer_arith.out.c >/dev/null
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

./c- tests/managed_reference_reuse_panic.c- \
    > tests/managed_reference_reuse_panic.out.c
grep '__cminus_gc_find_live_containing' \
    tests/managed_reference_reuse_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/managed_reference_reuse_panic.out.c \
    -o tests/managed_reference_reuse_panic.out
if ./tests/managed_reference_reuse_panic.out \
    > tests/managed_reference_reuse_panic.out.log \
    2> tests/managed_reference_reuse_panic.err; then
    echo "stale managed reference survived allocation reuse" >&2
    exit 1
fi
grep 'panic: dangling managed heap reference' \
    tests/managed_reference_reuse_panic.err >/dev/null

./c- tests/gc_interior_free_panic.c- \
    > tests/gc_interior_free_panic.out.c
cc -std=gnu99 -Wall -Wextra tests/gc_interior_free_panic.out.c \
    -o tests/gc_interior_free_panic.out
if ./tests/gc_interior_free_panic.out \
    > tests/gc_interior_free_panic.out.log \
    2> tests/gc_interior_free_panic.err; then
    echo "interior managed pointer free unexpectedly succeeded" >&2
    exit 1
fi
grep 'panic: cannot free interior managed pointer' \
    tests/gc_interior_free_panic.err >/dev/null

./c- tests/managed_optional_ref_panic.c- \
    > tests/managed_optional_ref_panic.out.c
grep 'cminus_ptr_classify' tests/managed_optional_ref_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/managed_optional_ref_panic.out.c \
    -o tests/managed_optional_ref_panic.out
if ./tests/managed_optional_ref_panic.out \
    > tests/managed_optional_ref_panic.out.log \
    2> tests/managed_optional_ref_panic.err; then
    echo "Optional Ref survived managed owner release" >&2
    exit 1
fi
grep 'panic: dangling managed heap reference' \
    tests/managed_optional_ref_panic.err >/dev/null

./c- tests/managed_string_dangling_panic.c- \
    > tests/managed_string_dangling_panic.out.c
grep 'cminus_string_require_alive(self)' \
    tests/managed_string_dangling_panic.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/managed_string_dangling_panic.out.c \
    -o tests/managed_string_dangling_panic.out
if ./tests/managed_string_dangling_panic.out \
    > tests/managed_string_dangling_panic.out.log \
    2> tests/managed_string_dangling_panic.err; then
    echo "dangling managed string unexpectedly survived" >&2
    exit 1
fi
grep 'panic: dangling managed heap reference' \
    tests/managed_string_dangling_panic.err >/dev/null

./c- tests/gc_header_offset.c- > tests/gc_header_offset.out.c
grep '__cminus_gc_header_from_payload(first)' tests/gc_header_offset.out.c >/dev/null
grep 'first_header->magic != __CMINUS_GC_MAGIC' tests/gc_header_offset.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/gc_header_offset.out.c -o tests/gc_header_offset.out
./tests/gc_header_offset.out

./c- tests/ref_language.c- > tests/ref_language.out.c
grep 'struct Ref_int Ref_from_int' tests/ref_language.out.c >/dev/null
grep 'struct Ref_int reference = ({ cminus_stack_note_caller_range(&value, sizeof(value)); Ref_from_int(&value' tests/ref_language.out.c >/dev/null
grep 'Ref_get_int(&reference)' tests/ref_language.out.c >/dev/null
grep 'Ref_set_int(&reference, 25)' tests/ref_language.out.c >/dev/null
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

C_MINUS_LIB="$ROOT/lib" ./c- -bare --dump-typed-ast tests/bare_metal.c- \
    > tests/bare_metal.out.c \
    2> tests/bare_metal.ast
grep '^runtime-prelude bare-runtime$' tests/bare_metal.ast >/dev/null
grep '^          callee identifier name=printf type=fn()->int$' \
    tests/bare_metal.ast >/dev/null
if grep 'type=unknown reason=' tests/bare_metal.ast >/dev/null; then
    echo "bare-mode AST retained an unknown expression type" >&2
    exit 1
fi
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

if ./c- tests/bad_parenthesized_heap_call_safe.c- > /dev/null 2> tests/bad_parenthesized_heap_call_safe.err; then
    echo "parenthesized raw heap call unexpectedly succeeded" >&2
    exit 1
fi
grep "raw heap function 'malloc' is only allowed inside unsafe" tests/bad_parenthesized_heap_call_safe.err >/dev/null

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

if ./c- tests/bad_global_ref_safe.c- > /dev/null 2> tests/bad_global_ref_safe.err; then
    echo "safe global Ref unexpectedly succeeded" >&2
    exit 1
fi
grep "Ref/Span values cannot be stored in safe global 'saved'" tests/bad_global_ref_safe.err >/dev/null

if ./c- tests/bad_heap_container_ref_safe.c- > /dev/null 2> tests/bad_heap_container_ref_safe.err; then
    echo "heap container of Ref unexpectedly succeeded" >&2
    exit 1
fi
grep "heap container 'values' cannot store Ref/Span values in safe mode" tests/bad_heap_container_ref_safe.err >/dev/null

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

if ./c- tests/bad_stack_syntax.c- > tests/bad_stack_syntax.out.c 2> tests/bad_stack_syntax.err; then
    echo "removed stack struct syntax unexpectedly succeeded" >&2
    exit 1
fi
grep "'stack Type name' syntax has been removed" tests/bad_stack_syntax.err >/dev/null

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
grep 'struct Ref_int reference = ({ cminus_stack_note_caller_range(&value, sizeof(value)); Ref_from_int(&value' tests/no_heap_optional_ref_ok.out.c >/dev/null
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
    Data data;

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
grep "cannot assign struct B to struct A" tests/bad_type_struct.err >/dev/null

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

./c- --dump-typed-ast tests/typed_statement_ast.c- \
    > tests/typed_statement_ast.out.c \
    2> tests/typed_statement_ast.ast
grep '^    function cminus_typed_ast_probe$' tests/typed_statement_ast.ast >/dev/null
grep '^      declaration value expression=binary$' tests/typed_statement_ast.ast >/dev/null
grep -A1 '^      declaration value expression=binary$' tests/typed_statement_ast.ast \
    | grep '^        type type=int$' >/dev/null
grep '^      assignment expression=binary$' tests/typed_statement_ast.ast >/dev/null
grep '^      return expression=identifier$' tests/typed_statement_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_statement_ast.out.c -o tests/typed_statement_ast.out
./tests/typed_statement_ast.out

./c- --dump-typed-ast tests/typed_ownership_ast.c- \
    > tests/typed_ownership_ast.out.c \
    2> tests/typed_ownership_ast.ast
grep -A3 '^        declaration source$' tests/typed_ownership_ast.ast \
    | grep '^          ownership owned$' >/dev/null
grep -A4 '^      declaration view expression=identifier$' tests/typed_ownership_ast.ast \
    | grep '^        ownership borrowed$' >/dev/null
grep -A4 '^      declaration view expression=identifier$' tests/typed_ownership_ast.ast \
    | grep '^        lifetime owner=source storage=owned state=live$' >/dev/null
grep -A5 '^      declaration reference expression=statement-expression$' \
    tests/typed_ownership_ast.ast \
    | grep '^        lifetime owner=value storage=stack state=live runtime-check=yes$' >/dev/null
grep -A4 '^      declaration destination expression=identifier$' tests/typed_ownership_ast.ast \
    | grep '^        move-transfer source=source$' >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_ownership_ast.out.c -o tests/typed_ownership_ast.out
./tests/typed_ownership_ast.out

./c- --dump-typed-ast tests/typed_control_ast.c- \
    > tests/typed_control_ast.out.c \
    2> tests/typed_control_ast.ast
grep '^    function cminus_control_ast_probe$' tests/typed_control_ast.ast >/dev/null
grep '^      for expression=binary initializer=declaration increment=binary$' tests/typed_control_ast.ast >/dev/null
grep '^      while expression=binary$' tests/typed_control_ast.ast >/dev/null
grep '^      if expression=binary$' tests/typed_control_ast.ast >/dev/null
grep '^      if$' tests/typed_control_ast.ast >/dev/null
grep '^      switch expression=identifier$' tests/typed_control_ast.ast >/dev/null
grep '^        case expression=literal$' tests/typed_control_ast.ast >/dev/null
grep '^        default$' tests/typed_control_ast.ast >/dev/null
grep '^        break$' tests/typed_control_ast.ast >/dev/null
grep '^        continue$' tests/typed_control_ast.ast >/dev/null
grep '^      do$' tests/typed_control_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_control_ast.out.c -o tests/typed_control_ast.out
./tests/typed_control_ast.out

./c- --dump-typed-ast tests/typed_update_ast.c- \
    > tests/typed_update_ast.out.c \
    2> tests/typed_update_ast.ast
grep '^      assignment expression=update$' tests/typed_update_ast.ast >/dev/null
grep '^        expr update op=++ form=postfix type=int$' tests/typed_update_ast.ast >/dev/null
grep '^        expr update op=++ form=prefix type=int$' tests/typed_update_ast.ast >/dev/null
grep '^        expr update op=-- form=postfix type=int$' tests/typed_update_ast.ast >/dev/null
grep '^        expr update op=-- form=prefix type=int$' tests/typed_update_ast.ast >/dev/null
grep '^      for expression=binary initializer=declaration increment=update$' tests/typed_update_ast.ast >/dev/null
grep '^        increment-expr update op=++ form=postfix type=int$' tests/typed_update_ast.ast >/dev/null
grep '^          operand identifier name=i type=int$' tests/typed_update_ast.ast >/dev/null
grep '^        expr binary op=<<= type=int$' tests/typed_update_ast.ast >/dev/null
grep '^        expr binary op=|= type=int$' tests/typed_update_ast.ast >/dev/null
grep '^        expr binary op=\^= type=int$' tests/typed_update_ast.ast >/dev/null
grep '^        expr binary op=&= type=int$' tests/typed_update_ast.ast >/dev/null
grep '^        expr binary op=>>= type=int$' tests/typed_update_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_update_ast.out.c -o tests/typed_update_ast.out
./tests/typed_update_ast.out

./c- --dump-typed-ast tests/typed_cast_unary_ast.c- \
    > tests/typed_cast_unary_ast.out.c \
    2> tests/typed_cast_unary_ast.ast
grep '^        expr unary op=- type=int$' tests/typed_cast_unary_ast.ast >/dev/null
grep '^        expr unary op=~ type=int$' tests/typed_cast_unary_ast.ast >/dev/null
grep '^        expr unary op=! type=int$' tests/typed_cast_unary_ast.ast >/dev/null
grep '^            rhs cast target="int" type=int$' tests/typed_cast_unary_ast.ast >/dev/null
grep '^              operand sizeof op=sizeof type=size_t$' \
    tests/typed_cast_unary_ast.ast >/dev/null
grep '^              operand alignof target="int" op=_Alignof type=size_t$' \
    tests/typed_cast_unary_ast.ast >/dev/null
cc -std=gnu11 -Wall -Wextra tests/typed_cast_unary_ast.out.c -o tests/typed_cast_unary_ast.out
./tests/typed_cast_unary_ast.out

./c- --dump-typed-ast tests/typed_typedef_ast.c- \
    > tests/typed_typedef_ast.out.c \
    2> tests/typed_typedef_ast.ast
grep '^    typedef Word type=long$' tests/typed_typedef_ast.ast >/dev/null
grep '^    typedef Counter type=long$' tests/typed_typedef_ast.ast >/dev/null
grep '^    typedef Unary type=fn()->int$' tests/typed_typedef_ast.ast >/dev/null
grep '^    function cminus_typedef_ast_probe$' tests/typed_typedef_ast.ast >/dev/null
grep '^      return-type type=long$' tests/typed_typedef_ast.ast >/dev/null
grep '^      parameter value type=long$' tests/typed_typedef_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_typedef_ast.out.c -o tests/typed_typedef_ast.out
./tests/typed_typedef_ast.out

./c- --dump-typed-ast tests/typed_statement_expression_ast.c- \
    > tests/typed_statement_expression_ast.out.c \
    2> tests/typed_statement_expression_ast.ast
grep '^      declaration result expression=call$' \
    tests/typed_statement_expression_ast.ast >/dev/null
grep '^          argument statement-expression type=struct StatementExpressionItem\*$' \
    tests/typed_statement_expression_ast.ast >/dev/null
grep '^              callee identifier name=cminus_gc_calloc type=fn()->void\*%$' \
    tests/typed_statement_expression_ast.ast >/dev/null
grep '^              argument sizeof target="struct StatementExpressionItem" op=sizeof type=size_t$' \
    tests/typed_statement_expression_ast.ast >/dev/null
grep '^            body-expression identifier name=__right_value[0-9][0-9]* result=yes type=struct StatementExpressionItem\*$' \
    tests/typed_statement_expression_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_statement_expression_ast.out.c \
    -o tests/typed_statement_expression_ast.out
./tests/typed_statement_expression_ast.out

if ./c- tests/bad_typedef_pointer_safe.c- > /dev/null \
    2> tests/bad_typedef_pointer_safe.err; then
    echo "pointer hidden behind typedef unexpectedly succeeded" >&2
    exit 1
fi
grep "pointer declarations are only allowed inside unsafe" \
    tests/bad_typedef_pointer_safe.err >/dev/null

./c- --dump-typed-ast tests/typed_label_ast.c- \
    > tests/typed_label_ast.out.c \
    2> tests/typed_label_ast.ast
grep '^    function cminus_label_ast_probe$' tests/typed_label_ast.ast >/dev/null
grep '^      block$' tests/typed_label_ast.ast >/dev/null
grep '^        assignment expression=binary$' tests/typed_label_ast.ast >/dev/null
grep '^      goto resume$' tests/typed_label_ast.ast >/dev/null
grep '^        goto resume$' tests/typed_label_ast.ast >/dev/null
grep '^      label resume$' tests/typed_label_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_label_ast.out.c -o tests/typed_label_ast.out
./tests/typed_label_ast.out

./c- --dump-typed-ast tests/typed_aggregate_ast.c- \
    > tests/typed_aggregate_ast.out.c \
    2> tests/typed_aggregate_ast.ast
grep '^    preprocessor$' tests/typed_aggregate_ast.ast >/dev/null
grep '^    struct TypedAggregate$' tests/typed_aggregate_ast.ast >/dev/null
grep '^      field value$' tests/typed_aggregate_ast.ast >/dev/null
grep -A1 '^      field value$' tests/typed_aggregate_ast.ast \
    | grep '^        type type=int$' >/dev/null
grep '^    enum TypedKind$' tests/typed_aggregate_ast.ast >/dev/null
grep '^      enum-member TYPED_KIND_ZERO value=0 type=enum TypedKind expression=literal$' \
    tests/typed_aggregate_ast.ast >/dev/null
grep '^      enum-member TYPED_KIND_ONE value=1 type=enum TypedKind expression=literal$' \
    tests/typed_aggregate_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_aggregate_ast.out.c -o tests/typed_aggregate_ast.out
./tests/typed_aggregate_ast.out

./c- --dump-typed-ast tests/typed_enum_ast.c- \
    > tests/typed_enum_ast.out.c \
    2> tests/typed_enum_ast.ast
grep '^      enum-member TYPED_VALUE_ZERO value=0 type=enum TypedValues$' \
    tests/typed_enum_ast.ast >/dev/null
grep '^      enum-member TYPED_VALUE_FOUR value=4 type=enum TypedValues expression=binary$' \
    tests/typed_enum_ast.ast >/dev/null
grep '^      enum-member TYPED_VALUE_FIVE value=5 type=enum TypedValues$' \
    tests/typed_enum_ast.ast >/dev/null
grep -A3 '^      enum-member TYPED_VALUE_FOUR ' tests/typed_enum_ast.ast \
    | grep '^        expr binary op=<< type=int$' >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_enum_ast.out.c -o tests/typed_enum_ast.out
./tests/typed_enum_ast.out

./c- --dump-typed-ast tests/typed_cleanup_ast.c- \
    > tests/typed_cleanup_ast.out.c \
    2> tests/typed_cleanup_ast.ast
grep '^    function cminus_cleanup_ast_probe$' tests/typed_cleanup_ast.ast >/dev/null
grep '^        return expression=literal$' tests/typed_cleanup_ast.ast >/dev/null
grep '^          cleanup$' tests/typed_cleanup_ast.ast >/dev/null
grep '^      return expression=literal$' tests/typed_cleanup_ast.ast >/dev/null
grep '^        cleanup$' tests/typed_cleanup_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_cleanup_ast.out.c -o tests/typed_cleanup_ast.out
./tests/typed_cleanup_ast.out

./c- --dump-typed-ast tests/typed_expansion_ast.c- \
    > tests/typed_expansion_ast.out.c \
    2> tests/typed_expansion_ast.ast
grep '^directive define CMINUS_TYPED_EXPANSION_VALUE$' tests/typed_expansion_ast.ast >/dev/null
grep '^translation-unit$' tests/typed_expansion_ast.ast >/dev/null
grep '^  source-body source$' tests/typed_expansion_ast.ast >/dev/null
grep '^    function cminus_expansion_ast_probe$' tests/typed_expansion_ast.ast >/dev/null
grep '^      expansion$' tests/typed_expansion_ast.ast >/dev/null
grep '^        declaration data expression=initializer-list$' \
    tests/typed_expansion_ast.ast >/dev/null
grep '^        declaration text$' tests/typed_expansion_ast.ast >/dev/null
grep '^        assignment expression=binary$' tests/typed_expansion_ast.ast >/dev/null
grep '^        cleanup$' tests/typed_expansion_ast.ast >/dev/null
grep '^          rhs identifier name=CMINUS_TYPED_EXPANSION_VALUE type=int$' \
    tests/typed_expansion_ast.ast >/dev/null
if grep 'type=unknown reason=' tests/typed_expansion_ast.ast >/dev/null; then
    echo "macro expansion AST retained an unknown expression type" >&2
    exit 1
fi
cc -std=gnu99 -Wall -Wextra tests/typed_expansion_ast.out.c -o tests/typed_expansion_ast.out
./tests/typed_expansion_ast.out

./c- --dump-typed-ast tests/typed_expression_tree_ast.c- \
    > tests/typed_expression_tree_ast.out.c \
    2> tests/typed_expression_tree_ast.ast
grep '^      declaration value expression=call$' tests/typed_expression_tree_ast.ast >/dev/null
grep '^        expr call type=int$' tests/typed_expression_tree_ast.ast >/dev/null
grep '^          callee identifier name=combine type=fn()->int$' \
    tests/typed_expression_tree_ast.ast >/dev/null
grep '^          argument literal value=1 type=int$' tests/typed_expression_tree_ast.ast >/dev/null
grep '^          argument binary op=\* type=int$' tests/typed_expression_tree_ast.ast >/dev/null
grep '^            lhs literal value=2 type=int$' tests/typed_expression_tree_ast.ast >/dev/null
grep '^            rhs literal value=3 type=int$' tests/typed_expression_tree_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_expression_tree_ast.out.c \
    -o tests/typed_expression_tree_ast.out
./tests/typed_expression_tree_ast.out

./c- --dump-typed-ast tests/typed_symbol_resolution_ast.c- \
    > tests/typed_symbol_resolution_ast.out.c \
    2> tests/typed_symbol_resolution_ast.ast
grep '^            rhs identifier name=TYPED_SYMBOL_ONE type=enum TypedSymbolMode$' \
    tests/typed_symbol_resolution_ast.ast >/dev/null
grep '^          then identifier name=__LINE__ type=int$' \
    tests/typed_symbol_resolution_ast.ast >/dev/null
grep '^          callee identifier name=cminus_typed_symbol_probe type=fn()->int$' \
    tests/typed_symbol_resolution_ast.ast >/dev/null
grep '^          argument identifier name=TYPED_SYMBOL_ONE type=enum TypedSymbolMode$' \
    tests/typed_symbol_resolution_ast.ast >/dev/null
grep '^          callee identifier name=cminus_checked_int_add type=fn()->int$' \
    tests/typed_symbol_resolution_ast.ast >/dev/null
grep '^        expr identifier name=__cminus_return[0-9][0-9]* type=int$' \
    tests/typed_symbol_resolution_ast.ast >/dev/null
cc -std=gnu99 -Wall -Wextra tests/typed_symbol_resolution_ast.out.c \
    -o tests/typed_symbol_resolution_ast.out
./tests/typed_symbol_resolution_ast.out

if ./c- tests/bad_untyped_safe_statement.c- > /dev/null \
    2> tests/bad_untyped_safe_statement.err; then
    echo "unrepresented safe-mode statement unexpectedly succeeded" >&2
    exit 1
fi
grep "safe-mode typed AST cannot represent an expression statement" \
    tests/bad_untyped_safe_statement.err >/dev/null

if grep -E '^[[:space:]]+(expression|assignment)$' tests/typed_*_ast.ast \
    >/dev/null; then
    echo "typed AST contains an untyped expression fallback" >&2
    exit 1
fi
if grep -E 'type=unknown reason=(unclassified|none)' tests/typed_*_ast.ast \
    >/dev/null; then
    echo "typed AST contains an unclassified unknown type" >&2
    exit 1
fi

echo "ok"
