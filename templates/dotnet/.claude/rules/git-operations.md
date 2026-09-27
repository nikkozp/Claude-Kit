# Git Operations Rules

Adjust the remote/CI specifics below to your repo. This file assumes a hosted Git repo with a
CI pipeline; swap in your actual host and pipeline tool where noted.

## Branching
- Long-lived: `main`/`master` (production), `staging` or `develop` (integration) if your repo uses one.
  Nobody pushes to them directly; they change only through PRs.
- Work branches: `feature/<slug>`, `fix/<slug>`, `chore/<slug>`, always created from the freshly pulled main branch.

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

Commit, push, pull and fetch are allowed. The policy below is enforced by the global
`~/.claude/hooks/git-guard.ps1` PreToolUse hook; a blocked command returns `git policy: ...` with the fix.

**Mandatory flow for new work:**
1. `git switch main`, then `git pull --ff-only` — as a **separate** command (the hook checks the
   state before a command runs, so a chained `switch && pull && switch -c` is blocked).
2. `git switch -c feature/<slug>` — no start point, no `--track`. Never `git switch -c x origin/main`:
   a remote start point becomes the upstream, and a plain `git push` would then target main.
3. Commit in small Conventional Commits. First push: `git push -u origin HEAD`
   (upstream becomes `origin/feature/<slug>`).
4. To pick up new main: `git fetch origin`, then `git merge origin/main`, then a normal `git push`.

**FORBIDDEN (blocked by the hook):**
- Pushing to `main`, `master`, the remote default branch, or any branch in `CLAUDE_GIT_PROTECTED`
  (including `HEAD:main` refspecs, `--all`, `--mirror`).
- Any force: `push --force`/`-f`/`--force-with-lease`/`+refspec`, `switch -C`, `checkout -B`, `branch -f`.
- Creating a branch from anything but the pulled local main, or with `--track`.
- Setting a branch upstream to a protected branch; pushing a branch that tracks one.

**Also forbidden (not machine-checked):**
- Rebasing a pushed branch (it would need a force push).
- Committing secrets (connection strings, API keys, license keys).

**Before every commit:** review `git diff --staged`; stage explicit paths, not a blind `git add -A`.

## Pull Requests
- Target the main branch (or as directed). Title mirrors the Conventional Commit subject.
- PR description: **What / Why / How tested**. Link the work item/issue if your tracker supports it.
- Required before requesting review: build clean, tests green, migration present if schema changed.

## CLI Notes
- Auth is via the configured Git credential manager; do not embed tokens/PATs in commands.
- Common read-only: `git status`, `git diff [--staged]`, `git log --oneline -n 20`, `git branch`.
