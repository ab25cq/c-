# C- safe-mode contract

C- safe mode is designed so that accepted safe C- code does not intentionally
emit an unchecked memory access. Operations whose validity depends on runtime
state must either perform a checked operation or panic before accessing memory.

This contract assumes a correct C- compiler and runtime, a conforming target C
compiler, and functioning hardware. Code inside `unsafe`, inline C/assembly,
foreign implementations, and target-specific runtime replacements form the
trusted computing base and must uphold the invariants described below.

## Enforced invariants

- Raw pointer declaration, arithmetic, casts, dereference, allocation, and
  deallocation are unavailable in safe code.
- Fixed-array indexing requires an in-range constant. Dynamic indexing uses a
  checked collection or view.
- `Ref`, `Span`, `FixedVec`, `RingBuffer`, `Bitmap`, and reference-bearing
  `Optional` values validate bounds and tracked lifetimes before access.
- Managed heap references carry an allocation generation. Free/reuse cannot
  make an old managed `Ref` valid again merely because its address is reused.
- Known stack escapes, owner moves/reassignments, aliases, double frees, and
  copies of finalizer-owning values are rejected.
- `Thread`, `Mutex`, `Cond`, and `Critical` cannot be copied or passed by value.
- Integer/allocation overflow, invalid atomic orders, null string operations,
  excessive tracked stack growth, and invalid managed frees panic.
- Explicit `extern` declarations and foreign/raw interfaces belong in
  `unsafe`; safe wrappers must validate their inputs and outputs.

## Trusted boundary

An `unsafe` block is a proof obligation, not a suppression of runtime faults.
It must not return a forged safe reference, an invalid length, an unowned value
presented as owned, or a value whose lifetime is shorter than its safe wrapper.
Foreign code must also obey C- ownership and thread-safety rules.

The compiler and runtime may still contain bugs. Stack exhaustion below the
configured reserve, asynchronous hardware faults, corrupted process state, and
bugs in the target C compiler or operating system cannot be converted reliably
to a language panic. Consequently the guarantee is intentionally phrased like
Rust's: memory safety is provided by the safe language subset, while unsafe and
foreign code are responsible for preserving its invariants.

## Concurrency status

The managed allocator and thread-handle lifetime operations are synchronized,
and invalid memory-order combinations panic. `Atomic<T>` and `Mutex`/`Cond`
are the supported synchronization primitives. A `Thread.spawn` entry and its
transitive user-function calls cannot access ordinary globals in safe mode;
only `Atomic<T>`, `Mutex`, `Cond`, and compile-time constants cross that global
boundary. Indirect calls and calls without a visible safe definition are also
rejected from a thread entry.

The `Sync` check is structural at the atomic boundary: safe `Atomic<T>` permits
only non-pointer integer, enum, and bitflags payloads. References, raw or owned
pointers, floating-point values, structs, and runtime resources are rejected.
`Mutex` and `Cond` are synchronization resources, but their mere presence does
not mark adjacent ordinary global storage as protected.

The `Send` surface supports transferring one or more exclusive values with
`Thread.spawn(move first, move second, worker)`. Captures may be managed owners,
scalars, or stack value structs, including structs with owned fields. The worker
must be a visible safe function returning `int` and accepting matching owned
parameters in the same order.
`Ref`, `Span`, raw/non-owning pointers, runtime resources, and structs storing
those values are rejected. The source becomes unusable immediately after the
move, and the worker owns cleanup of the value. `Send` is checked recursively
through user-struct fields and owned pointees; recursive owning types such as
`Box<Node>` are supported without weakening the check.

The same transfer rule applies to ordinary function calls: an `owned`
parameter requires `move local` or a fresh owned rvalue such as `new`, `clone`,
an owned return value, or an `s"..."` string. This prevents by-value owning
struct parameters from silently duplicating their finalizers.

This is intentionally narrower than a full Rust-style structural `Send`/`Sync`
proof. User-defined synchronization containers and shared references are not
yet part of the safe thread surface.
