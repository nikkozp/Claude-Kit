# Workflow Rules — Agent Pipeline Orchestration

How work flows through the agent team. Route each task to the right specialist instead of doing
everything inline. Each agent's model is fixed in its own frontmatter (`model:` field) — see
`.claude/agents/*.md`; there's no global plan/execute model switch to configure here.

## Pipelines

```
Standard feature:  Planning -> developer [/ blazor-expert] -> Quality Gate -> docs-writer
Bug fix:           debugger -> developer [/ blazor-expert] -> Verify (tester + reviewer)
Schema change:     ddd-architect -> dba -> developer -> reviewer (migration check)
Integration work:  integration-architect -> developer -> reviewer + security-scanner
CI/CD / infra:     devops -> reviewer
```

`blazor-expert` (and the UI agents below) only apply if the Blazor template is installed on top
of this one.

## Phases

1. **Plan (Opus-tier reasoning).** Clarify scope. For features with real domain/architecture
   decisions, involve `ba` (requirements/user stories), `ddd-architect` (modeling, logic
   placement), and `devil` (read-only challenger). Simple features: `ba` alone or skip straight
   to implementation.
2. **Implement (Sonnet-tier).** `developer` owns Domain/Application/Infrastructure.
   `blazor-expert` owns Presentation/UI layers if the Blazor template is installed. They hand
   off to each other via SendMessage (e.g., UI needs a new consolidated query -> `developer`).
3. **Quality Gate.** Run in parallel where possible: `tester` (unit/integration/component
   tests), `reviewer` (SOLID, EF traps, migration sync), `security-scanner` (auth/secrets/OWASP),
   `qa` (end-to-end flows when applicable). Any Critical/Important finding routes back to the
   implementer; then re-run the gate.
4. **Docs.** `docs-writer` updates README/CLAUDE.md/feature docs when public behavior or setup
   changed.

## Routing Table

| Need | Agent |
| --- | --- |
| Requirements, user stories, acceptance criteria | `ba` |
| Domain modeling, where business logic belongs | `ddd-architect` |
| Challenge the plan before code | `devil` |
| Backend C# (handlers, entities, EF, migrations) | `developer` |
| UI components, ViewModels, front-end views | `blazor-expert` (if the blazor template is installed) |
| Schema design, query/index optimization | `dba` |
| Bug root-cause analysis | `debugger` |
| Unit/integration/component tests | `tester` |
| End-to-end / UI flows | `qa` |
| Code review, architecture audit | `reviewer` |
| Auth, secrets, OWASP, CVE | `security-scanner` |
| External API integrations | `integration-architect` |
| Refactoring, N+1 fixes, code smells | `refactoring-expert` |
| Docker, CI/CD, deployment | `devops` |
| Docs, README, API notes | `docs-writer` |
| UI/UX review, layout, accessibility | `uiux-designer` (if the blazor template is installed) |
| Component-library-specific UI questions | `radzen-expert` (if the blazor template is installed) |

## Principles

- One responsibility per agent; don't let an agent act outside its scope — delegate.
- Always end an implementation task with a build + relevant tests before handing to the gate.
- Read-only agents (`ba`, `ddd-architect`, `devil`, `reviewer`, `security-scanner`) never edit
  code; they report and route.
- Version control follows `.claude/rules/git-operations.md`: `git commit` is allowed only when
  the user explicitly asks for it in the current message (always review the staged diff first);
  `git push` is forbidden with no exception.
