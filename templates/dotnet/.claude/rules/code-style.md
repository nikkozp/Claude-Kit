# Code Style Rules (C#)

Modern C# conventions. Target framework: see `Directory.Build.props` / the relevant `*.csproj`. Prioritize the language features available on that target; do not use APIs newer than the target framework, especially in shared/legacy libraries that pin an older one.

## 1. Nullable & Language Features

- **Nullable reference types are enabled and strict.** Never suppress with `!` to silence warnings — fix the actual nullability. The `!` (null-forgiving) operator is allowed ONLY for DI-injected members initialized as `= default!;`.
- **File-scoped namespaces** for all new files (`namespace <App>.Application.Orders;`). Match the surrounding file when editing legacy block-scoped namespaces.
- **Global usings** — rely on the project's `GlobalUsings`. Do not re-import already-global namespaces.
- **Primary constructors** for services, handlers, and DI-heavy classes where the file has no other constructor logic:
  ```csharp
  internal sealed class GetOrderByIdQueryHandler(IMapper mapper, IOrderRepository repository)
      : IQueryHandler<GetOrderByIdQuery, OrderItemResponse>
  ```
  Keep existing fields-and-ctor style when editing files that already use it — consistency within a file wins.
- Use the latest language features your target framework supports: pattern matching, switch expressions, collection expressions (`[]`, `[.. items]`), `is null` / `is not null` (never `== null`), target-typed `new`, `required` members.

## 2. Records for Data Contracts

Use `record` (or `record struct` for small value types) for:
- MediatR Commands & Queries.
- Requests and Responses.
- Projections and read DTOs.

Records are immutable by default — use positional syntax for simple contracts:
```csharp
public record GetOrderByIdQuery(long OrderId) : IQuery<OrderItemResponse>;
public record CreateOrderCommand(CreateOrderRequest Request) : ICommand;
```

## 3. Naming Conventions

- Classes/records that shape data for the UI: suffix `ViewModel` (e.g., `OrderGroupViewModel`) — NOT `Model`.
- MediatR query results: `[QueryName]Response` or `[QueryName]Result`.
- Requests: `[Action]Request`. Commands: `[Action]Command`. Queries: `[Action]Query`. Handlers: `[Action]CommandHandler` / `[Action]QueryHandler`.
- Private fields: `_camelCase`. Constants: `PascalCase` or domain style `Name_Max`.
- Interfaces: `I` prefix. Async methods: `Async` suffix.

## 4. Members & Access

- Handlers, EF configurations, and infrastructure internals: `internal` (and `sealed` where not inherited).
- Injected dependencies are `private readonly` fields (or primary-ctor params) — NOT internal/public properties. This applies to sub-collaborators too.
- Prefer expression-bodied members for one-liners.

## 5. Control Flow

- **Avoid tuples** for return values and `out` parameters. Prefer a dedicated `record`/method, or an optimistic-locking pattern for simple flows.
- Use guard clauses / early returns over nested `if`.
- Use switch expressions over long `if/else` ladders.

## 6. Formatting

- 4-space indentation, Allman braces (matching existing files).
- One type per file (records grouping tightly-related contracts are acceptable when already used in the codebase).
- Order usings: System -> third-party -> project. Let the global usings cover the common ones.
- All code, comments, identifiers, and commit messages in **English**.

## 7. Comments

- **Interfaces only.** XML-doc comments (`/// <summary>`) belong on interface members. Implementations inherit them automatically — never duplicate on the concrete class.
- **Non-obvious only.** Omit a comment if the method name + types already tell the story. Write one only for hidden constraints, subtle invariants, or workarounds for specific bugs.
- **Max 2 lines.** A comment longer than the code it annotates is a smell. A 50-char record does not need a 150-char description — trim or remove it.
- **No narration.** Do NOT explain what the code does ("iterates the list and returns…"). Self-documenting names over narration.

## 8. Logging & Exceptions

- Use `ILogger<T>` via DI. No `Console.WriteLine`.
- Handle expected failures with `Result<T>` + an error-code enum, not exceptions. Reserve exceptions for truly exceptional/invariant violations.
- See `.claude/skills/logging/SKILL.md` for structured logging conventions.
