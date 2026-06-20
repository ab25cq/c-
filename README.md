# c-

Small C-to-C translator experiment.

## Dependencies

Build dependencies:

- C compiler available as `cc`
- GNU Bison
- Flex
- `make`

Runtime/debugging dependencies:

- `valgrind` for `cpm val` and Linux fallback leak checks
- AddressSanitizer runtime for `cpm leak`
  - Fedora/RHEL: `libasan`
  - macOS: Apple Clang or LLVM Clang with AddressSanitizer support

Example installs:

```sh
# Fedora/RHEL
sudo dnf install gcc make bison flex valgrind libasan

# Ubuntu/Debian
sudo apt install build-essential bison flex valgrind libasan8

# Alpine
sudo apk add build-base bison flex valgrind

# Arch Linux
sudo pacman -S base-devel bison flex valgrind

# macOS with Homebrew
brew install bison flex
```

## cpm Package Manager

`cpm` is a small Cargo-like package manager for `c-` projects.

Commands:

```sh
cpm new hello
cd hello
cpm build
cpm run
cpm test
cpm val
cpm leak
cpm clean
```

`cpm new hello` creates:

```text
hello/
  C-.toml
  src/main.c-
  lib/c-/vec.c-
  .gitignore
```

The manifest is intentionally close to Cargo's shape:

```toml
[package]
name = "hello"
version = "0.1.0"
edition = "2026"

[build]
src = "src/main.c-"
compiler = "cc"
cflags = "-std=gnu99 -Wall -Wextra"
```

`cpm build` lowers the source with `c-`, writes generated C under
`target/debug`, and compiles the executable to `target/debug/<package-name>`.
`cpm run` builds first and then runs the executable. `cpm test` currently
uses the same build-and-run path as `run`; dedicated test targets can be added
later without changing the manifest format.

`cpm leak` rebuilds with compiler sanitizer instrumentation, then runs the
executable with leak detection enabled. This is the preferred project leak
check because it uses the target C compiler's runtime diagnostics. On Linux it
uses `-fsanitize=address,leak`. On macOS it uses AddressSanitizer only,
`-fsanitize=address`, because Apple Clang does not consistently support the
separate `leak` sanitizer flag.

On Linux, if the sanitizer build or run cannot be used in the current
environment, `cpm leak` falls back to the Valgrind path. On macOS, `cpm leak`
stays ASan-based and reports sanitizer failures directly.

`cpm val` builds normally and runs the executable under Valgrind:

```sh
cpm val
cpm val arg1 arg2
```

It uses `--leak-check=full`, reports all leak kinds, and exits nonzero for
definite or possible leaks. Set `CPM_VALGRIND=/path/to/valgrind` to override
the Valgrind executable. `cpm clean` removes `target`.

By default `cpm` runs `c-` from `PATH`. For development or tests, set
`CPM_C_MINUS=/path/to/c-`. Standard library includes are project-local:
`cpm new` and `cpm init` write them under `lib/c-/`, and `#include <c-/...>`
resolves through `./lib`. Set `C_MINUS_LIB=/path/to/lib` only when invoking
`c-` directly with a non-project library root.

The first feature is an owned pointer marker:

```c
int*% a = new int;
```

`malloc` is an ordinary function call. GCC-style `malloc` function attributes
are ignored by ownership analysis. A function result is treated as owning only
when the function return type itself is marked with `%`, or when the expression
uses `new`.

Owning results assigned to `%` pointer declarations are bound to the current
function scope, and the output C receives a `free(a);` before function exits.
Owning results assigned to ordinary pointer lvalues are rejected. Use `%` when
the current scope or struct field owns the allocation.

The `new` operator allocates one zeroed object with `calloc` and returns an
owning pointer:

```c
int*% value = new int;
```

is lowered to:

```c
int* value = calloc(1, sizeof(int));
```

Like `%`-marked function results, a `new` result bound to `%` lives until the
current function exit. A `new` result bound to an ordinary pointer is a
compile-time error.

For structs, `new` may use the struct tag directly and may include a simple
object initializer:

```c
struct Person*% person = new Person { name: strdup("aaa"), age: 48 };
```

This is lowered to a `calloc(1, sizeof(struct Person))` temporary followed by
field assignments. Owned fields such as `string name` are released by the
generated `Person_finalize` when `person` leaves scope.

Pointer arithmetic on `%` owned pointers is rejected, including `+`, `-`,
`++`, `--`, `+=`, and `-=`.

Simple method-call syntax is lowered to plain C calls. If `d` has type
`struct data`, then:

```c
d.show();
```

is lowered to:

```c
data_show(&d);
```

String literal receivers are passed as the first argument:

```c
"aaa".strcmp("aaa")
```

is lowered to:

```c
strcmp("aaa", "aaa")
```

Function parameters may have defaults and calls may use labels. Defaults are
written in the function declaration or definition with `=`:

```c
void fun(int a = b + 1, int b = 22, int c = 33);
```

The generated C signature removes the defaults:

```c
void fun(int a, int b, int c);
```

Calls may omit arguments that have defaults:

```c
int b = 111;
fun();
```

This is lowered at the call site:

```c
fun(b + 1, 22, 33);
```

Default expressions are stored as source text and inserted at the call site.
They are not evaluated or type-resolved when the function is declared. Names
inside a default expression are therefore resolved by the generated C compiler
in the caller's scope. In the example above, `b + 1` uses the local `b` in the
caller.

Calls may also use parameter labels with `name: value`:

```c
fun(c: 9, a: 7);
```

Labels are reordered into the function's parameter order and missing arguments
are filled from defaults:

```c
fun(7, 22, 9);
```

Positional and labeled arguments may be mixed. Positional arguments fill the
next unfilled parameter from left to right:

```c
int b = 111;
fun(1, c: 3);
```

is lowered to:

```c
fun(1, 22, 3);
```

A function is registered for this rewriting only when at least one parameter
has a default expression. Unknown labels, duplicate labels, too many arguments,
or omitted parameters without defaults are compile-time `c-` errors.

Generic structs and functions use explicit type arguments and are lowered by
monomorphization. Type inference is not performed.

The standard `Vec` template lives in the source library and can be included
with:

```c
#include <c-/vec.c->
```

```c
struct Vec<int> nums;
int first = Vec_first<int>(&nums);
```

The generated C uses concrete names such as `struct Vec_int` and
`Vec_first_int`.

Generic functions whose names follow `<TypeName>_<method>` may also be called
as methods on concrete generic values. The receiver type supplies the generic
argument, so no method-call type argument is needed:

```c
int first = nums.first();
```

This lowers to:

```c
int first = Vec_first_int(&nums);
```

Pointer receivers use `->`:

```c
struct Vec<int>* ptr = &nums;
int first = ptr->first();
```

Generic method blocks are intentionally not part of this feature.

`foreach` iterates over collection-like values that expose `.data` and `.len`:

```c
foreach (int value in nums) {
    sum += value;
}
```

This lowers to ordinary `for` loops. The element type must be written
explicitly; it may itself be a concrete generic type.

Local variable declarations without initializers receive a zero initializer and
are then zero-cleared immediately after the declaration with `memset`,
including aggregate variables:

```c
struct Pair pair;
```

is lowered to:

```c
struct Pair pair = {0};
memset(&pair, 0, sizeof(pair));
```

Struct fields may also use `%` to express owned heap pointers:

```c
struct Holder {
    int*% value;
};
```

`c-` removes the marker from the output field and emits a finalizer:

```c
struct Holder {
    int* value;
};

static void Holder_finalize(struct Holder* self)
{
    if (self == NULL) {
        return;
    }
    if (self->value != NULL) {
        free(self->value);
    }
}
```

When a local struct value reaches the function exit, or when an owned struct
pointer is released, the generated code calls the finalizer before the
existing `free` operation.

`string` is a built-in owned string alias. Source code may either use it
directly or write `typedef char*% string;`; the output C receives a single
plain C definition:

```c
typedef char* string;
```

Inside structs, `string` fields are treated like owned heap fields. The
generated finalizer frees the field, and the generated `StructName_clone`
function returns an owned `struct StructName*` allocated with `calloc`.
String fields are deep-copied with `calloc(strlen(src) + 1, sizeof(char))`
and `strncpy`, rather than copying the pointer:

```c
struct Person {
    string name;
    int age;
};
```

emits clone/finalize logic equivalent to:

```c
if (self->name != NULL) {
    free(self->name);
}

if (self->name != NULL) {
    copy->name = calloc(strlen(self->name) + 1, sizeof(char));
    strncpy(copy->name, self->name, strlen(self->name) + 1);
}
```

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
`c-` stores it in a generated `char* __right_valueN = NULL;`, rewrites the
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
