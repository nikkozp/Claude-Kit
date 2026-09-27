# <Project name>
<One line: stack, e.g. .NET 9, ASP.NET Core Minimal API, EF Core 9 (PostgreSQL), xUnit.>

## Commands
- Build: `dotnet build -warnaserror`
- Tests: `dotnet test --filter "FullyQualifiedName~<Class>"` (full suite only before a PR)
- Format: `dotnet format --verify-no-changes`

## Gotchas
- <Only things Claude cannot infer from the code. Delete this line.>

## Where things are
- <Key folders and conventions that differ from defaults.>

## Agents and rules
- Conventions live in `.claude/rules/` (path-scoped ones load only for matching files).
- On-demand expertise lives in `.claude/skills/`; subagents in `.claude/agents/`.
- Routing between agents and the quality gates: `.claude/rules/workflow.md`.
- Replace `<App>` placeholders in rules and skills with this solution's prefix.

## Knowledge
- If `knowledge/wiki/index.md` exists, read the page for a module before changing it.

## Compact Instructions
Keep the task goal, changed files and schema decisions. Drop test output.
