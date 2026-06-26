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
- `execinfo.h` / `backtrace(3)` support for panic stack-frame output
  - glibc systems usually provide this with the C library
  - Alpine/musl may require `libexecinfo-dev`

Example installs:

```sh
# Fedora/RHEL
sudo dnf install gcc make bison flex valgrind libasan

# Ubuntu/Debian
sudo apt install build-essential bison flex valgrind libasan8

# Alpine
sudo apk add build-base bison flex valgrind libexecinfo-dev

# Arch Linux
sudo pacman -S base-devel bison flex valgrind
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
  lib/c-.h
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
ldflags = ""
```

`cpm build` lowers every `.c-` file under `src` with `c-`, writes generated C
under `target/debug`, and compiles the executable to
`target/debug/<package-name>`.
`cpm run` builds first and then runs the executable. `cpm test` currently
uses the same build-and-run path as `run`; dedicated test targets can be added
later without changing the manifest format.

`cpm build` optimizes for size by default: it compiles with
`-Os -ffunction-sections -fdata-sections` and links with `-Wl,--gc-sections`,
so each function and global lives in its own section and the linker drops
everything the program never references. The unused (and weak/duplicate)
helpers carried by the standard library and the bare runtime are removed
automatically, shrinking the executable. `cpm run` builds the same way.

`cpm val` and `cpm leak` keep the section garbage collection but build without
`-Os`, so the allocations they are meant to inspect are not optimized away.

`c-` automatically reads the project standard library header `<c-.h>` when a
source file does not include it explicitly. During build, `cpm` also writes
`target/debug/common.h` from top-level function declarations and definitions
found under `src`, and includes that generated header in every generated C
file. `.c-` source files do not need to write either include explicitly.

`uniq` marks a top-level function or global variable definition whose body must
be emitted only once in a multi-source `cpm` build. The source file containing
`main` receives the definition; other source files receive an `extern`
declaration.

```c
uniq int gGlobalVar = 777;

uniq void fun(void)
{
    printf("%d\n", gGlobalVar);
}
```

`cpm leak` rebuilds with compiler sanitizer instrumentation, then runs the
executable with leak detection enabled. This is the preferred project leak
check because it uses the target C compiler's runtime diagnostics. It uses
`-fsanitize=address,leak`.

If the sanitizer build or run cannot be used in the current environment,
`cpm leak` falls back to the Valgrind path.

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
`cpm new` and `cpm init` write them as `lib/c-.h`, and `#include <c-.h>`
resolves through `./lib`. Set `C_MINUS_LIB=/path/to/lib` only when invoking
`c-` directly with a non-project library root.

## Bare-metal / freestanding (`-bare`)

`c- -bare input.c- > output.c` lowers without any libc dependency, for
microcontrollers and other freestanding targets. Instead of emitting
`#include <stdlib.h>` and friends, it inlines `lib/c-bare.h` at the top of the
output, a tiny freestanding runtime that implements exactly the libc surface
the generated code uses (`malloc`/`calloc`/`realloc`/`free`, `memset`/`memcpy`,
`strlen`/`strcmp`/`strncpy`/`strdup`, `printf`/`fprintf`/`puts`/`asprintf`, and
`abort`). Every function is `weak`, so the definitions also satisfy the `mem*`
calls the C compiler itself may emit.

The runtime is built on a single primitive for your board:

```c
int putchar(int c);   /* send one byte to your UART/console */
```

On a hosted Linux target (`__linux__`, on x86-64/aarch64/riscv64/arm) the
runtime already provides a `putchar` and a `_start` through raw syscalls, both
`weak`, so a `-bare` program builds and runs with no board code at all. Real
freestanding targets (for example `arm-none-eabi-gcc`, which does not define
`__linux__`) get nothing here and supply their own `putchar` and startup.

To replace the Linux defaults with your own, compile with
`-DCMINUS_BARE_NO_DEFAULT_PUTCHAR` and/or `-DCMINUS_BARE_NO_DEFAULT_START` (the
runtime is inlined into every translation unit, so a strong override in the
same file would otherwise collide) and provide the function yourself.

`cpm new` and `cpm init` also write `lib/c-bare.h`, so `c- -bare` from inside a
project resolves it through `./lib`. Compile the generated file freestanding;
on Linux no extra startup is needed:

```sh
c- -bare program.c- > program.c
cc -ffreestanding -nostdlib -fno-builtin program.c -o program   # Linux: runs as-is
```

For the smallest image, add size optimization and let the linker drop every
runtime helper the program does not use (the runtime functions are `weak` and
each lands in its own section):

```sh
cc -Os -ffunction-sections -fdata-sections -Wl,--gc-sections \
   -ffreestanding -nostdlib -fno-builtin program.c putchar.c -o program
```

### Making a whole project bare

To build an entire `cpm` project freestanding, set `bare = true` in the
`[build]` section of `C-.toml`:

```toml
[build]
src = "src/main.c-"
compiler = "cc"
cflags = "-std=gnu99 -Wall -Wextra"
ldflags = ""
bare = true
```

With `bare = true`, `cpm build` passes `-bare` to `c-` for every source and
links freestanding with a size-minimizing layout: `-ffreestanding -nostdlib
-fno-builtin -fno-stack-protector -fno-asynchronous-unwind-tables -fno-ident
-no-pie`, plus linker options that drop the build-id note and RELRO and merge
the code/data segments (`-Wl,-z,noseparate-code`), on top of the default `-Os`
and section garbage collection. On Linux this is all you need — the runtime's
default `putchar`/`_start` make the project build and run as-is. For a real
microcontroller, set `compiler`, extra `cflags` (MCU flags), and `ldflags`
(linker script, startup object) for your target, and provide the board's
`putchar` (and startup) as ordinary source files under `src/` — for example a
`src/board.c-`. The `cminus_panic` definition is still emitted once across all
translation units.

Add `strip = true` to `[build]` to strip the binary after linking (skipped for
`cpm val`/`cpm leak`, which need the symbols). With `compiler = "clang"`,
`strip = true`, and a `puts` hello-world, the resulting executable is around
600 bytes with no libc dependency.

Heap is a fixed static buffer; override its size with
`-DCMINUS_BARE_HEAP_SIZE=<bytes>`. `free` is a no-op (bump allocator).

Panics still work. Out-of-range index access calls `cminus_panic`, which prints
the original `.c-` source file and line number (`panic: index out of range at
program.c-:15`) through `putchar`, then `abort()`s. There is no stack-frame
backtrace in bare mode: `backtrace`/`backtrace_symbols_fd` are linked as no-ops,
so the source file and line are still reported but the frame dump is omitted.

`s"..."` heap strings still rely on `asprintf`, which the bare runtime provides.

Local pointer ownership is automatic for owning expressions:

```c
int* a = new int;
```

`new`, `clone`, `s"..."`, `*_new()` functions, and pointer-returning function
calls assigned to local pointer declarations are treated as owning values. The
compiler tracks the local and emits cleanup at every function exit path,
including before `return`.

Use `borrow` when the pointer is not owned by the current function:

```c
borrow char* home = getenv("HOME");
```

`borrow` declarations are not freed. Assigning an owning expression such as
`new int` to a `borrow` declaration is a compile-time error.

The `new` operator allocates one zeroed object with `calloc` and returns an
owning pointer:

```c
int* value = new int;
```

is lowered to:

```c
int* value = calloc(1, sizeof(int));
```

The generated cleanup releases `value` at the end of the current function.
On an early `return`, other tracked locals are released before the return.

Use `move` to transfer ownership out of a variable:

```c
int* make_value(void)
{
    int* value = new int;
    return move value;
}
```

`move value` is lowered to `value` in C and removes `value` from the current
function cleanup list. The caller receives an owning pointer when it stores the
result in a local pointer; use `borrow` at the caller when the result is not
owned.

For structs, `new` may use the struct tag directly and may include a simple
object initializer:

```c
struct Person* person = new Person { name: strdup("aaa"), age: 48 };
```

This is lowered to a `calloc(1, sizeof(struct Person))` temporary followed by
field assignments. Owned fields such as `string name` are released by the
generated `Person_finalize` when `person` leaves scope.

Pointer arithmetic on owned pointers is rejected, including `+`, `-`, `++`,
`--`, `+=`, and `-=`.

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

Generic structs, functions, and payload enums use explicit type arguments and
are lowered by monomorphization. Type inference is not performed except for
`auto` declarations initialized from payload enum constructors.

The standard `Vec` template lives in the source library and can be included
with:

```c
#include <c-.h>
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

The standard library currently provides `Vec<T>` and `List<T>`. Both support
`new`, `push`, `len`, `is_empty`, `clear`, `first`, `last`, `get`, `set`,
checked indexed access, automatic deletion for owning local variables, and
`foreach`.
`Vec<T>` also supports `capacity`, `reserve`, and `pop_opt`. `List<T>` also
supports `push_front` and `pop_front_opt`. `Map<K,V>` provides a generic
hash table with `new`, `set`, `get_opt`, `contains`, `remove`, `len`,
`is_empty`, `clear`, and automatic deletion for owning local variables.

Owning element containers are available as `OwnedVec<T>`, `OwnedList<T>`, and
`OwnedMap<K,V>`. They are intended for pointer element/value types. Insert
owned values with `move`; `set`, `remove`, `clear`, and `delete` free contained
values. `pop_opt` transfers an element out without freeing it. `OwnedMap`
owns values and treats keys as value or borrowed data.

```c
struct OwnedVec<int*>* xs = OwnedVec_new<int*>();
int* value = new int;
xs.push(move value);
xs.clear();
```

`foreach` iterates over `Vec<T>` values through `.data` and `.len`, and over
`List<T>` values through linked-list nodes:

```c
foreach (int value in nums) {
    sum += value;
}
```

This lowers to ordinary `for` loops. The element type must be written
explicitly; it may itself be a concrete generic type.

`Vec<T>` and `List<T>` also support checked indexed access:

```c
int a = nums[1];
int b = list[1];
```

The generated code calls a payload-enum checked access helper. If the index is
out of range, it calls `cminus_panic` with the original `.c-` source file name
and line number, prints stack frames with `backtrace(3)`, and aborts.

Rust-like payload enum syntax is available for generic enums:

```c
enum Option<T> {
    Some(T),
    None,
};

auto some = new Option<int>.Some(123);
auto none = new Option<int>.None();

if (some.is_Some() && none.is_None()) {
    return some.get_Some();
}
```

`new Type<T>.Variant(...)` creates a value of that variant. `is_Variant()` is
generated for every variant. `get_Variant()` is generated for variants with
one payload value.

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

Struct fields may use owned field types such as `string`, or the `owned`
keyword for raw heap fields. Generated finalizers release owned fields when
the struct value or owning struct pointer leaves scope.

```c
struct Holder {
    owned int* value;
};
```

`c-` emits a finalizer:

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

`string` is a built-in owned string alias. The output C receives a single
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
char* text = s"aaa \{1+1}";
```

is lowered to an `asprintf` call:

```c
char* text;
asprintf(&text, "aaa %d", 1+1);
```

The string is tracked as an owned local and freed at function exit. Output C
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
declarations, pointer depth, ownership qualifiers, and `struct` / `union` /
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
