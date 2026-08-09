# c-

Small C-to-C translator experiment.

Current language/package format version: `0.4.0`.

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
version = "0.4.0"
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

Safe structs cannot contain `Ref<T>` or `Span<T>` fields. C- does not yet have
lifetime parameters for stored references, so safe references must stay in local
variables, parameters, and return values that the compiler can check directly.
Store owned data in structs and create `Ref`/`Span` views at the call site.

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
version = "0.4.0"

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

Local pointer ownership is automatic for owning expressions. Heap allocation
with `new` is limited to structs:

```c
struct Item* item = new struct Item;
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
an owning pointer:

```c
struct Item* item = new struct Item;
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
struct Person* person = new Person { name: strdup("aaa"), age: 48 };
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
`Vec<T>`, `List<T>`, and `Map<K,V>`.
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

stack Packet pkt;
Span<unsigned char> all = Span<unsigned char>.from(pkt.bytes);
FixedVec<unsigned char> used = FixedVec<unsigned char>.from(pkt.bytes);

used.push(0x12);
used.push(0x34);
int n = used.len();
unsigned char first = used[0];
```

`Span<T>.from(array)` and `FixedVec<T>.from(array)` infer the element count
from a fixed array, including struct fields such as `pkt.bytes`. The explicit
forms `from(array, len)` and `from_bytes(array, bytes)` are still available.
`Span<T>` and `FixedVec<T>` are value types: declaring a local variable stores
their metadata directly in the stack frame instead of allocating a managed heap
object. Methods still validate the referenced memory before access, but the
view/container header itself does not require heap storage.
Use `span.get(index)` and `span.set(index, value)` when code needs explicit
checked reads and writes, especially in low-level code where nested expressions
should stay easy for the compiler to diagnose.
Safe direct indexing of fixed arrays only allows compile-time constant indexes
that are in range. Out-of-range constants are compile-time errors, and variable
indexes must go through `Span<T>` or `FixedVec<T>` so bounds checks are always
present. This keeps embedded code heap-light while avoiding unchecked C array
access in safe mode.

`stack Type name;` declares a user struct as an actual stack object in safe
mode. Normal `Type name = new Type;` still creates managed heap storage, while
`stack Type name;` emits a plain `struct Type name = {0};` and uses `.` field
access. Stack structs are useful for packet buffers, device state, and fixed
work areas where a microcontroller program must avoid dynamic allocation.

For stricter embedded builds, pass `-no-heap` to `c-` or set this in
`C-.toml`:

```toml
[build]
no_heap = true
```

In no-heap safe mode, managed heap-producing expressions such as `new`,
`clone`, `s"..."`, and heap-backed `Vec/List/Map` constructors are compile-time
errors. Use stack structs, fixed arrays, `Optional<T>`, `Ref<T>`,
`Span<T>` views, `FixedVec<T>`, `StaticCell<T>`, `Volatile<T>`,
`Register<T>`, `Atomic<T>`, and `Critical` storage-oriented APIs instead. This
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
    stack Uart uart;

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
    stack Uart uart;

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

For shared state between normal code and interrupts, use `StaticCell<T>` for
one-time or guarded storage, and value-type atomics plus critical-section
guards for concurrent updates:

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
pointer-sized scalar types. `Critical.enter()` returns a `Critical` value token
and `leave()` is idempotent. The default runtime hooks are no-ops for hosted
tests; a kernel or board layer can replace the interrupt save/restore
implementation when integrating the runtime.

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

if (value.is_Some() && empty.is_None()) {
    return value.get_Some();
}
```

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
