# c-

Small C-to-C translator experiment.

Current language/package format version: `0.5.0`.

The current surface syntax, safety rules, and an edition-gated direction for
value/reference syntax are described in [LANGUAGE.md](LANGUAGE.md).

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
- POSIX threads (`pthread`) for hosted `Thread`, `Mutex`, and `Cond`
  - glibc and musl provide this through the system C library/toolchain
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
version = "0.5.0"
edition = "2026"

[build]
src = "src/main.c-"
compiler = "cc"
std = ""
cflags = "-std=gnu99 -Wall -Wextra"
ldflags = ""
threads = false
c_compat = false
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

`std` is optional. The default project template keeps `-std=gnu99` in
`cflags` for C99 compatibility. Setting `std = "gnu11"` appends `-std=gnu11`
after `cflags`, so C11 can be selected without breaking existing manifests.

`c_compat = true` enables C compatibility mode for user source preprocessor
lines. In that mode, top-level and statement-local C preprocessor directives
such as `#define`, function-like macros, `#if`, `#ifdef`, `#ifndef`, `#elif`,
`#else`, `#endif`, `#undef`, and `#pragma` are preserved in place in the
generated C. C- still handles `<c-.h>` as the language standard library include.
Use this mode when porting C code that relies heavily on macros.

The compatibility path also preserves common C declarations and C99 constructs
that are awkward for the safe-mode parser but normal in existing C code:
braced `typedef struct`, `typedef union`, `typedef enum`, function-pointer
typedefs, VLA declarations, `restrict`, array parameters such as
`int values[static 1]`, flexible array members, variadic macros, compound
literals, and nested/designated initializers such as
`Point p = { .x = 1, .y = 2 };`. In `c_compat` user functions are emitted as
plain C functions without C- ownership or stack-guard rewriting; the bundled
`<c-.h>` standard library is still parsed as C- so safe-mode features keep
working. `cpm` adds both `-Itarget/debug` and `-Isrc`, so local C headers
included with `#include "name.h"` work in package builds.

For code that should be emitted as C without C- rewriting, use `inline c`.
The block is an unsafe raw-C boundary: C syntax is emitted directly, while
declarations inside the block are only partially visible to C-'s safe-mode type
and ownership tables. Prefer a small safe wrapper around raw C functions before
calling them from safe code.

```c
inline c {
#define SCALE 3
typedef int (*Callback)(int);

static inline int scale(int value)
{
    return value * SCALE;
}
}
```

`cpm` also compiles and links plain `src/**/*.c` files alongside generated C.
Declare those functions in a local header and include it from `.c-` sources when
mixing existing C modules into a C- package.

`c-` automatically reads the project standard library header `<c-.h>` when a
source file does not include it explicitly. During build, `cpm` also writes
`target/debug/common.h` from top-level function declarations and definitions
found under `src`, and includes that generated header in every generated C
file. `.c-` source files do not need to write either include explicitly.

`uniq` marks a top-level function or global variable definition whose body must
be emitted only once in a multi-source `cpm` build. The source file containing
`main` receives the definition; other source files receive an `extern`
declaration.

Managed allocations are explicit:

- `new` creates managed heap objects.
- `clone` is also managed.
- Raw C allocations such as `malloc`, `calloc`, and `strdup` stay outside the
  managed heap unless they are wrapped by an owning language feature.
- Managed heap blocks keep an allocation header, live/dead state, and allocation
  site. Freed blocks are kept for reuse, double-free is ignored for already-dead
  managed blocks, and leak reports come from `cminus_gc_report_leaks()`.
- The runtime is not reference counted; ownership cleanup and `borrow`/safe
  references are the intended safety model.
- `cpm leak` prefers AddressSanitizer where available and falls back to
  Valgrind; `cpm val` always runs Valgrind.

## Safety Model

`c-` is moving toward safe C by default. Raw C compatibility is restricted to
explicit unsafe blocks:

```c
unsafe {
    p++;
}
```

The compiler deliberately performs aggressive static checks so generated code is
easy for AI tools to write and debug. Prefer a compile-time error over a latent
segmentation fault, and prefer a precise source-location diagnostic over a
runtime surprise. Safe mode rejects unsafe lifetime escapes, raw pointer taint
crossing safe boundaries, invalid `NULL` use, unsafe pointer dereference, raw
heap calls, and many borrow-after-release patterns before C code is compiled.
The precise guarantee, trusted boundary, and current concurrency limitation are
documented in [`SAFETY.md`](SAFETY.md).

Outside `unsafe`, pointer arithmetic on pointer variables is a compile-time
error. This applies to borrowed and owned pointers. Use field access on structs,
checked collection indexing, `Span<T>` views, checked `/` and `%`, and
higher-level library types instead of pointer arithmetic in safe code. Division
or modulo by zero calls `cminus_panic` with the source file and line number.
Pointer dereference is also rejected in safe code for variables and pointer
return values; use `Span<T>` indexing or an unsafe wrapper that validates the
operation.

Safe code uses `Span` for contiguous views, `Ref` for non-owning references, and
`Optional` for nullable/absent values. Raw pointers and C-compatible memory
operations remain available inside `unsafe`.

Signed addition, subtraction, and multiplication in generated GNU C code use
the compiler's trapping-overflow mode. Allocation byte calculations additionally
use explicit checked arithmetic, including unsigned `size_t` multiplication and
header addition. A single managed allocation is limited to 1 GiB by default;
boards can override `CMINUS_MAX_ALLOCATION`. Safe call depth is limited to 1024
tracked frames by default. The runtime also panics after 2 MiB of tracked stack
growth, and safe local arrays larger than 64 KiB are rejected at compile time.
The runtime limits are named `CMINUS_MAX_STACK_DEPTH` and
`CMINUS_MAX_STACK_BYTES`. Variable-length arrays are unsafe-only. Ordinary
local scalars, structs, and fixed arrays are zero-initialized by the language
before they can be read.

Inline assembly does not have a separate C- surface syntax yet. Use the target
C compiler's inline assembly inside `unsafe`:

```c
unsafe {
    __asm__ volatile("dsb sy" : : : "memory");
}
```

This keeps CPU instructions, register constraints, and clobber lists behind an
explicit unsafe boundary while still letting kernels and board support code use
the compiler's native `__asm__` form. Outside `unsafe`, inline assembly is
treated like other C-compatible low-level code and should not be used.

Safe references cannot escape the lifetime of their source. Returning
`Ref<T>`/`Span<T>` values that directly refer to a local stack variable, local
stack array, or owning local is a compile-time error. Borrowed locals that refer
to an owned value also become invalid after the owner is moved or reassigned;
later use is rejected at compile time, including in `if`/`while`/`foreach`
headers and other control expressions.

At runtime, references into managed allocations retain the allocation's
generation ID as well as its storage kind. Validation searches the managed
live/dead registries without dereferencing an untrusted candidate address and
supports pointers to fields inside an allocation. A reference therefore panics
after its owner is released, and remains stale even if a later allocation
reuses exactly the same address. The same provenance travels through `Span`,
`FixedVec`, `RingBuffer`, `Bitmap`, and payload wrappers such as
`Optional<Ref<T>>`.

Safe structs cannot contain `Ref<T>` or `Span<T>` fields. C- does not yet have
lifetime parameters for stored references, so safe references must stay in local
variables, parameters, and return values that the compiler can check directly.
Store owned data in structs and create `Ref`/`Span` views at the call site.
Safe globals likewise cannot store `Ref`, `Span`, or an `Optional` containing
one, and heap collections cannot use safe references as their element type.
These conservative restrictions prevent an indirect stack reference from
outliving its source until explicit lifetime parameters are available.

Owned values are unique. Assigning an owned local to another pointer without
`move` is rejected; use `move` to transfer ownership or an explicit `borrow`
declaration for a non-owning local view. Safe unions and variadic functions are
also rejected because their active type and argument types cannot be established
by the current type checker; put them behind `unsafe` and expose a typed wrapper.

Safe/unsafe boundaries are checked conservatively. Raw pointer taint from unsafe
functions cannot be passed to safe function parameters, including calls nested
inside control conditions; use a managed wrapper, `Optional`, `Span`, or
`Ref`-based API instead.
Raw pointer fields declared inside an `unsafe` struct also cannot be accessed
from safe code. Wrap the operation in `unsafe` or expose a safe method that
returns managed data, `Optional`, `Span`, or `Ref`.
Functions declared inside `unsafe` are unsafe functions. Safe code cannot call
them directly; the call site must be inside `unsafe`, matching Rust's explicit
boundary style.
C string, memory, and file APIs such as `strlen`, `strcmp`, `strcpy`, `memcpy`,
`memset`, `strdup`, `fopen`, `fread`, and `fwrite` are also unsafe-only in safe
mode. Use Rust-style string methods such as `text.len()`, `text.cmp(other)`,
`text.eq(other)`, `text.contains(part)`, `text.starts_with(prefix)`, and
`text.ends_with(suffix)`. File operations stay procedural and use wrappers such
as `xfopen(path, mode)`.

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
`#include <stdlib.h>` and friends, it inlines the *declarations* from
`lib/c-bare.h`, a tiny freestanding runtime that implements exactly the libc
surface the generated code uses (`malloc`/`calloc`/`realloc`/`free`,
`memset`/`memcpy`, `strlen`/`strcmp`/`strncpy`/`strdup`,
`printf`/`fprintf`/`puts`/`asprintf`, and `abort`).

The runtime *definitions* live behind `CMINUS_BARE_IMPL` and are compiled once
into a separate object that the program links against. Keeping the definitions
out of the program translation units is deliberate: the compiler then sees
`printf` and friends as ordinary libc declarations and may fold, for example,
`printf("...\n")` into `puts()` and drop the unused format engine entirely. A
constant-string hello-world links to roughly 600–800 bytes with no libc.

The runtime is built on a single primitive for your board:

```c
int putchar(int c);   /* send one byte to your UART/console */
```

On a hosted Linux target (`__linux__`, on x86-64/aarch64/riscv64/arm) the
runtime object already provides a `putchar` and a `_start` through raw
syscalls, both `weak`, so a `-bare` program builds and runs with no board code
at all. Real freestanding targets (for example `arm-none-eabi-gcc`, which does
not define `__linux__`) supply their own `putchar` and startup. Because the
runtime is a separate object, a board source that defines a strong `putchar`
(or `_start`) simply overrides the weak default — no macros needed.

`cpm new` and `cpm init` write `lib/c-bare.h`. The easiest path is a bare `cpm`
project (below), which compiles and links the runtime object automatically.
Building by hand takes two objects:

```sh
c- -bare program.c- > program.c
printf '#define CMINUS_BARE_IMPL\n#include <c-bare.h>\n' > c-bare-runtime.c
# runtime: freestanding, builtins off so its own printf is not rewritten
cc -Os -ffreestanding -fno-builtin -Ilib -c c-bare-runtime.c -o c-bare-runtime.o
# program: NOT freestanding, so printf("...\n") can fold to puts
cc -Os -nostdlib -ffunction-sections -fdata-sections -Wl,--gc-sections \
   program.c c-bare-runtime.o -o program
```

Use `gcc` for the program object. `clang` currently miscompiles some generated
code (the checked-index statement expressions) at `-Os`/`-Oz`; it is fine for
programs that avoid those, which is why the runtime object itself builds with
either.

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

For the smallest runnable Linux ELF, also set `strip_sections = true`. Section
headers are not needed by the Linux loader, so `cpm` asks `strip` to remove
them after linking:

```toml
[package]
version = "0.5.0"

[build]
compiler = "clang"
cflags = "-std=gnu99 -Wall -Wextra -flto=thin"
bare = true
strip = true
strip_sections = true
```

The checked-in `small` project uses this mode and currently builds a runnable
`Hello World` ELF of about 274 bytes on x86-64 Linux.

`bare_runtime = false` remains available for comparison-only experiments. It
skips the runtime object; without your own `_start`, the result is not runnable.

Heap is a fixed static buffer; override its size with
`-DCMINUS_BARE_HEAP_SIZE=<bytes>`. `free` is a no-op (bump allocator).

Panics still work. Out-of-range index access calls `cminus_panic`, which prints
the original `.c-` source file and line number (`panic: index out of range at
program.c-:15`) through `putchar`, then `abort()`s. There is no stack-frame
backtrace in bare mode: `backtrace`/`backtrace_symbols_fd` are linked as no-ops,
so the source file and line are still reported but the frame dump is omitted.

`s"..."` heap strings still rely on `asprintf`, which the bare runtime provides.

Safe user structs are values by default. Use `Box<T>` when a struct must be a
managed heap owner; heap allocation with `new` is limited to structs:

```c
Box<Item> item = new Item;
```

`new`, `clone`, `s"..."`, `*_new()` functions, and owned-return function calls
assigned to local pointer declarations are treated as owning values. The
compiler tracks the local and emits cleanup at every function exit path,
including before `return`. Primitive heap allocations such as `new int` are no
longer valid; use an explicit allocator call only where raw heap use is
intended.

Use `borrow` when the pointer is not owned by the current function:

```c
borrow char* home = getenv("HOME");
```

`borrow` declarations are not freed. Assigning an owning expression such as a
struct `new` expression to a `borrow` declaration is a compile-time error.

The `new` operator allocates one zeroed struct object with `calloc` and returns
an owning `Box<T>`:

```c
Box<Item> item = new Item;
```

is lowered to:

```c
struct Item* item = calloc(1, sizeof(struct Item));
```

The generated cleanup releases `item` at the end of the current function.
On an early `return`, other tracked locals are released before the return.
Generated generic function instances also insert stack-frame cleanup before
early `return`, so stack lifetime tracking remains balanced across generic
code paths.

Use `move` to transfer ownership out of a variable:

```c
int* make_value(void)
{
    int* value = calloc(1, sizeof(int));
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
Box<Person> person = new Person { name: strdup("aaa"), age: 48 };
```

This is lowered to a `calloc(1, sizeof(struct Person))` temporary followed by
field assignments. Owned fields such as `owned char* name` are released by the
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

The standard library currently provides `Ref<T>`, `Span<T>`, `Iterator<T>`,
`RingBuffer<T>`, `Bitmap`, `Vec<T>`, `List<T>`, and `Map<K,V>`.
`Ref<T>` is a non-owning one-value reference with `from`, `is_null`, `get`, and
`set`. It is a value type: a local `Ref<T>` stores only checked reference
metadata in the current stack frame and does not allocate.
`Span<T>` is a non-owning contiguous view with `from`, `empty`, `len`,
`is_empty`, `get`, `get_opt`, checked indexed access, and `foreach`.
`Span<T>` also supports checked pointer-like operators: `span + n` and
`span - n` return shifted spans, `*span` reads `span[0]`, and `span[i]` can be
read or assigned through a bounds-checked pointer.
`Iterator<T>` is a function-pointer interface value. It has no inheritance and
stores only an opaque `self` pointer plus a generated `next` function. `next`
returns `__CMinusIndex<T>.Some(value)` or `None`.
`Vec<T>.as_span()` returns a non-owning view of the vector storage.
`Vec<T>.iter()` and `List<T>.iter()` return `Iterator<T>` values:

```c
Iterator<int> it = nums.iter();
struct __CMinusIndex<int> item;

while (1) {
    item = it.next();
    if (item.is_None()) {
        break;
    }
    sum += item.get_Some();
}
```

`List<T>.to_span(buffer, cap)` serializes list elements into caller-owned
storage and returns a `Span<T>` view. `Map<K,V>.keys_to_span(buffer, cap)` and
`Map<K,V>.values_to_span(buffer, cap)` serialize active keys or values into a
caller-owned buffer and return `Span<K>` or `Span<V>`.

For microcontroller-style fixed storage, keep the storage as a normal fixed
array and create checked views over it:

```c
struct Packet {
    unsigned char bytes[64];
};

Packet pkt;
Span<unsigned char> all = Span<unsigned char>.from(pkt.bytes);
FixedVec<unsigned char> used = FixedVec<unsigned char>.from(pkt.bytes);

used.push(0x12);
used.push(0x34);
int n = used.len();
unsigned char first = used[0];
```

`Span<T>.from(array)` and `FixedVec<T>.from(array)` infer the element count
from a fixed array, including struct fields such as `pkt.bytes`.
`RingBuffer<T>.from(array)` does the same for fixed-size queues. If the array
length is a macro expression, C- derives the count from `sizeof(array)` instead
of requiring the expression to be reduced by the parser. The explicit forms
`from(array, len)` and `from_bytes(array, bytes)` are still available.
`Span<T>`, `FixedVec<T>`, and `RingBuffer<T>` are value types: declaring a
local variable stores their metadata directly in the stack frame instead of
allocating a managed heap object. Methods still validate the referenced memory
before access, but the view/container header itself does not require heap
storage.
Use `span.get(index)` and `span.set(index, value)` when code needs explicit
checked reads and writes, especially in low-level code where nested expressions
should stay easy for the compiler to diagnose.
`Span<T>.fill(value)` fills the whole checked range and is intended for
zeroing fixed kernel buffers without dropping back to raw `memset`.
`Span<T>.slice(start, len)` returns a checked subrange, and
`copy_from(src)` / `copy_from_count(src, count)` copy between checked ranges.
These are useful for filesystem blocks, packets, page-table fragments, and
other fixed memory regions where raw `memcpy` would otherwise be tempting.
`Span<T>.map_from(buffer, len)` safely maps raw storage with a known length into
a typed view. For fixed arrays, C- inserts `sizeof(buffer)` automatically and
the runtime checks byte capacity and alignment before allowing typed access.
Use `Span<struct Header>.map_from(bytes, 1)` for packet headers, disk blocks,
MMIO-like records backed by fixed storage, and other layouts where copying would
be wasteful but unchecked casts would be unsafe.
For fixed NUL-terminated buffers, `cstr_len()`, `cstr_eq(other)`, and
`copy_cstr_from(src)` provide bounded string-style operations over the same
checked storage. They are useful for small kernel path buffers and firmware
protocol fields without calling unsafe C string functions.
Safe direct indexing of fixed arrays only allows compile-time constant indexes
that are in range. Out-of-range constants are compile-time errors, and variable
indexes must go through `Span<T>` or `FixedVec<T>` so bounds checks are always
present. This keeps embedded code heap-light while avoiding unchecked C array
access in safe mode.

A bare user struct is a value in safe mode. `Type name;` emits a zeroed
`struct Type name` and uses `.` field access. `Box<Type> name = new Type;`
creates managed heap storage. Struct values are
useful for packet buffers, device state, and fixed work areas where a
microcontroller program must avoid dynamic allocation.

Function parameters make borrowing explicit. `ref Type value` is a shared,
read-only reference and lowers to `const struct Type*`; `mut ref Type value` is
a mutable reference and lowers to `struct Type*`. A bare `Type value` parameter
passes the struct value rather than silently changing it into a pointer:

```c
int inspect(ref Device device);
void reset(mut ref Device device);
void consume(Device device);
```

For interrupt event queues, UART buffers, scheduler ready queues, and other
bounded kernel FIFOs, use `RingBuffer<T>` over caller-owned fixed storage:

```c
struct ReadyQueue {
    int slots[16];
};

ReadyQueue storage;
RingBuffer<int> ready = RingBuffer<int>.from(storage.slots);

ready.push(1);
ready.push(2);
struct __CMinusIndex<int> next = ready.pop_opt();
```

`RingBuffer<T>` provides `from`, `from_bytes`, `len`, `capacity`, `is_empty`,
`is_full`, `clear`, `push`, `peek_opt`, `pop_opt`, and `drain_to_span`. `push`
panics when the buffer is full; `peek_opt` and `pop_opt` return
`__CMinusIndex<T>` so empty queues can be handled explicitly. `drain_to_span`
copies queued values into caller-owned storage and returns a checked `Span<T>`
over the copied range. In safe mode, raw pointer storage returned from `unsafe`
functions cannot be converted into a `RingBuffer`; create the buffer from a
fixed array, managed object field, or a validated unsafe wrapper.

For page-frame allocation, file descriptors, PIDs, and other fixed slot maps,
use `Bitmap` over caller-owned `unsigned long` storage:

```c
struct PageMap {
    unsigned long words[4];
};

PageMap pages;
Bitmap map = Bitmap.from(pages.words);

struct __CMinusIndex<int> page = map.alloc_opt();
if (page.is_Some()) {
    int index = page.get_Some();
    map.free_bit(index);
}
```

`Bitmap.from(array)` infers the number of bits from `sizeof(array) * 8`.
`from(array, bit_count)`, `from_words(array, word_count)`, and
`from_bytes(array, byte_count)` are available when a smaller range is needed.
The API provides `len`, `word_len`, `is_empty`, `test`, `set`, `clear_bit`,
`clear_all`, `find_zero`, `alloc_opt`, and `free_bit`. Out-of-range bit access
panics. If a numeric literal bit count exceeds a fixed array's capacity, C-
rejects it at compile time. Safe code also rejects raw pointer storage from
unsafe functions; board code should wrap raw memory in a small unsafe boundary
before exposing a safe bitmap.

For stricter embedded builds, pass `-no-heap` to `c-` or set this in
`C-.toml`:

```toml
[build]
no_heap = true
```

In no-heap safe mode, managed heap-producing expressions such as `new`,
`clone`, `s"..."`, and heap-backed `Vec/List/Map` constructors are compile-time
errors. Use struct values, fixed arrays, `Optional<T>`, `Ref<T>`,
`Span<T>` views, `FixedVec<T>`, `RingBuffer<T>`, `Bitmap`, `StaticCell<T>`,
`Volatile<T>`, `Register<T>`, `Atomic<T>`, and `Critical` storage-oriented APIs instead. This
mode is intended to keep safe C- code predictable on microcontrollers by making
accidental heap use visible at build time. `Optional<T>` variants,
`Ref<T>.from(...)`, `Span<T>.from(...)`, and `FixedVec<T>.from(...)` are allowed
in no-heap mode because they return value-type metadata and do not allocate.
The embedded value types above also keep their metadata directly in the stack
or global object that stores them.

MMIO registers should be exposed through `Register<T>`. Creating a register
from a raw address is an unsafe boundary, but volatile register access after
that is safe:

```c
struct Uart {
    Register<unsigned int> status;
    Register<unsigned int> data;
};

int main(void)
{
    Uart uart;

    unsafe {
        uart.status = Register<unsigned int>.from_addr(0x10000000u);
        uart.data = Register<unsigned int>.from_addr(0x10000004u);
    }

    uart.data.write(0x41u);
    uart.status.set_bits(0x01u);
    uart.status.replace_bits(0x06u, 0x04u);
    unsigned int ready = uart.status.read();
    return ready;
}
```

`Register<T>` is also a value type, so a peripheral map can be stack-allocated
or embedded as fields without heap metadata. `from_addr` is rejected outside
`unsafe`; this keeps raw board addresses concentrated in a small hardware
abstraction layer while drivers use checked C- methods.

For register blocks, `mmio struct` is shorthand for `Register<T>` fields:

```c
mmio struct Uart {
    unsigned int status;
    unsigned int data;
};

int main(void)
{
    Uart uart;

    unsafe {
        uart.status = Register<unsigned int>.from_addr(0x10000000u);
        uart.data = Register<unsigned int>.from_addr(0x10000004u);
    }

    uart.data.write(0x41u);
    return uart.status.read();
}
```

Each scalar integer, enum, or bitflags field in a `mmio struct` is lowered to a
`Register<T>` field. Pointer fields, arrays, and initializer-like declarators
are rejected; use explicit `Register<T>` fields or an `unsafe` wrapper for
unusual layouts. This keeps board register maps compact while preserving safe
volatile access at the driver call site.

For volatile memory that is not a named device register, use `Volatile<T>`.
Like `Register<T>`, creating it from a raw address requires `unsafe`, while
`read()` and `write()` are safe after construction:

```c
unsigned int raw = 0u;
Volatile<unsigned int> cell;

unsafe {
    cell = Volatile<unsigned int>.from_addr((unsigned long)&raw);
}
cell.write(42u);
```

For heap-free shared storage, use `StaticCell<T>` instead of raw mutable global
state. It is a value type with explicit initialization state:

```c
StaticCell<int> boot_count = StaticCell<int>.uninit();

int main(void)
{
    boot_count.set(1);
    return boot_count.get();
}
```

`get()` and `replace()` panic if the cell has not been initialized. `set()`
initializes or overwrites the value.

Interrupt handlers can be declared with `interrupt void name(void)`. C- emits a
target compiler interrupt attribute, rejects non-`void` returns or parameters,
and treats the handler as an implicit no-heap function:

```c
Register<unsigned int> IRQ_STATUS;

interrupt void timer_irq(void)
{
    IRQ_STATUS.set_bits(0x01u);
}
```

Inside an interrupt handler, `new`, `clone`, `s"..."`, and heap-backed
collection constructors are compile-time errors, even inside nested `unsafe`
blocks. This keeps ISR code bounded and suitable for kernel or bare-metal
paths.

Kernel and board code can use a small set of declaration attributes without
spelling raw compiler attributes directly:

```c
export section(".vectors") int vectors[4];
aligned(4096) int page_table[1024];

weak int board_timer_init(void)
{
    return 0;
}

naked void trampoline(void)
{
    unsafe {
        __asm__ volatile("" : : : "memory");
    }
}
```

`section("name")`, `aligned(n)`, `packed`, `used`, `export`, `weak`, and
`naked` are lowered to the target C compiler's `__attribute__` form. These
attributes are intended for vector tables, page tables, boot stacks, packed
hardware layouts, assembly trampolines, and board override hooks. `export`
emits `used, externally_visible` so linker garbage collection and LTO are less
likely to discard an entry symbol. `weak` emits a weak symbol suitable for
default interrupt handlers, board hooks, and runtime stubs that platform code
may override. `naked` functions do not receive C- stack lifetime guards and are
treated as no-heap functions, so managed allocation is rejected in their body.

For kernel ABI checks, C- also provides compile-time layout helpers:

```c
struct TrapFrame {
    unsigned int r0;
    unsigned int r1;
    unsigned int pc;
};

static_assert(sizeof(TrapFrame) == 12, "trap frame size");
static_assert(offset_of(TrapFrame, pc) == 8, "pc offset");

no_return void halt_forever(void)
{
    for (;;) {
    }
}
```

`static_assert(...)` lowers to `_Static_assert(...)`. `offset_of(Type, field)`
lowers to the compiler builtin `__builtin_offsetof(...)`; for known C- structs,
the `struct` keyword is inserted automatically. `no_return` lowers to the C
compiler's `noreturn` function attribute. These checks are intended for trap
frames, syscall ABI structs, page-table entries, boot headers, and other places
where a layout mismatch should be a compile-time error instead of a boot-time
failure.

Linker-script symbols can be declared without exposing raw pointers to safe
code:

```c
linker_symbol __kernel_start;
linker_symbol __kernel_end;

unsigned long start = addr_of(__kernel_start);
unsigned long end = addr_of(__kernel_end);
```

`linker_symbol name;` lowers to `extern char name[];`. `addr_of(name)` lowers
to an `unsigned long` address value and is accepted only after a matching
`linker_symbol` declaration. This is intended for section bounds such as
kernel image ranges, `.bss` clearing, init arrays, physical memory maps, and
bootloader handoff data. Safe code receives an integer address; turning that
address into a pointer still belongs inside `unsafe`.

Address alignment helpers are available for page tables, section ranges, DMA
buffers, and allocator boundaries:

```c
unsigned long page = align_up(addr, 4096u);
unsigned long base = align_down(addr, 4096u);
int ok = is_aligned(page, 4096u);
```

`align_up`, `align_down`, and `is_aligned` take `unsigned long` values. An
alignment of zero panics with the caller's source file and line. `align_up`
also panics on unsigned overflow instead of wrapping an address across the
address space.

Typed flag sets can be declared with `bitflags`:

```c
bitflags PageFlags : unsigned int {
    Present = 1u,
    Write = 2u,
    User = 4u,
};

PageFlags flags = PageFlags_Present | PageFlags_Write;
```

This lowers to a C `typedef` plus prefixed constants such as
`PageFlags_Present`. C- keeps the flag set as a distinct type during checking,
so assigning `IrqFlags_Timer` to a `PageFlags` variable is a compile-time type
error. This is intended for page-table bits, interrupt masks, CPU status bits,
file modes, and other OS flag values where accidental mixing is easy.

For shared state between normal code, interrupts, and hosted threads, use
`StaticCell<T>` for one-time or guarded storage, value-type atomics for lock-free
scalar updates, critical-section guards for interrupt code, and pthread-backed
`Thread`/`Mutex`/`Cond` for hosted C99 builds:

```c
Atomic<unsigned int> ticks = Atomic<unsigned int>.init(0u);

interrupt void timer_irq(void)
{
    ticks.fetch_add(1u);
}

int read_ticks(void)
{
    Critical guard = Critical.enter();
    unsigned int now = ticks.load();

    guard.leave();
    return (int)now;
}
```

`Atomic<T>` uses compiler atomic builtins and is intended for integer or
pointer-sized scalar types. It does not require C11 `<stdatomic.h>`; C- emits
GCC/Clang `__atomic` builtins, so the generated C can stay at C99/gnu99. The
default methods use sequential consistency. Ordered variants such as
`load_order`, `store_order`, `exchange_order`, `compare_exchange_order`, and
`fetch_add_order` accept `AtomicRelaxed`, `AtomicAcquire`, `AtomicRelease`,
`AtomicAcqRel`, or `AtomicSeqCst`.

`Critical.enter()` returns a `Critical` value token and `leave()` is idempotent.
The default runtime hooks are no-ops for hosted tests; a kernel or board layer
can replace the interrupt save/restore implementation when integrating the
runtime.

Hosted thread support is a thin POSIX pthread wrapper:

```c
Atomic<int> total;
Mutex gate;

int worker(void)
{
    gate.lock();
    total.fetch_add(1);
    gate.unlock();
    return 0;
}

int main(void)
{
    Thread t;

    total = Atomic<int>.init(0);
    gate = Mutex.init();
    t = Thread.spawn(worker);
    t.join();
    gate.destroy();
    return total.load() == 1 ? 0 : 1;
}
```

Set `threads = true` in `C-.toml` to let `cpm build`, `cpm run`, `cpm val`, and
`cpm leak` add `-pthread` automatically. Bare builds ignore this flag.

Safe `Thread.spawn` entries are checked transitively. They cannot read or write
ordinary globals, call through an indirect function pointer, or call a function
without a visible safe definition. Shared global state must currently use
`Atomic<T>`, `Mutex`, or `Cond`.

One exclusive managed value can be moved into a thread:

```c
struct Work {
    int value;
};

int consume(owned Box<Work> work)
{
    return work.value;
}

Box<Work> work = new Work;
Thread thread = Thread.spawn(move work, consume);
```

Multiple values use the same positional form:

```c
Thread thread = Thread.spawn(move request, move response, consume_pair);
```

The worker must be a visible safe `int` function with matching owned
parameters in the same order. The `Send` check accepts managed owners such as
`Box<T>` and owned strings, while rejecting `Ref`, `Span`, raw/non-owning
pointers, runtime resources, and structs storing them. The moved source is no
longer usable. The check recursively follows nested user structs and owned
pointees, and handles cyclic `Box<Node>`-style types. Missing `move` and moving
one variable twice are rejected. By-value captures remain unsupported.

`Thread`, `Mutex`, `Cond`, and `Critical` are non-copyable resources in safe
mode. Initialize each variable separately and pass an existing resource with
`ref` or `mut ref`; by-value parameters, aliases, and resource fields in safe
structs are rejected. Joining and detaching the same thread concurrently is
also guarded atomically and panics instead of releasing its state twice.
Struct values containing owned/finalized fields are likewise non-copyable;
use `clone` for an independent value and `ref`/`mut ref` for borrowing.
Ordered atomic methods validate both the numeric order and operation-specific
rules before invoking the target compiler builtin.

`Vec<T>` and `List<T>` support `new`, `push`, `len`, `is_empty`, `clear`,
`first`, `last`, `get`, `set`, checked indexed access, automatic deletion for
owning local variables, and `foreach`. `Vec<T>` also supports `capacity`,
`reserve`, and `pop_opt`. `List<T>` also supports `push_front` and
`pop_front_opt`. `Map<K,V>` provides a generic hash table with `new`, `set`,
`get_opt`, `contains`, `remove`, `len`, `is_empty`, `clear`, and automatic
deletion for owning local variables.

Owning element containers are available as `OwnedVec<T>`, `OwnedList<T>`, and
`OwnedMap<K,V>`. They are intended for pointer element/value types. Insert
owned values with `move`; `set`, `remove`, `clear`, and `delete` free contained
values. `pop_opt` transfers an element out without freeing it. `OwnedMap`
owns values and treats keys as value or borrowed data.

```c
struct OwnedVec<int*>* xs = OwnedVec_new<int*>();
int* value = calloc(1, sizeof(int));
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

`Optional<T>` is built in as the standard nullable/absent value type. It is a
value-type payload enum with `Some(T)` and `None`, and can be written without a
leading `struct`. The `new Optional<T>.Variant(...)` syntax is accepted for
consistency with payload enums, but `Optional<T>` lowers to a stack value and
does not allocate managed heap storage:

```c
Optional<int> value = new Optional<int>.Some(123);
Optional<int> empty = new Optional<int>.None();
Optional<Ref<int>> borrowed = new Optional<Ref<int>>.Some(reference);

if (value.is_Some() && empty.is_None()) {
    return value.get_Some();
}
```

Generic payload types may be nested. When an `Optional` contains `Ref<T>`,
`Span<T>`, or another checked view, unwrapping copies the view together with its
lifetime metadata. Access through a view whose local owner has returned still
panics with `dangling stack reference`.

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

Struct fields should use the `owned` keyword for heap fields. Generated finalizers release owned fields when
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

Owned `char*` fields are treated like owned heap fields. The generated
finalizer frees the field, and the generated `StructName_clone` function
returns an owned `struct StructName*` allocated with `calloc`. Owned `char*`
fields are deep-copied with `calloc(strlen(src) + 1, sizeof(char))` and
`strncpy`, rather than copying the pointer:

```c
struct Person {
    owned char* name;
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

The old built-in `string` alias has been removed. Use `owned char*` directly.

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
are represented with chibicc-style `Node`, `Type`, and `Obj` records. Safe-mode
expression checks additionally build typed expression nodes for identifiers,
grouping, unary address/dereference, calls, indexes, member access, and binary
operators. Raw heap/C calls, pointer dereference, and fixed-array index checks
walk this tree. Assignment type inference, owned-value alias/move recognition,
borrow-root tracking, and raw-pointer argument taint also use the expression
nodes, so parentheses, comments, and comma expressions cannot change the
security result. After statement lowering, declarations, assignments,
expression statements, and returns are rebuilt as typed statement nodes. A
declaration node records its `Type`, `Obj`, name, and initializer expression;
assignment and return nodes retain their typed expression root. Function
definitions similarly own their typed body-node list. The statement emitter
then reproduces C from the AST-owned source ranges, preserving comments and
formatting while moving the statement/code-generation boundary away from raw
`Text`. Braced `if`/`else`, `while`, `for`, `switch`, and `do` blocks are also
control AST nodes which own their body-node list. Their condition is a typed
expression; `for` additionally separates its initializer and increment, with a
declaration initializer represented as a declaration node. Control blocks are
emitted from their AST-owned head, brace, body, and closing source fragments.
Ordinary labels and `case`/`default` labels are dedicated statement nodes;
`case` owns its typed constant expression. Standalone braced blocks likewise
own their child statement list and are emitted from AST-owned brace/body
fragments.
Value-less control transfers are explicit `goto`, `break`, and `continue`
nodes, so they do not masquerade as untyped expression statements. Safe mode
also enforces AST completeness after lowering: a nonempty expression,
initializer, return value, case value, or control condition that cannot be
represented by the typed AST is a compile-time error. Intentional compiler-
specific C remains available inside `unsafe` or `inline c`; `return;`, a plain
`else`, and the omitted clauses of `for (;;)` remain valid value-less syntax.
Initializer lists, static assertions, and `offsetof` queries have dedicated
typed expression forms instead of being exempted from this check.
Top-level `struct`, `union`, and `enum` definitions have dedicated aggregate
nodes containing the tag type and field/body statement list. Preprocessor lines
that remain in generated C are represented by source-preserving preprocessor
nodes; compiler-consumed C- includes and defines remain metadata instead of
output nodes.
When ownership finalization or stack guards insert statements before a return,
the return node retains the final typed return expression and owns a generated
`cleanup` child for the preceding C fragment. This prevents lowering from
collapsing the return back into an untyped raw statement.
Declarations and assignments lowered into several top-level C statements are
represented by an `expansion` node. Its children are reparsed as typed
declarations, assignments, and expression statements; trailing generated
release blocks are explicit `cleanup` children. Semicolons inside calls,
initializers, GNU statement expressions, strings, and comments do not split the
expansion.
Compiler-consumed directives are retained in a separate directive metadata AST.
For example, a consumed define is shown by `--dump-typed-ast` as
`directive define MACRO_NAME`, even though its placement is managed through the
compiler prelude rather than the source-preserving output tree.
Generic application and qualified method calls are represented
explicitly as well: reference constructors such as `Ref<T>.from` and
`Span<T>.from`, plus owned-returning calls, are classified by AST nodes instead
of scanning for function-name text. Expression-level generic concretization and
method-call lowering are dispatched only from matching AST source sites, and
owned-return temporaries use AST call ranges. Generic type declarations still
use the declaration/type parser. Method lowering first builds a sorted,
non-overlapping replacement plan from call nodes, then emits unchanged source
gaps and lowered C fragments; nested calls are handled by rebuilding the AST on
the next lowering pass. The final source is represented by a `translation-unit`
node with a `source-body` child that owns the typed top-level nodes. A leading
preserved define section, when present, is a `source-prefix` child. These source
nodes emit their source-preserving token buffers through the AST output path.
Incrementally generated payload-enum
helpers and default-argument macro fragments are retained as `payload-helpers`
and `default-macro` generated-artifact AST nodes before their C text is emitted.
Generic declarations consumed during parsing are retained separately as
`generic-struct-template` and `generic-function-template` metadata nodes. Each
template node owns the typed declaration or statement nodes from its original
body, while its concrete emitted forms remain linked through the existing
generic generated-artifact nodes.
Concrete generic artifacts also own a parsed definition header: generated
struct artifacts contain a concrete `struct` child, prototypes contain a
`function-declaration` child, and generated bodies contain a concrete
`function` child. This makes instantiated names and return types available
without reparsing the complete emitted translation unit.
Concrete struct fields and function bodies are cloned from their template AST
with the type parameter replaced, then declarations, expressions, and control
heads are typed again. The child tree therefore represents the concrete
language-level body; C-only stack guards and similar instrumentation remain in
the enclosing generated artifact text.
Ordinary source prototypes use the same `function-declaration` node as generic
prototypes instead of falling back to a general declaration. Function
declarations and definitions both own an explicit `return-type` child and
`parameter` children containing the registered parameter name and resolved
`Type`, so their signatures can be inspected without scanning the function-head
text. Generic function, struct, and payload-enum templates likewise own one
`type-parameter` child per declared parameter; multi-parameter declarations such
as `generic<K,V>` retain `K` and `V` as separate typed nodes.
Variable declarations and parameters also own an explicit `type` child. A
generic application records its template name and has one `type-argument`
child per applied argument, so `Map<int,int>` remains a structured `Map`
application instead of being observable only as its lowered C tag
`struct Map_int_int`. The semantic lowered type is retained alongside that
source structure for code generation and safety checks.
Ownership analysis is represented in the same tree. Owned and borrowed
declarations have an `ownership` child, moves retain a `move-transfer` child
with the consumed source even after lowering removes the `move` keyword, and a
borrow has a `lifetime` child naming its owner. Stack-backed safe references
are marked `storage=stack` and `runtime-check=yes`; borrowed parameters use the
caller as their lifetime owner. These are snapshots of the safety analysis,
not guesses reconstructed from the generated C.
Aggregate members are distinct `field` nodes rather than ordinary local
declarations. Their `type` children retain generic arguments, and fixed arrays
own an `array-dimension` child with the checked length. Struct-member type
lookup consults this aggregate AST first, with the older field table retained
only as a compatibility fallback while migration continues. Concrete generic
struct ASTs receive substituted field types instead of copying template `T`
types unchanged.
Ordinary C-style enums also own `enum-member` nodes. Explicit initializer
expressions are parsed once into typed expression trees, while constant
integer expressions are evaluated for the member value and the following
implicit member sequence. Comments and commas inside trivia do not split the
member list. Payload enums and bitflags keep their specialized AST nodes.
When a parameter has a default value, its node also owns the parsed typed
default expression. For example, a dependent default such as `a = b + 1` is a
binary expression, while an integer default is a literal; macro generation no
longer needs to be the only observable representation of those defaults.
`--dump-typed-ast` recursively exposes expression trees below their owning
statement. Calls distinguish the callee and each argument; binary, conditional,
index, member, grouping, generic, address, and dereference nodes show their
operands, operator, resolved type, and constant integer value where available.
Prefix and postfix increment/decrement are dedicated `update` expressions.
They retain the `++`/`--` operator, their prefix/postfix form, typed operand,
and also appear as the explicit increment expression owned by a `for` node.
All C compound assignments, including bitwise and shift forms (`&=`, `|=`,
`^=`, `<<=`, and `>>=`), remain typed assignment expressions rather than
falling back to an empty expression statement.
C casts, `sizeof`, `_Alignof`, and the remaining prefix unary operators are
structured expressions too. A cast or type-form size query retains its source
type spelling, while expression-form `sizeof` owns the typed operand. Size and
offset queries have the opaque typedef type `size_t`; its representation width
remains target-defined without making the expression type unknown or assuming
that every target uses the host's `long` width.
Unknown expression types are never anonymous in the typed AST. The dump records
a reason such as `unresolved-call-return`,
`unresolved-symbol`, or `unknown-operand-type`, and safe-mode AST validation
rejects an unknown type that has no classified reason. This keeps opaque ABI
facts distinct from missed expression parsing without inventing a host-specific
type.
Known function identifiers use a distinct function type such as
`fn()->int`; the enclosing call takes its result type from that function type.
Enum members are registered as typed constants when their declaration AST is
built, and predefined `__FILE__`, `__func__`, and `__LINE__` expressions have
their standard character-pointer or integer types. These identifiers therefore
no longer appear as unresolved symbols in later safe expressions.
Object-like preprocessor definitions whose replacement is a typed constant are
registered for the final AST pass as well. Common hosted calls such as `printf`
retain their builtin function signature even when encountered through a bare or
unsafe boundary. Default-parameter expressions use their declared parameter
type to type call-site-dependent names that cannot be bound until expansion.
Lowering-generated `__cminus_return` temporaries inherit the enclosing
function's return type. Concrete generic function ASTs are rebuilt in a
temporary function scope containing their substituted parameters and local
declarations, allowing member and index expressions such as `self->data[i]` to
retain their concrete types. Compiler-generated checked-arithmetic, managed-GC,
and common memory helper calls also have builtin function signatures instead of
unresolved return types.
After all generic prototypes and generated artifacts have been materialized, a
final type-resolution pass revisits the retained AST. It reconstructs each
function's parameter and local scope, resolves function identifiers registered
later in translation, and propagates the resulting call/member/index types back
through their parent expressions. Concrete `Vec`, `List`, and `Map` calls are
therefore not left unresolved merely because their prototypes were emitted
after the original source node was parsed.
Attribute-qualified runtime functions are registered in a separate late AST
step, after source rewriting has finished. Their return and parameter types are
therefore available without exposing internal raw-pointer parameters to the
safe source call-rewriting rules. Generated payload-enum constructors,
predicates, and accessors register their concrete return types at generation
time. As a result, `Bitmap` and `__CMinusIndex<T>` helper calls also remain
typed throughout the final AST.
The same final pass revisits generic function templates with their symbolic
parameter and local scope. GCC atomic value builtins derive their result from
the pointee type of the first argument, so an atomic template retains `T`
instead of an unresolved call result; store and compare-exchange retain `void`
and `int`. Variadic builtins, `vsnprintf`, `fopen`, and internal alignment
helpers have explicit signatures. GNU `__alignof__` is represented by the same
`size_t`-typed `alignof` expression node as standard `_Alignof`, rather than
being misclassified as an unresolved function call.
The final pass also assigns `NULL` the type required by its use site. Binary
comparisons and assignments use the opposite operand, declarations and returns
use their declared type, and calls use the corresponding parameter type.
Parenthesized nulls retain the same context. A null whose surrounding member or
generic type is itself unresolved remains explicitly `contextual-literal`; it
is never guessed to be an arbitrary pointer type or reported as an unresolved
symbol.
Function parameter splitting treats commas inside generic applications as part
of the type, so a declaration such as `Map<K,V>* self` remains one parameter
instead of becoming `K` and `V* self`. Function-pointer declarators are also
retained directly: `R (*next_fn)(void*)` produces a field or parameter named
`next_fn` with type `fn()->R`. This lets member calls through Iterator-style
callbacks and their null checks participate in final type propagation.
Symbolic static method syntax such as `Span<T>.get` is linked to the matching
generic function template, preserving `fn()->T` and the call result before any
concrete instantiation exists. Generated payload-enum layouts expose typed
`tag`, `payload`, and variant fields to member lookup, so checked-index GNU
statement expressions propagate their final payload type to the parent node.
The final scope rebuild also scans every initializer in the chained `for`
loops produced by `foreach`, retaining the declared element variable type.
Generic aggregate names used as the receiver of symbolic static syntax have a
distinct type-constructor type (for example, `type Span`) instead of being
reported as unresolved value symbols. Runtime globals and constants used by
generated safety code, including `stderr`, allocation/stack limits, and
lowering-generated return temporaries, also retain their concrete types.
Typedef declarations have dedicated `typedef` nodes and are registered in the
type table before following declarations are analyzed. Alias chains and
function-pointer typedefs retain their resolved underlying type. Common
implementation-provided names such as `size_t` and `pthread_t` are opaque
typedefs, preserving their spelling without assuming a host-specific layout.
A pointer hidden behind a typedef remains a pointer for safe-mode validation,
so aliases cannot bypass the safe-mode pointer declaration ban.
GNU statement expressions synthesized by lowering are dedicated
`statement-expression` nodes. Their internal expression forest remains
walkable by safety analysis, declarations provide local operand types, and the
final value is marked `result=yes`. Declaration syntax, control keywords, and
punctuation are not emitted as fake value expressions; declaration
initializers remain ordinary typed expression children. Generic type spellings inside `sizeof`,
such as `sizeof(struct ListNode<T>)`, are retained as type-form size queries.
Uninstantiated generic parameters use a dedicated `TY_GENERIC` representation
instead of `unknown`. Generic function templates therefore retain typed return,
parameter, local, field, and expression information such as `T`, while applied
types containing `T` remain symbolic and do not accidentally register an
invalid concrete instance before substitution.
Payload-enum declarations are likewise retained as `payload-enum-template`
metadata. Their `payload-variant` children record the variant name and payload
type spelling, including generic parameters such as `T`; payload-free variants
remain explicit children without a type.
Typed flag declarations remain `bitflags` nodes in the translation-unit AST
after lowering to a C typedef and enum. The node records its base integer type,
and each `bitflag-member` child owns its typed constant-value expression.
Safe/unsafe transitions are explicit in the tree: an `unsafe` boundary owns the
typed declarations and statements parsed inside it, even though the C output
omits the C- keyword. Function definitions inside a top-level `unsafe` boundary
remain structured function nodes with raw-pointer parameters and typed bodies;
the boundary no longer turns them into anonymous raw blocks. An `inline-c` node
marks deliberately opaque raw C at both file and statement scope instead of
presenting it as typed C- statements.
`c- --dump-typed-ast input.c-` prints the current typed
function/statement tree to stderr while emitting C normally on stdout.

Generated runtime declarations, synthesized system includes, and the inlined
bare-metal runtime are emitted through `runtime-prelude` AST artifacts. Normal
generic struct instances, function prototypes, and function bodies similarly
use `generic-struct`, `generic-prototype`, and `generic-function` artifacts
instead of writing their completed `Text` buffers directly. The generated
artifact list is included at the end of `--dump-typed-ast` output. Payload-enum
variants can still be materialized incrementally, but the completed helper
fragment is captured by the generated-artifact AST before output.

Build and test:

```sh
make test
```

The parser is generated from `src/parser.y` with GNU Bison. The lexer is
generated from `src/lexer.l` with flex, while keeping comments/whitespace
attached to tokens so the output remains close to the input.
