---
name: database-optimizer
description: EF Core + Dapper + SQL Server query and schema optimization — N+1 elimination, indexing, projections, tracking. Use when diagnosing slow queries or designing read paths.
paths:
  - "src/**/Infrastructure/**/*.cs"
---

# Database Optimizer (EF Core + Dapper + SQL Server)

Make data access fast and correct without leaking EF outside Infrastructure.

## Read-Path Rules
- **Always `AsNoTracking()`** for reads. Tracking is for writes only.
- **Project early** to `Response`/projection records (`Select(...)`) — fetch only needed columns, not whole entities.
- **Paginate** every list (`OrderBy(...).Skip(...).Take(...)`). No unbounded `ToListAsync`.
- **Pass `CancellationToken`** to `ToListAsync(ct)`, `FirstOrDefaultAsync(ct)`, etc.
- **Dapper** is used for complex reads (reports, stored procedures, views). Always parameterize — no string concatenation in queries.

## Killing N+1
- Symptom: a query inside a loop, or lazy navigation access per item.
- Fix: a single query with `Include`/`ThenInclude`, or (better for reads) a projection that joins in `Select`.
- Verify the generated SQL is one round-trip; avoid client-side evaluation (no untranslatable method calls in the query).

## Indexing (SQL Server)
- Index every column used in `WHERE`, `JOIN`, `ORDER BY`, FK, and uniqueness (`HasIndex(...).IsUnique()`).
- Composite index column order = most selective / equality first, range last.
- Consider covering indexes (`.IncludeProperties(...)`) for hot read paths (dashboards, list views, reports).
- Don't over-index write-heavy tables; each index costs on insert/update.

## Schema Hygiene
- `HasMaxLength` on strings (avoid `nvarchar(max)` unless needed); `IsUnicode(false)` for ASCII-only.
- `HasPrecision(18,2)` for money; never `float/double` for financial values.
- Explicit `OnDelete` — avoid SQL Server multiple-cascade-path errors (`Restrict`/`NoAction`/`SetNull`).

## Diagnosis Workflow
1. Identify the LINQ/Dapper query producing slow SQL; log/inspect the generated query.
2. Check tracking, projection, includes, and pagination.
3. Inspect the execution plan for scans on filtered/joined columns -> add/adjust index.
4. Re-measure. Confirm one round-trip and index seeks.

## Checklist
- [ ] Reads `AsNoTracking` + projected + paginated
- [ ] No N+1 (single round-trip)
- [ ] Indexes cover filters/joins/FKs/uniqueness
- [ ] Money uses `decimal` + precision; strings bounded
- [ ] Dapper queries parameterized, not string-concatenated

See `.claude/skills/sql-server-best-practices/SKILL.md` for schema/migration conventions and `.claude/rules/migrations.md` for the migration workflow.
