set -eu

./cauto tests/good.cauto.c > tests/good.out.c
grep 'int\* a = malloc(sizeof(int));' tests/good.out.c >/dev/null
grep 'free(a);' tests/good.out.c >/dev/null
test "$(grep -c 'free(a);' tests/good.out.c)" = "1"
cc -std=c99 -Wall -Wextra -pedantic tests/good.out.c -o tests/good.out
./tests/good.out

./cauto tests/no_return.cauto.c > tests/no_return.out.c
grep 'free(a);' tests/no_return.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic -c tests/no_return.out.c -o tests/no_return.out.o

./cauto tests/types_ok.cauto.c > tests/types_ok.out.c
grep 'struct Pair\* p = malloc(sizeof(struct Pair));' tests/types_ok.out.c >/dev/null
grep 'free(p);' tests/types_ok.out.c >/dev/null
cc -std=c99 -Wall -Wextra -pedantic tests/types_ok.out.c -o tests/types_ok.out
./tests/types_ok.out

./cauto tests/bad.cauto.c > tests/unbound_malloc.out.c
grep 'int\* a = malloc(sizeof(int));' tests/unbound_malloc.out.c >/dev/null
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
grep 'free(p);' tests/attr_malloc_return.out.c >/dev/null
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
grep "malloc result requires a pointer % declaration" tests/bad_owned_non_pointer.err >/dev/null

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
