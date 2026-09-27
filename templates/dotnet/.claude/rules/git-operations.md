# Git Operations Rules

Adjust the remote/CI specifics below to your repo. This file assumes a hosted Git repo with a
CI pipeline; swap in your actual host and pipeline tool where noted.

## Branching
- Long-lived: `main`/`master` (production), `staging` or `develop` (integration) if your repo uses one.
- Work branches: `feature/<slug>`, `fix/<slug>`, `chore/<slug>`. Branch off the integration branch unless told otherwise.

## Commits — Conventional Commits
Format: `<type>(<scope>): <subject>`
- Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `build`, `ci`.
- Scope = feature/layer, e.g. `orders`, `auth`, `application`, `domain`, `infra`, `migrations`, `ci`.
- Subject: imperative, lower-case, no trailing period. English only.
- Examples:
  - `feat(orders): add order details query`
  - `fix(auth): propagate cancellation token in refresh flow`
  - `chore(migrations): add Order status index`

## Safety

**FORBIDDEN — never do these:**
- `git push` — Claude must NOT push to any branch.
- `git push --force` or `--force-with-lease` to any branch.
- Committing secrets (connection strings, API keys, license keys).

**Allowed:**
- `git commit` — permitted when the user asks for it in the current message. Always review the staged diff first and use the Conventional Commit format above. Never commit unprompted.
- Read-only: `git status`, `git diff [--staged]`, `git log --oneline -n 20`, `git branch`, `git fetch`.
- Stage review: always `git diff` before committing. Don't blindly `git add -A`.

## Pull Requests
- Target the integration branch (or as directed). Title mirrors the Conventional Commit subject.
- PR description: **What / Why / How tested**. Link the work item/issue if your tracker supports it.
- Required before requesting review: build clean, tests green, migration present if schema changed.

## CLI Notes
- Auth is via the configured Git credential manager; do not embed tokens/PATs in commands.
- Common read-only: `git status`, `git diff [--staged]`, `git log --oneline -n 20`, `git branch`.
