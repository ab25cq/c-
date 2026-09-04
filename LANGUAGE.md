# C- Language Reference

This document describes the C- `0.5` surface language. C- is a source-to-source
language: it accepts a C-like program, checks and rewrites C- features, and emits
C for the selected target compiler.

The implementation remains the final authority for `0.5`. This reference is a
language contract toward which the parser and diagnostics should converge.

## 1. Language profiles

C- has three source profiles.

### 1.1 Safe mode

Safe mode is the default. It rejects raw pointer declarations, pointer
dereference, pointer arithmetic, casts, raw heap functions, selected unsafe C
APIs, and calls to functions declared in an `unsafe` context.

Safe code uses managed struct references, `Ref<T>`, `Span<T>`, `Optional<T>`,
and checked collection types instead of raw pointers.

### 1.2 C compatibility mode

The package setting `c_compat = true` preserves C declarations, preprocessor
directives, and C99 constructs needed when porting existing C. User functions
in this mode are emitted as C without safe-mode ownership and stack-guard
rewriting.

### 1.3 Raw C regions

`unsafe` permits checked C- code to perform operations that safe mode rejects.
It does not disable all C- lowering.

`inline c` is a raw-C emission boundary. Declarations inside it are only
partially visible to the C- type and ownership checker.

```c
unsafe {
    unsigned int* register_ptr = (unsigned int*)0x10000000u;
    *register_ptr = 1u;
}

inline c {
typedef void (*Handler)(void);
}
```

## 2. Grammar notation

The grammar uses this notation:

```text
name        nonterminal
"text"      literal token
[ item ]    optional item
{ item }    zero or more repetitions
item | item alternatives
```

`c-expression`, `c-declarator`, and similar names denote C token syntax that
the current translator preserves and delegates partly to the target C
compiler. This is deliberate: the current parser does not yet construct a
complete expression AST.

Whitespace and comments may appear between tokens unless a lexical form, such
as a string literal, says otherwise.

## 3. Lexical forms

```ebnf
identifier     = letter-or-underscore, { letter-or-digit-or-underscore } ;
integer        = decimal-integer | hexadecimal-integer ;
string-literal = [ "L" ], '"', { string-character | escape }, '"' ;
char-literal   = [ "L" ], "'", ( character | escape ), "'" ;
heap-string    = "s", string-literal ;
```

Identifiers are case-sensitive. C keywords retain their C meaning. C-
contextual keywords include:

```text
Box aligned bitflags borrow clone export foreach inline interrupt linker_symbol
mmio move mut naked new no_return owned packed ref section uniq unsafe used weak
```

Because these are recognized contextually by the `0.5` translator, programs
should not use them as ordinary declaration names.

## 4. Translation unit

```ebnf
translation-unit = { external-item } ;

external-item = preprocessor-line
              | declaration, ";"
              | function-definition
              | struct-definition, ";"
              | generic-struct-definition, ";"
              | union-definition, ";"
              | enum-definition, ";"
              | payload-enum-definition, ";"
              | bitflags-definition, ";"
              | mmio-struct-definition, ";"
              | unsafe-external-block
              | inline-c-block
              | linker-symbol-declaration
              | static-assertion ;

unsafe-external-block = "unsafe", "{", { external-item }, "}" ;
inline-c-block = "inline", "c", "{", raw-c-token-sequence, "}" ;
```

Top-level `#include <c-.h>` is optional in package builds. The package manager
loads the project standard library automatically.

`uniq` may prefix a top-level function or global definition that must be
emitted only once in a multi-source build.

```ebnf
unique-definition = "uniq", ( function-definition | object-definition ) ;
```

## 5. Types

```ebnf
type = c-scalar-type
     | tagged-type
     | bare-struct-type
     | generic-type
     | box-type
     | raw-pointer-type ;

tagged-type      = ( "struct" | "union" | "enum" ), identifier ;
bare-struct-type = identifier ;
generic-type     = identifier, "<", type-argument-list, ">" ;
box-type         = "Box", "<", bare-struct-type, ">" ;
type-argument-list = type, { ",", type } ;
raw-pointer-type = type, { "*" } ;
```

Raw pointer types are allowed only in `unsafe`, `inline c`, or C compatibility
contexts. A type must be declared before its bare tag name can be recognized as
a struct, union, or enum type.

Generic structs, functions, and payload enums are monomorphized. General type
inference is not performed. `auto` inference is currently limited primarily to
payload-enum constructors.

### 5.1 Safe value, owner, and reference rule

In safe mode, a bare user-struct type uniformly denotes a value:

```c
Data local;                         // local value
Box<Data> item = new Data;          // managed owning heap value
void inspect(ref Data item);        // shared reference
void update(mut ref Data item);     // mutable reference
void consume(Data item);            // value parameter
```

The generated C is conceptually:

```c
struct Data local = {0};
struct Data* item = cminus_gc_calloc(1, sizeof(struct Data));
void inspect(const struct Data* item);
void update(struct Data* item);
void consume(struct Data item);
```

`ref` lowers to a const C pointer and `mut ref` lowers to a mutable C pointer.
`Box<T>` is accepted for concrete user
structs and participates in automatic finalization and ownership transfer.

Heap-backed standard containers (`Vec`, `List`, `Map`, their owning variants,
and `Iterator`) retain value-like surface spelling while using managed handles
internally. `Optional<T>`, `Span<T>`, `Register<T>`, and the other fixed-storage
standard types store their metadata directly by value.

## 6. Structs, unions, enums, and bitflags

```ebnf
struct-definition = "struct", identifier,
                    "{", { field-declaration }, "}" ;

generic-struct-definition = "generic", generic-parameters,
                            "struct", identifier,
                            "{", { field-declaration }, "}" ;

union-definition  = "union", identifier,
                    "{", { field-declaration }, "}" ;

enum-definition   = "enum", identifier,
                    "{", enum-item, { ",", enum-item }, [ "," ], "}" ;

generic-parameters = "<", identifier, { ",", identifier }, ">" ;
field-declaration  = [ "owned" ], type, c-declarator, ";" ;
enum-item          = identifier, [ "=", c-constant-expression ] ;
```

An `owned` pointer field participates in the generated struct finalizer and
clone operation.

Payload enums use Rust-like single-payload variants:

```ebnf
payload-enum-definition = "enum", identifier, generic-parameters,
                          "{", payload-variant,
                          { ",", payload-variant }, [ "," ], "}" ;
payload-variant = identifier, [ "(", type, ")" ] ;
```

```c
enum Result<T> {
    Ok(T),
    Error(int),
};
```

Each variant receives `is_Variant()` and, when it has a payload,
`get_Variant()` methods. `Optional<T>` is the built-in `Some(T)`/`None`
payload enum and is a non-allocating value type.

Generic payloads may be nested, for example `Optional<Ref<int>>` and
`Optional<Span<char>>`. Checked-view lifetime metadata is copied with the
payload, so accessing an unwrapped view after its local owner has returned
panics with `dangling stack reference`.

Typed bit sets are declared as:

```ebnf
bitflags-definition = "bitflags", identifier, ":", integer-type,
                      "{", bitflag-item,
                      { ",", bitflag-item }, [ "," ], "}" ;
bitflag-item = identifier, "=", c-constant-expression ;
```

Constants are emitted with the type name as a prefix. Values belonging to
different bitflag types cannot be assigned to each other in safe code.

## 7. Declarations and storage

```ebnf
declaration = safe-struct-value-declaration
            | safe-reference-declaration
            | boxed-declaration
            | borrowing-declaration
            | owning-declaration
            | ordinary-declaration ;

safe-struct-value-declaration = bare-struct-type, identifier,
                                [ "=", initializer ] ;
safe-reference-declaration = [ "mut" ], "ref", bare-struct-type,
                             identifier, [ "=", expression ] ;
boxed-declaration = box-type, identifier, [ "=", owning-expression ] ;
borrowing-declaration = "borrow", type, c-declarator,
                        [ "=", expression ] ;
owning-declaration    = [ "owned" ], type, c-declarator,
                        "=", owning-expression ;
ordinary-declaration = type, c-declarator, [ "=", expression ] ;
```

`Type name;` zero-initializes a user-struct value without heap allocation.
Ordinary uninitialized locals are also zero-initialized by the translator.

Fixed C arrays are permitted. In safe mode, direct indexing uses only an
in-range compile-time constant. Variable indexing must go through a checked
view such as `Span<T>` or `FixedVec<T>`. A local array larger than 64 KiB is
rejected in safe mode; use `Box` or a checked heap collection instead. Safe
functions also have runtime depth and tracked-byte stack budgets, whose default
limits are 1024 frames and 2 MiB.

## 8. Functions and parameters

```ebnf
function-definition = [ "generic", generic-parameters ],
                      { declaration-attribute }, [ "interrupt" ],
                      type, identifier,
                      "(", [ parameter-list ], ")", compound-statement ;

parameter-list = parameter, { ",", parameter } | "void" ;
parameter      = [ "borrow" | "owned" | "ref" | "mut", "ref" ],
                 type, c-declarator,
                 [ "=", expression ] ;
```

A default argument is written in the declaration or definition. Calls may use
positional arguments, labels, or both:

```c
void draw(int x, int y = 0, int color = 1);
draw(10, color: 7);
```

Labeled arguments are reordered into parameter order. Missing arguments must
have defaults. Default expressions are inserted as source text at the call
site and are resolved in the caller's C scope.

An interrupt handler has this restricted form:

```ebnf
interrupt-function = "interrupt", "void", identifier, "(", "void", ")",
                     compound-statement ;
```

Interrupt and `naked` functions are implicitly no-heap.

## 9. Statements

```ebnf
statement = compound-statement
          | declaration-statement
          | expression-statement
          | selection-statement
          | iteration-statement
          | jump-statement
          | foreach-statement
          | unsafe-statement
          | inline-c-statement
          | static-assertion ;

compound-statement = "{", { statement }, "}" ;
foreach-statement  = "foreach", "(", type, identifier, "in", expression,
                     ")", statement ;
unsafe-statement   = "unsafe", compound-statement ;
inline-c-statement = "inline", "c", compound-statement ;
```

The ordinary `if`, `switch`, `while`, `do`, `for`, `break`, `continue`,
`goto`, and `return` forms follow C syntax. C- inserts ownership cleanup before
each return path.

`foreach` requires an explicit element type. It supports checked spans and the
collection types for which the standard library provides lowering.

## 10. Expressions

The ordinary expression grammar follows the configured C compiler, subject to
C- safe-mode checks and rewrites. C- adds these primary forms:

```ebnf
expression = c-expression
           | new-expression
           | clone-expression
           | move-expression
           | heap-string
           | method-call
           | indexed-expression ;

new-expression = "new", type, [ "(", [ argument-list ], ")" ]
               | "new", type, object-initializer
               | "new", generic-type, ".", identifier,
                 "(", [ argument-list ], ")" ;

object-initializer = "{", object-field,
                     { ",", object-field }, [ "," ], "}" ;
object-field       = identifier, ":", expression ;
clone-expression   = "clone", expression ;
move-expression    = "move", identifier ;
method-call        = expression, ( "." | "->" ), identifier,
                     "(", [ argument-list ], ")" ;
argument-list      = argument, { ",", argument } ;
argument           = [ identifier, ":" ], expression ;
```

`new` allocates user structs but returns value-type payload enum constructors
without allocation. `new` and other heap-producing operations are rejected in
no-heap contexts.

`move name` transfers ownership and makes the source unavailable. `clone`
creates an independently owned result when cloning is defined for the type.

A method call is lowered to a free function whose name follows the
`Type_method` convention. It does not declare a separate method namespace.

### 10.1 Heap strings

```c
string message = s"value = \{value}";
```

An `s"..."` expression creates an owned formatted string. Interpolations are C
expressions enclosed by `\{` and `}`. Heap strings are forbidden in no-heap
contexts. The legacy `string` surface type is still recognized in parts of the
current compiler and test suite, but new code should use the ownership spelling
documented by the project standard library.

## 11. Ownership and borrowing

An owning expression includes:

- a heap-allocating `new` expression;
- `clone` of a cloneable owned value;
- a heap string;
- a known allocation-returning function;
- a function whose return is tracked as owned.

`Box<T>` makes ownership visible in declarations and return types. A boxed
value is finalized at scope exit unless ownership is transferred with `move`.

An owning local is finalized on every normal function exit. Assignment to an
owning local first releases its old value. `move` transfers responsibility and
prevents subsequent use of the source.

`borrow` marks a raw-pointer/string declaration as non-owning in contexts where
that spelling is permitted. Safe non-owning access should normally use
`Ref<T>` or `Span<T>`.

The current lifetime checker rejects known escapes from stack storage and use
after a known owner move or reassignment. It is conservative but is not yet a
general Rust-style lifetime/type proof: expressions not modeled by the
translator may remain unknown and be delegated to C.

Safe structs cannot store `Ref<T>` or `Span<T>` fields because C- `0.5` has no
lifetime parameters for stored references.

Hosted `Thread`, `Mutex`, and `Cond` values and the `Critical` guard are
non-copyable in safe mode. They cannot be passed by value or stored as safe
struct fields; pass them with `ref`/`mut ref`. This prevents two value aliases
from joining, destroying, or leaving the same runtime resource twice.

Both safe thread forms perform a transitive typed-AST check of the entry
function. Ordinary globals, indirect calls, and calls without a visible safe
definition are rejected. Global `Atomic<T>`, `Mutex`, and `Cond` values are the
permitted shared synchronization surface. In safe mode, `Atomic<T>` accepts
only non-pointer integer, enum, and bitflags payloads. `Ref<T>`, `Span<T>`,
owned/raw pointers, floating-point values, structs, and runtime resources are
not `Sync` atomic payloads. A global `Mutex` does not implicitly protect a
separate ordinary global; that state remains rejected until C- has an explicit
lock-coupled shared container.

`Shared<T>` is the lock-coupled global container for copy-safe structured
state. Declare it at file scope and use `load()`/`store()`; each operation holds
its internal mutex for the complete value copy. For a value struct, spell the
payload explicitly, for example `Shared<struct Pair> state;`. Payloads are
checked recursively and cannot contain pointers, references, arrays, owned or
finalizer-bearing fields, or runtime resources. The representation and lock are
private. `load()` followed later by `store()` is two transactions; use
`Atomic<T>` for supported read-modify-write operations. For a compound update,
`SharedGuard<struct Pair> guard = state.lock();` keeps the mutex locked across
the guard's `load()` and `store()` calls. The guard is non-copyable and unlocks
automatically at scope exit, including early returns. Explicit `unlock()` is
idempotent; later guard access panics. `wait()` atomically releases the same
internal mutex and reacquires it before returning. `notify_one()` and
`notify_all()` are guard methods, keeping the condition variable, predicate
data, and mutex inseparable. Always recheck the predicate in a loop because
condition waits may wake spuriously.

The representation fields of `Atomic`, `Thread`, `Mutex`, `Cond`, and
`Critical` are private in safe code; use their checked methods. A shared global
`Atomic<T>` cannot be replaced by direct struct assignment. Global atomics are
zero-initialized, and runtime initialization uses `store()`.

Global `Mutex` and `Cond` values have static lifetime. Declare them with zero
initialization (`Mutex gate;`) and use them directly; their native resources are
initialized once on first use, including when threads race on that first use.
Safe code cannot assign or destroy a global `Mutex`/`Cond`. Local synchronization
resources may still use explicit `init()` and `destroy()`, and access after
destruction panics.

Hosted mutexes are error-checking mutexes. Locking one twice on the same thread,
unlocking it from a thread that does not own it, and calling `Cond.wait` without
owning the supplied mutex panic instead of deadlocking or entering pthread
undefined behavior.

Local `Thread`, `Mutex`, `Cond`, and `Critical` values are scope-finalized. A thread handle
that was not joined or detached is detached automatically, matching Rust's
`JoinHandle` drop behavior. Local mutexes and condition variables are destroyed
automatically; explicit `destroy()` remains allowed and is idempotent.
Runtime resources cannot currently be returned from a safe function because
that would cross the cleanup boundary; complete their operation in the scope
that created them. Runtime-resource bindings are currently immovable in safe
code; pass them by `ref`/`mut ref` and keep one cleanup owner. Arrays of runtime
resources are rejected until element-wise cleanup is supported.

An exclusive managed value can be transferred to a worker:

```c
int worker(owned Box<Job> job)
{
    return job.result;
}

Box<Job> job = new Job;
Thread thread = Thread.spawn(move job, worker);
```

Multiple owners are listed before the worker and matched positionally:

```c
Thread thread = Thread.spawn(move request, move reply, worker);
```

Stack values use the same syntax; the compiler copies their representation into
the private startup context while transferring any owned fields:

```c
State state;
Thread thread = Thread.spawn(move state, state_worker);
```

The worker declares the corresponding parameter as `owned State state`.
Managed owners and stack values can be mixed in one spawn. The worker must
return `int` and have matching owned parameters. The
`Send` predicate accepts owned managed heap values and rejects `Ref`, `Span`,
raw/non-owning pointers, runtime resources, and structs containing them. The
moved source cannot be used afterward. User structs and their owned pointees
are checked recursively, including cyclic `Box<Node>`-style type graphs.
Moving the same variable twice is rejected, and every moved source becomes
unusable after the spawn expression.

Outside `Thread.spawn`, an `owned` parameter also consumes its argument:

```c
consume(move message);
consume(new Job);       // fresh owned rvalues transfer directly
```

Passing an existing owner without `move` is a compile-time error.

## 12. Unsafe boundary

The following operations require `unsafe` in safe mode:

- declaring or dereferencing a raw pointer;
- pointer arithmetic;
- explicit C casts;
- raw allocation and deallocation;
- constructing `Register<T>` or `Volatile<T>` from an address;
- inline assembly;
- calling a function declared in an `unsafe` block;
- selected C string, memory, and file operations;
- reading a raw pointer field declared by an unsafe struct.

`unsafe` grants permission to perform these operations; it does not assert that
they are correct. A small unsafe wrapper should validate raw state and return a
safe value, `Optional<T>`, `Ref<T>`, or `Span<T>` interface.
Explicit `extern` function declarations must also be placed inside `unsafe`.
The complete trusted-boundary contract is specified in `SAFETY.md`.

## 13. No-heap mode

The compiler option `-no-heap`, or package setting `no_heap = true`, rejects:

- allocating `new` expressions;
- heap-producing `clone` expressions;
- heap strings;
- heap-backed collection constructors;
- allocation inside interrupt and naked functions.

It permits fixed arrays, struct values, and non-allocating value/view types such
as `Optional<T>`, `Ref<T>`, `Span<T>`, `FixedVec<T>`, `RingBuffer<T>`,
`Bitmap`, `StaticCell<T>`, `Volatile<T>`, `Register<T>`, `Atomic<T>`, and
`Critical`.

## 14. OS and bare-metal declarations

```ebnf
declaration-attribute = "section", "(", string-literal, ")"
                      | "aligned", "(", integer, ")"
                      | "packed" | "used" | "export" | "weak"
                      | "naked" | "no_return" ;

linker-symbol-declaration = "linker_symbol", identifier, ";" ;
static-assertion = "static_assert", "(", c-constant-expression,
                   ",", string-literal, ")", ";" ;
```

`addr_of(name)` accepts a previously declared linker symbol and yields an
integer address. Converting it to a pointer remains unsafe.

`offset_of(Type, field)`, `align_up`, `align_down`, and `is_aligned` provide
checked layout/address helpers.

An MMIO struct rewrites supported scalar fields to `Register<T>`:

```ebnf
mmio-struct-definition = "mmio", "struct", identifier,
                         "{", { mmio-field }, "}" ;
mmio-field = mmio-scalar-type, identifier, ";" ;
```

Pointer, array, and initializer-like MMIO fields are rejected.

## 15. Implementation limits in version 0.5

The `0.5` parser recognizes balanced token groups and then performs many
declaration, expression, ownership, and method transformations on preserved
source text. Consequently:

- this document is more precise than the current parser's acceptance boundary;
- some malformed input may be diagnosed only by the generated-C compiler;
- some valid but complex C expressions may not receive full C- type analysis;
- macro-expanded syntax is generally invisible to C- checks;
- fixed compiler tables impose implementation limits on symbols, functions,
  fields, parameters, generic instances, and tracked owned values.

New syntax should first be added to this reference, then to focused positive
and negative parser tests. Moving declaration and expression recognition into
typed AST nodes should be preferred over adding new source-text searches.

## 16. Rust-like value and reference model

Rust places a struct value in the current storage by default:

```rust
let mut kernel = Kernel::new();       // local value, normally on the stack
let boxed = Box::new(Kernel::new());  // explicit heap allocation
fn inspect(kernel: &Kernel) {}        // shared borrow
fn update(kernel: &mut Kernel) {}     // exclusive mutable borrow
fn consume(kernel: Kernel) {}         // value move
```

Rust does not need a `stack` keyword. Stack versus heap is determined by the
containing value: `Kernel` is a value, while `Box<Kernel>` is an owning heap
pointer. A compiler may optimize physical placement, but the ownership
semantics remain those shown above.

The corresponding C- syntax is:

```c
Kernel kernel;                         // value, zero-initialized locally
Kernel kernel = Kernel { ticks: 0 };   // value initializer
Box<Kernel> boxed = new Kernel;        // explicit managed heap owner
void inspect(ref Kernel kernel);       // shared safe borrow
void update(mut ref Kernel kernel);    // exclusive mutable borrow
void consume(Kernel kernel);           // value move/copy by type rule
```

`Ref<T>` remains the checked runtime reference/view value used when a reference
must be stored in a local variable or produced by an API. The `ref T` and
`mut ref T` forms describe function/declaration borrowing directly and make the
generated calling convention visible at the source level.

Code using the older model migrates as follows:

```text
T owner = new T;        -> Box<T> owner = new T;
void f(T implicit_ref); -> void f(mut ref T explicit_ref);
```
