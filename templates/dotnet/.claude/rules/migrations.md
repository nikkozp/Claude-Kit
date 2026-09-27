---
paths:
  - "**/Migrations/**"
  - "**/*DbContext*.cs"
---
# Migration Rules — EF Core / SQL Server

Database is **Microsoft SQL Server**. Migrations are code-first and are applied automatically at
startup — adjust the paths below to match your solution's actual project names.

## Project Layout
- DbContext: `src/<App>.Infrastructure/Database/AppDbContext.cs`
- Migrations project (`--project`): `src/<App>.Infrastructure`
- Startup project (`--startup-project`): `src/<App>.API`

## Commands

**IMPORTANT: Migrations may only be created via `dotnet ef migrations add`. Never apply migrations manually — the app applies them on startup.**

```bash
# Add a migration (the ONLY allowed migration operation)
dotnet ef migrations add <Name> \
  --project src/<App>.Infrastructure \
  --startup-project src/<App>.API

# Check for pending model changes (read-only check)
dotnet ef migrations has-pending-model-changes \
  --startup-project src/<App>.API

# List migrations (read-only)
dotnet ef migrations list \
  --startup-project src/<App>.API

# Remove the LAST (not-yet-applied) migration
dotnet ef migrations remove \
  --project src/<App>.Infrastructure \
  --startup-project src/<App>.API

# Generate SQL script (read-only, for review)
dotnet ef migrations script \
  --startup-project src/<App>.API
```

**FORBIDDEN:**
```bash
# DO NOT run — migrations apply automatically on app startup
dotnet ef database update ...
dotnet ef database drop ...
```

## Naming Convention
`Add_<Entity>_<Detail>`, `Update_<Entity>_<Field>`, `Remove_<Thing>`, `Rename_<Old>_<New>`, `Init`.
PascalCase segments joined by `_`. Examples: `Add_Order_Table`, `Update_Product_Status_Field`,
`Rename_Customer_Columns`.

## Rules
- **Every schema-affecting change to an entity or `IEntityTypeConfiguration` REQUIRES a new migration.** Never edit an already-applied migration.
- Schema is defined ONLY via Fluent API (`IEntityTypeConfiguration<T>`), never data annotations. Make the config change first, then scaffold the migration.
- After scaffolding, **read the generated `Up`/`Down`** — confirm intended columns, types, `nvarchar` lengths, `decimal(p,s)` precision, indexes, and FK `OnDelete` behavior. SQL Server cannot have multiple cascade paths — use `Restrict`/`NoAction`/`SetNull` to avoid cycles.
- Commit the migration `.cs`, its `.Designer.cs`, and the updated `AppDbContextModelSnapshot.cs` together. A change to the snapshot without a migration (or vice-versa) is a bug.
- Prefer additive, backward-compatible changes. For destructive changes (drop/rename column) ensure `Down` is correct and data loss is intentional and noted in the PR.
- Never run `dotnet ef database update` against production — production migrates on container/app startup via the app's own migration-apply step.
- Default schema is `dbo`. Tables are explicit via `ToTable("...")`.
