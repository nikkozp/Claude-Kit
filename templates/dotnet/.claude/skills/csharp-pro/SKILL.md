---
name: csharp-pro
description: Modern C# expertise — language features, async, LINQ, performance. Use when writing or reviewing any C# code in this solution.
---

# C# Pro

Authoritative knowledge for idiomatic, modern C# in this codebase. Check `Directory.Build.props`
or the relevant `*.csproj` for the actual target framework/language version. Shared utility
libraries may target an older framework — do not use newer-only APIs in those projects.

## Language Features to Prefer
- **Records** for immutable contracts (Commands/Queries/Requests/Responses/DTOs/projections). Positional syntax for simple cases.
- **Primary constructors** for services/handlers with pure DI.
- **File-scoped namespaces**, **global usings**, **target-typed `new`**, **`required` members**, **`init` setters**.
- **Pattern matching** & **switch expressions** over `if/else` ladders; **`is null` / `is not null`** (never `== null`).
- **Collection expressions**: `[]`, `[.. items]`, spreads.
- **Nullable reference types** strict — fix nullability, don't `!`-suppress (except DI `= default!;`).

## Async
- `async Task`/`async Task<T>` only; no `async void` outside UI event handlers.
- Propagate `CancellationToken` through the whole chain; pass to EF (`ToListAsync(ct)`) and HTTP.
- Never block: no `.Result`, `.Wait()`, `.GetAwaiter().GetResult()`.
- `await foreach` / `IAsyncEnumerable<T>` for streaming; `ValueTask` only when measured.
- Don't `Task.Run` already-async work.

## LINQ & Collections
- Readable, translatable LINQ. For EF, ensure server-side translation (no client eval).
- Avoid multiple enumeration; materialize once. Prefer projection over fetching whole entities.
- Use `Span<T>`/`Memory<T>` only in hot paths with evidence.

## Error Handling
- Expected/business failures -> `Result<T>` + an error-code enum, not exceptions.
- Exceptions for invariant violations only; never swallow; log via `ILogger<T>` (no `Console.WriteLine`).

## Style
- Avoid tuples for returns/out-params — use a dedicated record/method.
- Injected deps are `private readonly` fields (or primary-ctor params), never public/internal properties.
- Expression-bodied members for one-liners. One type per file. English everywhere.

## Checklist
- [ ] Nullable honored, no `!` abuse
- [ ] CancellationToken threaded, no blocking
- [ ] Records for contracts, `ViewModel` suffix for UI types
- [ ] `Result<T>` for expected failures
- [ ] No tuples; readonly injected deps

See `.claude/rules/code-style.md` for the full style rulebook this skill summarizes for quick reference.
