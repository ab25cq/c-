set -eu

./cauto tests/good.cauto.c > tests/good.out.c
grep 'int\* a = calloc(1, sizeof(int));' tests/good.out.c >/dev/null
grep 'free(a);' tests/good.out.c >/dev/null
test "$(grep -c 'free(a);' tests/good.out.c)" = "1"
cc -std=c99 -Wall -Wextra -pedantic tests/good.out.c -o tests/good.out
./tests/good.out

./cauto tests/no_return.cauto.c > tests/no_return.out.c
grep 'free(a);' tests/no_return.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic -c tests/no_return.out.c -o tests/no_return.out.o

./cauto tests/types_ok.cauto.c > tests/types_ok.out.c
grep 'struct Pair\* p = calloc(1, sizeof(struct Pair));' tests/types_ok.out.c >/dev/null
grep 'free(p);' tests/types_ok.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/types_ok.out.c -o tests/types_ok.out
./tests/types_ok.out

./cauto tests/local_zero.cauto.c > tests/local_zero.out.c
grep '#include <string.h>' tests/local_zero.out.c >/dev/null
grep 'int value = {0};' tests/local_zero.out.c >/dev/null
grep 'struct Pair pair = {0};' tests/local_zero.out.c >/dev/null
grep 'int\* ptr = {0};' tests/local_zero.out.c >/dev/null
grep 'memset(&value, 0, sizeof(value));' tests/local_zero.out.c >/dev/null
grep 'memset(&pair, 0, sizeof(pair));' tests/local_zero.out.c >/dev/null
grep 'memset(&ptr, 0, sizeof(ptr));' tests/local_zero.out.c >/dev/null
grep 'int initialized = 7;' tests/local_zero.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/local_zero.out.c -o tests/local_zero.out
./tests/local_zero.out

./cauto tests/struct_finalizer.cauto.c > tests/struct_finalizer.out.c
grep 'int\* value;' tests/struct_finalizer.out.c >/dev/null
grep 'static void Holder_finalize(struct Holder\* self)' tests/struct_finalizer.out.c >/dev/null
grep 'free(self->value);' tests/struct_finalizer.out.c >/dev/null
grep 'Holder_finalize(&stack);' tests/struct_finalizer.out.c >/dev/null
grep 'Holder_finalize(heap);' tests/struct_finalizer.out.c >/dev/null
grep 'struct Holder\* heap = calloc(1, sizeof(struct Holder));' tests/struct_finalizer.out.c >/dev/null
grep 'heap->value = calloc(1, sizeof(int));' tests/struct_finalizer.out.c >/dev/null
grep 'free(heap);' tests/struct_finalizer.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/struct_finalizer.out.c -o tests/struct_finalizer.out
./tests/struct_finalizer.out

./cauto tests/new_operator.cauto.c > tests/new_operator.out.c
grep 'int\* owned = calloc(1, sizeof(int));' tests/new_operator.out.c >/dev/null
grep 'int\* unbound = calloc(1, sizeof(int));' tests/new_operator.out.c >/dev/null
grep 'struct Item\* item = calloc(1, sizeof(struct Item));' tests/new_operator.out.c >/dev/null
grep 'free(unbound);' tests/new_operator.out.c >/dev/null
grep 'free(owned);' tests/new_operator.out.c >/dev/null
grep 'free(item);' tests/new_operator.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/new_operator.out.c -o tests/new_operator.out
./tests/new_operator.out

./cauto tests/owned_reassign.cauto.c > tests/owned_reassign.out.c
grep 'void\* __owned_old' tests/owned_reassign.out.c >/dev/null
grep 'owned = calloc(1, sizeof(int));' tests/owned_reassign.out.c >/dev/null
grep 'holder.value = calloc(1, sizeof(int));' tests/owned_reassign.out.c >/dev/null
grep 'if (__owned_old' tests/owned_reassign.out.c >/dev/null
grep 'free(__owned_old' tests/owned_reassign.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/owned_reassign.out.c -o tests/owned_reassign.out
./tests/owned_reassign.out

./cauto tests/method_calls.cauto.c > tests/method_calls.out.c
grep 'struct data\* p = calloc(1, sizeof(struct data));' tests/method_calls.out.c >/dev/null
grep 'data_show(&d);' tests/method_calls.out.c >/dev/null
grep 'data_show(p);' tests/method_calls.out.c >/dev/null
grep 'strcmp("aaa", "aaa") != 0' tests/method_calls.out.c >/dev/null
grep 'return strcmp("aaa", "aaa");' tests/method_calls.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/method_calls.out.c -o tests/method_calls.out
./tests/method_calls.out

./cauto tests/bad.cauto.c > tests/unbound_malloc.out.c
grep 'int\* a = calloc(1, sizeof(int));' tests/unbound_malloc.out.c >/dev/null
grep 'free(a);' tests/unbound_malloc.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic -c tests/unbound_malloc.out.c -o tests/unbound_malloc.out.o

./cauto tests/owned_return.cauto.c > tests/owned_return.out.c
grep 'struct Pair\* make_pair(void);' tests/owned_return.out.c >/dev/null
grep 'struct Pair\* p = make_pair();' tests/owned_return.out.c >/dev/null
grep 'free(p);' tests/owned_return.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/owned_return.out.c -o tests/owned_return.out
./tests/owned_return.out

./cauto tests/attr_malloc_return.cauto.c > tests/attr_malloc_return.out.c
grep 'int\* p = raw_alloc(sizeof(int));' tests/attr_malloc_return.out.c >/dev/null
if grep 'free(p);' tests/attr_malloc_return.out.c >/dev/null; then
    echo "malloc attribute unexpectedly made raw_alloc owned" >&2
    exit 1
fi
cc -std=c99 -Wall -Wextra -pedantic tests/attr_malloc_return.out.c -o tests/attr_malloc_return.out
./tests/attr_malloc_return.out

./cauto tests/s_string_owned.cauto.c > tests/s_string_owned.out.c
grep 'char\* text;' tests/s_string_owned.out.c >/dev/null
grep 'asprintf(&text, "aaa %d", 1+1);' tests/s_string_owned.out.c >/dev/null
grep 'free(text);' tests/s_string_owned.out.c >/dev/null
test "$(grep -c 'free(text);' tests/s_string_owned.out.c)" = "1"
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_owned.out.c -o tests/s_string_owned.out
./tests/s_string_owned.out

./cauto tests/s_string_unbound.cauto.c > tests/s_string_unbound.out.c
grep 'char\* text;' tests/s_string_unbound.out.c >/dev/null
grep 'asprintf(&text, "abc");' tests/s_string_unbound.out.c >/dev/null
grep 'free(text);' tests/s_string_unbound.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_unbound.out.c -o tests/s_string_unbound.out
./tests/s_string_unbound.out

./cauto tests/s_string_rvalue.cauto.c > tests/s_string_rvalue.out.c
grep 'char\* __right_value0 = NULL;' tests/s_string_rvalue.out.c >/dev/null
grep 'asprintf(&__right_value0, "abc");' tests/s_string_rvalue.out.c >/dev/null
grep 'strcmp(__right_value0, "abc") == 0' tests/s_string_rvalue.out.c >/dev/null
grep 'free(__right_value0);' tests/s_string_rvalue.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/s_string_rvalue.out.c -o tests/s_string_rvalue.out
./tests/s_string_rvalue.out

./cauto tests/s_string_conditions.cauto.c > tests/s_string_conditions.out.c
grep 'if (({' tests/s_string_conditions.out.c >/dev/null
grep 'while (({' tests/s_string_conditions.out.c >/dev/null
grep 'free(__right_value' tests/s_string_conditions.out.c >/dev/null
cc -std=gnu99 -Wall -Wextra tests/s_string_conditions.out.c -o tests/s_string_conditions.out
./tests/s_string_conditions.out

if ./cauto tests/bad_owned_non_pointer.cauto.c > /dev/null 2> tests/bad_owned_non_pointer.err; then
    echo "bad owned non-pointer unexpectedly succeeded" >&2
    exit 1
fi
grep "new result requires a pointer % declaration" tests/bad_owned_non_pointer.err >/dev/null

if ./cauto tests/bad_type_pointer_to_int.cauto.c > /dev/null 2> tests/bad_type_pointer_to_int.err; then
    echo "bad pointer-to-int assignment unexpectedly succeeded" >&2
    exit 1
fi
grep "cannot assign char\\* to int" tests/bad_type_pointer_to_int.err >/dev/null

if ./cauto tests/bad_type_struct.cauto.c > /dev/null 2> tests/bad_type_struct.err; then
    echo "bad struct assignment unexpectedly succeeded" >&2
    exit 1
fi
grep "cannot assign struct B to struct A" tests/bad_type_struct.err >/dev/null

if ./cauto tests/bad_owned_arith.cauto.c > /dev/null 2> tests/bad_owned_arith.err; then
    echo "bad owned pointer arithmetic unexpectedly succeeded" >&2
    exit 1
fi
grep "pointer arithmetic is forbidden for owned pointer 'p'" tests/bad_owned_arith.err >/dev/null

if ./cauto tests/bad_s_string_type.cauto.c > /dev/null 2> tests/bad_s_string_type.err; then
    echo "bad s string type unexpectedly succeeded" >&2
    exit 1
fi
grep "s string requires a char pointer declaration" tests/bad_s_string_type.err >/dev/null

echo "ok"
