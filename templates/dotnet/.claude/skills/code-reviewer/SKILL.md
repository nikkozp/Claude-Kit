---
name: code-reviewer
description: Structured code review against SOLID, Clean Architecture, EF Core performance, and async hygiene. Use when reviewing diffs or auditing a change.
---

# Code Reviewer

A repeatable review rubric for changes in this solution. Pairs with the `reviewer` agent.

## Severity
- **Critical** — must fix (breaks architecture/security/data, build/test fail, missing migration, SQL injection).
- **Important** — should fix (perf trap, SOLID violation, style contract break).
- **Nit** — optional polish.

## Checklist

### Architecture & SOLID
- [ ] Dependency rule intact; no EF Core/`DbContext` in Domain/Application.
- [ ] Strict CQRS; handlers thin; logic in domain. No `ISender`/`IMediator` in handlers.
- [ ] `Result<T>` + error code for expected failures (no exception-as-flow).
- [ ] SRP/DRY; no chatty UI (one consolidated query per view).

### EF Core / SQL Server / Dapper
- [ ] Reads `AsNoTracking` + projected + paginated.
- [ ] No N+1 (single round-trip; `Include`/projection).
- [ ] Indexes for new filter/FK/unique columns; `HasMaxLength`, `HasPrecision`, explicit `OnDelete`.
- [ ] Schema change -> matching migration + snapshot committed. No `dotnet ef database update` runs.
- [ ] Dapper queries parameterized; no string-concatenated SQL.

### Async
- [ ] `CancellationToken` threaded end-to-end; no blocking (`.Result`/`.Wait()`); no `async void` outside UI handlers.

### Style & Contracts
- [ ] Records for Commands/Queries/Requests/Responses; `ViewModel` suffix for UI types.
- [ ] Strict nullable (no `!` abuse); file-scoped namespaces; primary ctors where idiomatic.
- [ ] `IMapper` in App/Presentation; manual mapping in zero-dep libs. No anonymous objects; no tuples.

### UI (if a component framework like Blazor is in use)
- [ ] Thin components; no heavy LINQ in `@code`; subscriptions disposed; `InvokeAsync(StateHasChanged)`.

### Security
- [ ] Server-side role enforcement; no secrets in code/logs; EF parameterization; Dapper parameterized; input validated; no path traversal in file handling.

## Output Format
```
## Review — APPROVED | CHANGES REQUESTED
### Critical / Important / Nits
- <file:line> — <rule> — <why + fix>
### Checks: build · tests · migration
```

## Principle
Cite file + line and the exact rule. Be specific and actionable; review the diff, not the whole repo.
