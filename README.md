# cauto

Small C-to-C translator experiment.

The first feature is an owned pointer marker:

```c
int*% a = malloc(sizeof(int));
```

`malloc` is treated as an owning allocator. If a function has a GCC-style
`malloc` function attribute in a visible prototype, or its return type is
marked with `%`, `cauto` also treats its return value as owning.

Owning results assigned to `%` pointer declarations are bound to the current
function scope, and the output C receives a `free(a);` before function exits.
Owning results assigned to ordinary pointer lvalues are not bound; the output C
keeps the heap object alive for that statement and inserts `free(a);`
immediately after the statement.

Pointer arithmetic on `%` owned pointers is rejected, including `+`, `-`,
`++`, `--`, `+=`, and `-=`.

Heap strings use the `s"..."` syntax. They must be assigned to a `char*`
lvalue. For example:

```c
char*% text = s"aaa \{1+1}";
```

is lowered to an `asprintf` call:

```c
char* text;
asprintf(&text, "aaa %d", 1+1);
```

When the left hand side is `%`, the string is freed at function exit. When it
is an ordinary `char*`, it is freed immediately after the statement. Output C
using heap strings expects `asprintf` to be declared by the target C library.

If an `s"..."` heap string appears as an rvalue inside a larger expression,
`cauto` stores it in a generated `char* __right_valueN = NULL;`, rewrites the
expression to use that temporary, and frees it at the end of the statement:

```c
int ok = strcmp(s"abc", "abc") == 0;
```

becomes:

```c
char* __right_value0 = NULL;
asprintf(&__right_value0, "abc");
int ok = strcmp(__right_value0, "abc") == 0;
free(__right_value0);
```

Conditions in `if`, `else if`, `while`, and `do while` use the same temporary
rule, but are lowered into a GNU C statement expression so the temporary is
freed as part of condition evaluation:

```c
if (strcmp(s"abc", "abc") == 0) {
    ...
}
```

becomes:

```c
if (({ char* __right_value0 = NULL; asprintf(&__right_value0, "abc"); int __right_value_cond1 = strcmp(__right_value0, "abc") == 0; free(__right_value0); __right_value_cond1; })) {
    ...
}
```

The parser also tracks a small C type table. It records local/global
declarations, pointer depth, owned pointer markers, and `struct` / `union` /
`enum` tags. Simple declarations and assignments are checked when both sides
have known types. Complex expressions that are not yet modeled are left as
unknown to avoid false positives.

Internally, output text is kept in a separate `Text` buffer while parser facts
are represented with chibicc-style `Node`, `Type`, and `Obj` records. The AST
currently records statement/block-level nodes and keeps the existing C-to-C
lowering path, so later expression parsing and code generation can move toward
the chibicc model without changing the surface syntax.

Build and test:

```sh
make test
```

The parser is generated from `src/parser.y` with GNU Bison. The lexer is
generated from `src/lexer.l` with flex, while keeping comments/whitespace
attached to tokens so the output remains close to the input.
