---
paths:
  - "src/**/*.cs"
---
# Architecture Rules (DDD + Clean Architecture)

These rules govern backend implementation across `Domain`, `Application`, and `Infrastructure`
layers. Load this file before writing any handler, entity, repository, or EF Core configuration.

## 1. Layer Boundaries (Dependency Rule)

Dependencies flow inward only:

```
Presentation / API -> Application -> Domain
Infrastructure -> Application -> Domain
```

- **Domain** — entities, value objects, enums, repository interfaces, domain services. ZERO external dependencies (no EF Core, no MediatR, no AutoMapper).
- **Application** — CQRS handlers, Commands/Queries, Requests/Responses, AutoMapper profiles. Depends only on `Domain`.
- **Infrastructure** — EF Core (`AppDbContext`, configurations, migrations), repository implementations, external service clients. Implements `Domain` interfaces.
- **Presentation** — API endpoints, DI composition root, middleware, OpenAPI/Swagger config. If a UI project (e.g. Blazor) sits on top, it calls the API via facades — never MediatR or EF Core directly from UI code; see `.claude/rules/blazor.md` if the blazor template is installed.

STRICT: Never let `Domain` reference `Infrastructure` or `Application`. Never leak EF Core types out of `Infrastructure`.

## 2. CQRS — Commands & Queries

Enforce strict CQRS. **Commands mutate state. Queries only read.** Never mix.

Use the project's own CQRS abstractions (not a raw `IRequest`):

- Queries: `record GetXQuery(...) : IQuery<TResponse>;`
- Commands (no payload result): `record CreateXCommand(XRequest Request) : ICommand;`
- Commands (with result): `record CreateXCommand(...) : ICommand<TResult>;`
- Query handlers: `internal class GetXQueryHandler : IQueryHandler<GetXQuery, TResponse>`
- Command handlers: `internal class CreateXCommandHandler : ICommandHandler<CreateXCommand>`

Rules:
- Commands/Queries/Requests/Responses are ALWAYS `record` types.
- Handlers are ALWAYS `internal` and `sealed` where possible.
- Handlers MUST return `Result<T>` built via a result builder. Never throw for expected business failures.
- NEVER inject `IMediator` or `ISender` into a handler. Handlers are fully isolated.
- Handlers orchestrate; they do NOT contain complex algorithms. Delegate domain logic to entities or domain services.
- One handler per file, colocated with its Command/Query in a feature folder (`Feature/Action/`).
- Cross-cutting concerns (logging, exception handling, validation) go through pipeline behaviors, not repeated per-handler code.

## 3. Folder Structure (Vertical Slice per Feature)

Organize by feature, then by use case:

```
Application/<Feature>/Handlers/<UseCase>/<UseCase>Query.cs
Application/<Feature>/Handlers/<UseCase>/<UseCase>QueryHandler.cs
Application/<Feature>/Responses/<X>Response.cs
Application/<Feature>/Requests/<X>Request.cs
Application/<Feature>/Mapper/<Feature>Profile.cs
```

Mirror an existing sibling slice exactly when adding a new one.

## 4. Domain Entities

- Inherit from the project's `BaseEntity`.
- `private` parameterless constructor (for EF Core materialization).
- All setters are `private set;` — never expose public setters.
- Construct via `public static X Create(...)` factory methods. Mutate via explicit behavior methods (`Update(...)`, `Activate(...)`, etc.).
- Guard invariants inside factories/methods (`ArgumentException.ThrowIfNullOrEmpty(...)`).
- Keep validation constants in `Domain/<Feature>/Consts/<X>ValidationRules.cs`.

## 5. EF Core & Persistence

- `AppDbContext` lives in `Infrastructure/Database`. Register configs via `modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly)`.
- One `IEntityTypeConfiguration<TEntity>` per entity in `Infrastructure/<Feature>/Configurations/`. Configurations are `internal`.
- Use Fluent API exclusively — NO data annotations on domain entities.
- Always set: table name (`ToTable`), `IsRequired`, `HasMaxLength`, `HasPrecision` for decimals, explicit `OnDelete` behavior, and indexes (`HasIndex`).
- Query repositories use `IDbContextFactory<AppDbContext>` (short-lived contexts for reads). Write repositories + `IUnitOfWork` handle mutations and `SaveChangesAsync`.
- **Reads MUST use `AsNoTracking()`.** Project to DTOs/projections in the repository; never return tracked entities for read paths.
- Avoid N+1: use explicit `Include`/`ThenInclude` or projection. Never lazy-load.
- Paginate all list queries (`Skip`/`Take`).
- Use Dapper for complex read queries (reports, stored procedures, views) when EF projections get unwieldy. Keep Dapper queries in dedicated read services inside `Infrastructure`.

## 6. Async/Await Hygiene

- All I/O is `async Task` / `async Task<T>`. NEVER `async void` (except UI event handlers).
- **Propagate `CancellationToken`** through every async call in the chain — handler signature already provides it; pass it to repositories, EF Core (`ToListAsync(ct)`), and HTTP calls.
- NEVER block: no `.Result`, no `.Wait()`, no `.GetAwaiter().GetResult()`.
- Use `await` directly; avoid unnecessary `Task.Run` for already-async work.

## 7. Mapping

- **Application & Presentation:** inject and use `IMapper` (AutoMapper). Define `Profile` classes per feature. Never `new Dto { ... }` manually.
- **Shared/zero-dependency infrastructure libraries:** STRICTLY FORBIDDEN to inject `IMapper`. Use manual mapping via extension methods (`public static XDto ToDto(this XEntity e)`) or static factory methods. These libraries stay dependency-free.

## 8. Anti-Patterns (Reject on Sight)

- `IMediator`/`ISender` inside a handler.
- Public setters on domain entities.
- EF Core types or `DbContext` referenced from `Application`/`Domain`.
- Anonymous objects (`new { ... }`) for data transfer.
- Throwing exceptions for expected validation/business errors instead of `Result<T>`.
- Missing `CancellationToken` propagation.
- Tracked entities returned from read queries.
- Anemic entities (data bags with logic pushed into handlers instead).
- Raw string-concatenated SQL in EF `FromSqlRaw` or Dapper — always parameterize.

## 9. Design Checklist

- [ ] Dependency rule intact; no EF leakage outward
- [ ] Strict CQRS; thin handlers; `Result<T>` outcomes
- [ ] Records for contracts; `IMapper` in App/Presentation, manual mapping in zero-dep libs
- [ ] One consolidated query per view (no chatty UI)
- [ ] Slice mirrors existing structure

See `.claude/skills/ddd-strategic-design/SKILL.md` for aggregate/entity/value-object modeling
guidance and `.claude/rules/testing.md` for how these layers get tested.
