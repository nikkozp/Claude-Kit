---
name: ddd-strategic-design
description: Domain-Driven Design — aggregates, entities, value objects, bounded contexts, and logic placement. Use when modeling domain or deciding where business logic belongs.
---

# DDD Strategic & Tactical Design

Guidance for modeling the domain inside Clean Architecture.

## Bounded Contexts (example shape)
Example contexts you might see in a solution: **Ordering** (carts, checkout, order lifecycle),
**Catalog** (products, categories, pricing), **Billing** (invoices, payments, refunds), **Identity**
(users, auth, roles). Replace with the actual contexts of your domain. Keep concepts from
different contexts from bleeding into each other.

## Tactical Patterns
- **Entity**: identity + lifecycle. `: BaseEntity`, private ctor, `private set;`, `static Create(...)` factory, behavior methods guarding invariants. No public setters.
- **Aggregate root**: the only entry point to its cluster; owns child entities and enforces consistency boundaries (e.g., `Order` -> `OrderLine`; a `Catalog` -> its `Product` variants). Reference other aggregates by id, not navigation, across boundaries.
- **Value object**: immutable, equality-by-value, no identity — model status types, money/precision, and typed identifiers as VOs instead of loose primitives.
- **Domain service**: logic that doesn't belong to a single entity (e.g., cross-order duplicate detection, pricing policy evaluation).
- **Domain events**: side effects that cross aggregate boundaries (e.g., `OrderPlacedDomainEvent`, `PaymentFailedDomainEvent`).
- **Repository**: interface in Domain, implementation in Infrastructure. Split read (query repo + projections) from write (write repo + `IUnitOfWork`).

## Logic Placement (the core question)
- Business rules -> entities/value objects/domain services.
- Orchestration (load -> call domain -> persist) -> Application handlers (thin).
- Mapping/shaping for UI -> Application (`IMapper`) -> ViewModels.
- I/O, EF, Dapper, HTTP -> Infrastructure.
If a handler contains an algorithm or branching business rule, it belongs in the domain.

## Invariants
- Enforce at construction and on every state change. The domain must not trust the UI.
- Keep validation limits in Domain `Consts` (single source for validator + EF config).

## Anti-Patterns
- Anemic entities (data bags + logic in handlers).
- EF Core / MediatR / AutoMapper types inside Domain.
- Cross-aggregate navigation that creates huge object graphs.
- Primitive obsession instead of value objects.

See `.claude/rules/architecture.md` for the layering rules this skill's placement guidance enforces.
