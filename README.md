# Claude-Kit

A personal Claude Code starter kit. It holds global settings, skills, subagents, hooks and scripts,
plus project templates with a reusable library of agents, rules and skills for .NET and Blazor.

The kit serves two jobs:
- **New machine:** clone the repo, run one script, and the familiar environment is back in a minute.
- **New project:** copy a template in, and the project starts with a ready `.claude/` setup.

Current version: see [`VERSION`](VERSION). History: [`CHANGELOG.md`](CHANGELOG.md).

> This repository is public. Never commit tokens, passwords, connection strings or internal
> hostnames. If you start adding company-internal conventions, make the repository private first.

## Structure

```text
Claude-Kit/
├── install.ps1 / install.sh   links ~/.claude to home/ (Windows / macOS, Linux, WSL)
├── new-project.ps1            copies one or more templates into a project repo
├── mcp.ps1                    user-scope MCP servers (no secrets)
├── VERSION, CHANGELOG.md      versioning
├── home/                      everything that lives in ~/.claude
│   ├── settings.json          global config (Windows)
│   ├── CLAUDE.md              global rules: accuracy, comments, compaction
│   ├── skills/                ship, babysit, commit-push-pr, techdebt, grill,
│   │                          decomment, wrap-up, skill-map, post-merge-sweeper,
│   │                          pr-pruner, fix-workitem, triage-feedback, test-and-fix,
│   │                          flaky, review-pr, weekly-sync
│   ├── agents/                security-reviewer
│   ├── hooks/                 guard-secrets.ps1, git-guard.ps1, comment-guard.ps1 (optional)
│   └── scripts/               skill-map.ps1
└── templates/
    ├── dotnet/                .claude/ (settings, hooks, agents, rules, skills) + CLAUDE.md
    ├── blazor/                add-on for Blazor UI: agents, rule, skills
    ├── sdlc/                  intent.md, spec.md, plan.md templates and review.md
    └── knowledge/             raw/ + wiki/ knowledge base skeleton
```

`home/` is **linked** to `~/.claude`, so every change made there shows up in `git diff` right away.
`templates/` is **copied** into a project. After that, the copy belongs to the project repo and its team.

## Install on a new machine (Windows)

1. Install Claude Code, Git for Windows, Node.js and the Azure CLI.
2. Turn on Developer Mode (*Settings > For developers*). File symlinks need it.
   Without it, run `install.ps1 -Copy`.
3. Clone and install:
   ```powershell
   git clone https://github.com/nikkozp/Claude-Kit.git $HOME\src\Claude-Kit
   cd $HOME\src\Claude-Kit
   .\install.ps1
   ```
4. Restart the terminal and run `claude doctor`.
5. In Claude Code, open `/plugin` and check the plugins listed below.
6. If you need MCP servers, edit `mcp.ps1` and run it.

The script backs up existing files as `*.bak-<timestamp>`, so it is safe to run again.
On macOS, Linux or WSL, use `install.sh` instead. The hooks in `home/settings.json` call
`powershell.exe`, so adjust them there.

## Plugins

Global plugins, already set in `home/settings.json`:

```text
/plugin install superpowers@claude-plugins-official
/plugin install context7@claude-plugins-official
/plugin install github@claude-plugins-official
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud@claude-hud
```

The `dotnet` template turns on these project plugins: `csharp-lsp`, `security-guidance` and
`pr-review-toolkit`. `csharp-lsp` needs its binary: `dotnet tool install --global csharp-ls`.

## New project

```powershell
cd C:\src\MyRepo
& $HOME\src\Claude-Kit\new-project.ps1 -Template dotnet                 # backend
& $HOME\src\Claude-Kit\new-project.ps1 -Template dotnet,blazor          # Blazor app
& $HOME\src\Claude-Kit\new-project.ps1 -Template dotnet,sdlc,knowledge  # add SDLC docs and a wiki
```

Existing files are never overwritten unless you pass `-Force`. After copying:
1. Fill in `CLAUDE.md` with the stack, commands and gotchas.
2. Replace the `<App>` placeholders in `.claude/rules` and `.claude/skills` with the solution prefix.
3. Delete what the project does not need, then commit.

## Library catalogue

### `templates/dotnet`

| Kind | Name | Purpose |
|---|---|---|
| rule | `architecture` | Layering, dependency direction, vertical slices, handlers |
| rule | `code-style` | C# style and a strict comment policy |
| rule | `docker` | Dockerfile and compose conventions, local commands |
| rule | `git-operations` | Branch-from-pulled-main flow, Conventional Commits; push feature branches only, never force |
| rule | `migrations` | EF Core migrations; Claude never runs `database update` |
| rule | `testing` | xUnit conventions, naming, fixtures, what to test |
| rule | `validation-authorization` | Validators and policy-based authorization |
| rule | `workflow` | Routing between agents, model phases, quality gates |
| skill | `azure-pipelines` | CI/CD pipeline patterns |
| skill | `code-reviewer` | Review checklist for .NET changes |
| skill | `csharp-pro` | Modern C# idioms quick reference |
| skill | `database-optimizer` | Query and index tuning |
| skill | `ddd-strategic-design` | Bounded contexts and context maps |
| skill | `logging` | Structured logging with Serilog; secrets are never logged |
| skill | `plan-writing` | Vertical-slice implementation plan template |
| skill | `sql-server-best-practices` | SQL Server schema and query rules |
| agent | `ba` | Requirements, user stories, acceptance criteria |
| agent | `dba` | Schema, migrations and query review |
| agent | `ddd-architect` | Domain model and aggregate design |
| agent | `debugger` | Root-cause analysis |
| agent | `developer` | Implements planned changes |
| agent | `devil` | Devil's advocate for designs and plans |
| agent | `devops` | Containers, pipelines, configuration |
| agent | `docs-writer` | Project documentation |
| agent | `integration-architect` | External APIs and integrations |
| agent | `qa` | Test scenarios and acceptance checks |
| agent | `refactoring-expert` | Safe, behavior-preserving refactoring |
| agent | `reviewer` | Code review against the rules |
| agent | `security-scanner` | Security review of changes |
| agent | `tester` | Writes and fixes automated tests |

### `templates/blazor` (install on top of `dotnet`)

| Kind | Name | Purpose |
|---|---|---|
| rule | `blazor` | Components, render modes, state, forms, JS interop |
| skill | `blazor-server-gotchas` | Circuit, prerendering and DbContext pitfalls |
| skill | `playwright-dotnet` | End-to-end UI tests with Playwright for .NET |
| skill | `uiux-design-system` | Design tokens, theming, spacing and typography |
| agent | `blazor-expert` | Blazor implementation specialist |
| agent | `uiux-designer` | UX and visual design review |
| agent | `radzen-expert` | Optional Radzen Blazor component specialist |

## Global commands (`home/skills`)

| Command | What it does |
|---|---|
| `/ship <workitem>` | Runs decomment, techdebt, grill, then commit-push-pr. Stops at the first problem |
| `/commit-push-pr <workitem>` | Commits, pushes and opens an Azure DevOps PR |
| `/babysit` | Looks after your PRs: review comments, merge from the target branch, CI. Run it in a separate `claude --worktree` session, looped with `/loop 10m /babysit` |
| `/grill` | Adversarial review of the branch in a forked context |
| `/techdebt` | Finds duplication, dead code and debug leftovers |
| `/decomment` | Removes low-value comments from the diff |
| `/wrap-up` | Summarizes the session and proposes CLAUDE.md changes |
| `/skill-map` | Draws a Mermaid map of skills and highlights broken links |
| `/post-merge-sweeper` | Collects review comments on your PRs merged in the last 7 days and fixes them in one follow-up PR |
| `/pr-pruner` | Abandons your drafts idle for 30+ days and reports PRs idle for 14+ days |
| `/fix-workitem <id>` | Takes an Azure Boards work item from acceptance criteria to tests, fix and a draft PR |
| `/triage-feedback` | Turns work items tagged `claude-ready` into draft PRs, at most 2 per run |
| `/test-and-fix [filter]` | Runs the tests and fixes failures at the root cause, at most 3 iterations |
| `/flaky <filter> [runs]` | Reruns a flaky test, finds the nondeterminism and fixes it without retries |
| `/review-pr <id>` | Reviews a teammate's PR against `REVIEW.md` without posting anything |
| `/weekly-sync` | Briefs your last 7 days: commits, PRs, work items and risks |

`decomment`, `techdebt` and `grill` deliberately have no `disable-model-invocation`, so `/ship`
can invoke them. `commit-push-pr` stays manual-only, so `/ship` reads its file instead.
The same applies to `fix-workitem`, which `/triage-feedback` reads. Every command that pushes,
opens or closes a PR, or edits a work item is manual-only.

## Loops

Run each loop in its own session with its own worktree (`claude --worktree`), so the agent never
switches branches in your working copy.

| Session | Command | What it does |
|---|---|---|
| babysitter | `/loop 10m /babysit` | Review comments, merge from the target branch and CI for your PRs |
| feedback | `/loop 30m /triage-feedback` | Work items tagged `claude-ready` become draft PRs |
| sweeper | `/loop 2h /post-merge-sweeper` | Comments left after merge become a follow-up PR |
| pruner | `/loop 6h /pr-pruner` | Abandons stale drafts, reports the rest |
| reviewer | `/loop 20m /review-pr <id>` | Watches a teammate's PR and reviews new commits |

For sessions that push, add this to the project's `.claude/settings.local.json`:

```json
{ "permissions": {
    "allow": ["Bash(git push -u origin HEAD)"],
    "deny":  ["Bash(git push * main)", "Bash(git push * master)"] } }
```

Force pushes are not allowed in loops either: `git-guard.ps1` blocks them, and `babysit` catches
up with a merge instead of a rebase.

Every command has a per-run limit and a stop condition. Stop a loop with `Esc` or by closing the
session. To keep a loop running after the terminal closes, move it to `/schedule` or a routine.
Run each command by hand for a week before you put it in a loop.

## Global hooks

Enabled in `home/settings.json`:

- `guard-secrets.ps1` blocks reads of secret files and secret-dumping shell commands.
- `git-guard.ps1` enforces the git branch policy on every `Bash`/`PowerShell` call:

| Blocked | Why |
|---|---|
| Push to `main`, `master`, `origin/HEAD` or `CLAUDE_GIT_PROTECTED` (also `HEAD:main`, `--all`, `--mirror`) | Protected branches change only via PR |
| Plain `git push` from a branch whose upstream is a protected branch | It would land on main |
| `push -f`, `--force-with-lease`, `+refspec`, `switch -C`, `checkout -B`, `branch -f`, `branch -M` | No force of any kind |
| New or renamed branch not named `<feature\|fix\|chore>/<task>_<short-description>` | One naming scheme, every branch linked to a task |
| New branch not from the local main, from `origin/<x>`, or with `--track` | The upstream must never be `origin/main` |
| New branch while local main differs from `origin/main` (checked with `git fetch`) | Branch only after a pull |
| `branch -u` / `--set-upstream-to` a protected branch | Same reason |

Expected flow: `git switch main`, then `git pull --ff-only` as a separate command, then
`git switch -c feature/<task>_<short-description>` and `git push -u origin HEAD`. The hook checks
the repo state *before* a command runs, so `switch main && pull && switch -c x` in one call is blocked.

Branch names: `<task>` is the Azure DevOps work item id (`12345`), a Jira key (`ABC-123`) or
`NO-TASK`; the description is lower-case kebab-case. Examples: `feature/12345_order-export`,
`fix/ABC-123_null-customer-name`, `chore/NO-TASK_bump-deps`. A project with a different scheme can
set a regex in the `CLAUDE_GIT_BRANCH_PATTERN` environment variable.
Extra protected branches (e.g. `develop,staging`) go in the `CLAUDE_GIT_PROTECTED` environment
variable, comma-separated. The hook is a guard rail for Claude, not a replacement for server-side
branch policies.

## Optional hooks

`home/hooks/comment-guard.ps1` rejects diffs whose comments narrate the code.
To enable it, add this to the `hooks` block in `home/settings.json`:

```json
"Stop": [{
  "hooks": [{
    "type": "command",
    "command": "powershell.exe",
    "args": ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command",
             "& \"$env:USERPROFILE\\.claude\\hooks\\comment-guard.ps1\"; exit $LASTEXITCODE"],
    "timeout": 30
  }]
}]
```

## What must never be here

- `~/.claude.json`: login session, trust decisions, MCP servers with their env.
- Claude Code credential files.
- `~/.claude/projects/`: session transcripts and auto-memory, which are local to each machine.
- `~/.claude/plugins/cache/`: the plugin cache.
- Any token, password or connection string.

## Script rules

Keep every `.ps1` ASCII-only. Windows PowerShell 5.1 reads BOM-less files as ANSI, and non-ASCII
characters break the parser. `.gitattributes` pins line endings: LF for `.sh` and CRLF for `.ps1`.

## Updating

When you change a skill or a setting (including through `/config`), the change lands in the repo
at once. Review it with `git diff`, then commit. On another machine, run `git pull`.

## Releasing

1. Add each change under `## [Unreleased]` in `CHANGELOG.md` as you go.
2. To release, pick the next version by the SemVer rules at the top of the changelog.
   Update `VERSION`, and rename `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD` with a new empty
   `[Unreleased]` above it.
3. Commit with `chore: release vX.Y.Z` and tag it with `git tag vX.Y.Z`.
4. Push the commit and the tag: `git push && git push --tags`.
