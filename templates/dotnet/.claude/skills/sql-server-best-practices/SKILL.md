---
name: sql-server-best-practices
description: SQL Server conventions via EF Core Fluent API, Dapper, and migrations. Use when designing schema, configurations, or migrations.
paths:
  - "src/**/Infrastructure/**/*.cs"
  - "**/*.sql"
---

# SQL Server Best Practices (via EF Core + Dapper)

The database is **Microsoft SQL Server**, code-first, schema defined only through Fluent API
(`IEntityTypeConfiguration<T>`). Migrations apply on app startup. Dapper is used for complex reads.

## Types & Columns
- Strings: `HasMaxLength(...)` always; `IsUnicode(true)` for human text (names, addresses), `IsUnicode(false)` for ASCII tokens (codes, keys). Avoid `nvarchar(max)`.
- Money/amounts: `decimal` with `HasPrecision(18, 2)`. NEVER `float`/`double`.
- Dates: store UTC (`DateTime.UtcNow`); be explicit and consistent.
- Enums: stored as `int`; keep enum values stable — don't reorder or renumber.

## Keys, Relationships, Cascades
- `BaseEntity` provides the identity. Configure FKs explicitly with `HasOne/WithMany/HasForeignKey`.
- **Set `OnDelete` explicitly.** SQL Server rejects multiple cascade paths to the same table — use `Restrict`/`NoAction`/`SetNull` to break cycles.
- Avoid accidental cascade deletes on business-critical data; prefer `Restrict`.

## Indexes
- `HasIndex(...)` for filters, joins, FKs; `.IsUnique()` for natural keys.
- Composite indexes ordered by selectivity; add covering `IncludeProperties` for hot reads.
- Name nothing manually unless needed — let EF generate; add explicit names only for clarity in big tables.

## Configurations & Migrations
- One `internal IEntityTypeConfiguration<T>` per entity in `Infrastructure/<Feature>/Configurations/`; registered via `ApplyConfigurationsFromAssembly`.
- `ToTable("...")` explicitly (default schema `dbo`).
- Workflow: change config -> scaffold migration with `dotnet ef migrations add` -> read `Up`/`Down` -> commit `.cs` + `.Designer.cs` + snapshot together. Never edit applied migrations. (See `.claude/rules/migrations.md`.)
- **NEVER run `dotnet ef database update`** — migrations apply on app startup.

## Dapper (complex reads)
- All Dapper queries must be parameterized (`new { Id = id }`) — never string concatenation.
- Complex SQL lives in embedded `.sql` files or stored procedures, not inline strings.
- Use `QueryAsync<T>` with typed DTOs. Avoid `dynamic` results.

## Performance & Safety
- Reads: `AsNoTracking` + projection + pagination; push filtering/aggregation to SQL.
- Wrap multi-statement mutations in the `IUnitOfWork`/`SaveChangesAsync` boundary for atomicity.
- Keep connection strings in config/env (`Database__ConnectionString`), never in code.

## Checklist
- [ ] Lengths/precision/unicode set; money is `decimal`
- [ ] Explicit `OnDelete`, no multiple cascade paths
- [ ] Indexes for filters/joins/FKs/uniqueness
- [ ] Migration scaffolded, reviewed, snapshot committed
- [ ] Dapper queries parameterized

See `.claude/skills/database-optimizer/SKILL.md` for query performance and `.claude/rules/migrations.md` for the full migration workflow.
