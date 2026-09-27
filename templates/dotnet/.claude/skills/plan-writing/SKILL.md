---
name: plan-writing
description: Writing concise, executable implementation plans for features and fixes. Use before multi-file or non-trivial changes.
---

# Plan Writing

How to turn a request into a small, ordered, executable plan.

## When to Plan
- Multi-file or multi-layer changes (Domain -> Application -> Infrastructure -> Presentation).
- Schema changes, new integrations, or anything with unclear scope.
- Skip for truly trivial edits (<=2 files, no schema/contract impact) — state the skip in one line.

## Format
```
# <Title>
## Steps
1. <verb> <target>
2. <verb> <target>
## Files
- path (new|modify) — purpose
```

## Step Rules
- Atomic: one verb + one target. No "and"/commas joining actions.
- Separate create vs modify vs test vs validate into distinct steps.
- Order by dependency: Domain first (entities/VOs/interfaces) -> Infrastructure (config/migration/repo) -> Application (handler/contract/mapper) -> Presentation (endpoint/component/ViewModel/validator) -> tests -> build.
- 5-12 steps for a feature; 3-5 for a small fix.

## Vertical Slice Template (standard feature)
1. Model/extend domain entity + invariants (`<App>.Domain`).
2. Add/extend repository interface (`<App>.Domain`).
3. Add EF `IEntityTypeConfiguration` + migration via `dotnet ef migrations add` (`<App>.Infrastructure`).
4. Implement repository (`<App>.Infrastructure`).
5. Define Command/Query + Request/Response records (`<App>.Application`).
6. Implement handler returning `Result<T>` (`<App>.Application`).
7. Add mapping profile (`<App>.Application`).
8. Add REST endpoint if needed (`<App>.Presentation`/`<App>.API`).
9. Build ViewModel + validator + thin component for the UI layer, if one exists.
10. Add unit/integration tests.
11. `dotnet build` + `dotnet test`; review.

## Tips
- Mirror an existing sibling slice; name things per conventions (`.claude/rules/code-style.md`).
- Call out the migration explicitly as its own step whenever schema changes.
- Note any external integration dependency and route it to the appropriate specialist.
- End every plan with a build/test/validate step.

See `.claude/rules/workflow.md` for how a plan hands off to implementation agents.
