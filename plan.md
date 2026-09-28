# Plan: AI-Native SDLC playbook in Claude-Kit

Status: **approved 2026-09-28** (decisions in section 6). Work branch: `feature/NO-TASK_sdlc-playbook`.

Sources read in full:
- The playbook: https://claude.com/blog/the-ai-native-sdlc-playbook
- The docs: https://code.claude.com/docs/en/hooks, `/skills`, `/sub-agents`, `/settings`, `/plugin-marketplaces`

## 1. What the repo already has (research summary)

| Playbook item | Already in the kit | Gap |
|---|---|---|
| intent / spec / plan templates | removed 2026-09-28 | superpowers owns design and planning; `/feature` wraps it (done) |
| REVIEW.md | `templates/sdlc/docs/sdlc/review.md` (flag / skip list, High/Med/Low) | no 3 passes, no Important vs Nit, no nit cap, no exclusions |
| One-page CLAUDE.md | `templates/dotnet/CLAUDE.md` | no "Verifying your work" or "Things Claude gets wrong" block |
| Format hook (C5) | `templates/dotnet/.claude/hooks/format-file.ps1` (PostToolUse, `dotnet format --include`) | resolves nothing from `cwd`; runs `dotnet format` without a workspace argument |
| Verify Stop hook (C6) | `templates/dotnet/.claude/hooks/tests-gate.ps1` (Stop, `stop_hook_active` guard) | no build step, no opt-out variable |
| Secrets (C2) | `home/hooks/guard-secrets.ps1` blocks secret **reads** | nothing blocks **writing** a secret into a file |
| Git guard | `home/hooks/git-guard.ps1` (uncommitted, see section 8) | none |
| Plan skill | `templates/dotnet/.claude/skills/plan-writing` (generic vertical-slice plan) | kept as is (user decision); superpowers `writing-plans` is the main flow |
| Review | `reviewer` agent, `code-reviewer` skill, `home/agents/security-reviewer` | none of them read REVIEW.md |
| Security policy | `rules/validation-authorization.md`, the `security-scanner` agent | no advisory skill with a check script |
| CI | `skills/azure-pipelines` (pipeline patterns) | no triage step, no evals |
| Bootstrap | `install.ps1` / `install.sh` link `home/` into `~/.claude`; `new-project.ps1` copies templates | no dry-run, no settings merge, no bash project installer |

**Convention found:** every hook is PowerShell (`.ps1`), ASCII-only and compatible with PS 5.1.
Hooks are registered in exec form: `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& \"$env:CLAUDE_PROJECT_DIR\\.claude\\hooks\\x.ps1\"; exit $LASTEXITCODE"`.
Because this convention exists, the rule "bash+jq only if there is no convention" means we
should **not** default to bash. Decision Q1: move everything to pwsh 7 (section 4).

**Tools on this machine:**
- present: Git Bash, dotnet, node/npx;
- missing: `jq`, `shellcheck`, `yamllint`;
- broken: Python (a Store stub).

## 2. Doc facts this plan relies on (verified)

**Hooks** (https://code.claude.com/docs/en/hooks):
- Events used: `PreToolUse`, `PostToolUse`, `Stop`.
- Handler keys used: `type: "command"`, `command`, `args`, `timeout`. `if` is documented; I do not plan to use it.
- stdin fields:
  - common: `cwd`, `permission_mode`, `hook_event_name`, `tool_name`, `tool_input.file_path`, `tool_input.command`;
  - Stop only: `stop_hook_active`.
- Exit codes:
  - exit 2 on PreToolUse blocks the call, and stderr goes to Claude;
  - exit 2 on Stop keeps Claude working;
  - exit 2 on PostToolUse only shows a warning, because the tool already ran.
- Matcher: a `|` list is an exact match, e.g. `Edit|Write`.
- `$CLAUDE_PROJECT_DIR`: in a worktree it points to the **main checkout**, so hooks must read `cwd` to find the worktree.
- Hooks may be declared in skill frontmatter (`hooks:`). They are registered when the skill is invoked and stay for the rest of the session. `once` is optional.

**Skill frontmatter** (https://code.claude.com/docs/en/skills):
- Fields used: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `allowed-tools`, `disable-model-invocation`, `hooks`, `paths`.
- `description` + `when_to_use` are capped at 1,536 characters.
- No frontmatter field switches the session into plan mode.

**Agent frontmatter** (https://code.claude.com/docs/en/sub-agents):
- Fields used: `name`, `description`, `tools`, `disallowedTools`, `model`, `permissionMode` (`plan` is allowed), `color`.
- Allowed colors: `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan`.

**Settings** (https://code.claude.com/docs/en/settings):
- Precedence, highest first: managed, CLI, `.claude/settings.local.json`, `.claude/settings.json`, `~/.claude/settings.json`.
- `permissions.allow`, `additionalDirectories`, `extraKnownMarketplaces` and most `env` values wait for workspace trust. `deny` and `ask` apply at once.

**Plugins** (https://code.claude.com/docs/en/plugin-marketplaces):
- Location: `.claude-plugin/marketplace.json`, with `name`, `owner` and `plugins[]` (`name`, `source`, `description`).
- Commands: `claude plugin validate`, `claude plugin marketplace add`, `claude plugin install x@market`.
- Plugin skills get a `plugin:` prefix.

Found while checking (fixed per Q12):
- **F1:** `color` values outside the documented list:
  - `teal`: `templates/dotnet/.claude/agents/qa.md:5`, `templates/blazor/.claude/agents/radzen-expert.md:5`
  - `gray`: `templates/dotnet/.claude/agents/docs-writer.md:5`
  - `magenta`: `templates/blazor/.claude/agents/uiux-designer.md:5`

## 3. File tree

N = new, C = changed, D = deleted.

```text
Claude-Kit/
├── plan.md                                        N  this file
├── bootstrap.ps1                                  N  F: -User / -Project, dry-run default (pwsh 7; runs on Linux too)
├── docs/ai-native-sdlc.md                         N  G
├── tests/hooks/                                   N  repo-only, never copied into projects
│   ├── run-hook-tests.ps1                         N  feeds fixtures to each hook, asserts exit + stderr
│   └── fixtures/<hook>/<case>.json                N  stdin payloads + expected exit code
├── home/settings.json                             C  hook commands: powershell.exe -> pwsh; protect-tests registered (Q5)
├── home/hooks/protect-tests.ps1                   N  C1, global (Q5)
├── home/hooks/*.ps1                               C  pwsh 7 compatible (still ASCII-only)
├── templates/sdlc/                                   project payload of the playbook
│   ├── REVIEW.md                                  N  A: 3 passes, Important vs Nit, max 5 nits, exclusions
│   ├── bands.yaml                                 N  A: 1 sigma log / 2 sigma diagnose / 3 sigma propose
│   ├── docs/sdlc/review.md                        D  replaced by the root REVIEW.md (Q3)
│   ├── .claude/settings.json                      N  C: registers C2-C4 (merged by bootstrap, Q6)
│   ├── .claude/protected-paths.txt                N  C3: globs (obj/, bin/, Migrations/*.Designer.cs, ...)
│   ├── .claude/hooks/block-secrets.ps1            N  C2 (writes; reads stay in guard-secrets)
│   ├── .claude/hooks/protected-paths.ps1          N  C3
│   ├── .claude/hooks/production-gate.ps1          N  C4 (RELEASE_APPROVAL)
│   ├── .claude/skills/bugfix-tdd/SKILL.md         N  B
│   ├── .claude/skills/dotnet-api-security/SKILL.md N B (+ scripts/check-endpoints.ps1)
│   ├── .claude/agents/verifier.md                 N  D (Bash, Read; report only)
│   ├── .claude/agents/researcher.md               N  D (read-only)
│   ├── evals/README.md                            N  E
│   ├── evals/example-*.json                       N  E (2 examples)
│   ├── evals/check.ps1                            N  E (pwsh on the ubuntu CI agent)
│   ├── ci/azure-pipelines/triage-failed-build.yml N  E
│   └── ci/azure-pipelines/agent-evals.yml         N  E
├── templates/dotnet/
│   ├── CLAUDE.md                                  C  A: + Verifying your work, Things Claude gets wrong
│   ├── .claude/settings.json                      C  hook commands: powershell.exe -> pwsh
│   ├── .claude/agents/qa.md, docs-writer.md       C  valid colors (Q12)
│   └── .claude/hooks/
│       ├── format-file.ps1                        C  C5: resolve cwd/worktree, still one file only
│       └── tests-gate.ps1                         C  C6: build + test, opt-out SDLC_SKIP_VERIFY=1
├── templates/blazor/.claude/agents/radzen-expert.md, uiux-designer.md  C  valid colors (Q12)
├── skills using docs/sdlc/review.md               C  review-pr keeps it only as a fallback for old projects
├── README.md                                      C  catalogue, bootstrap, SDLC section, pwsh 7 prerequisite
└── CHANGELOG.md                                   C  [Unreleased] entries
```

`install.ps1` / `install.sh` stay untouched (Q9). No new `.sh` files: every script is pwsh 7 (Q1).

## 4. Design notes per deliverable

**Shell (Q1).** All kit scripts target PowerShell 7 (`pwsh`), stay ASCII-only and are registered as
`pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& \"...\\x.ps1\"; exit $LASTEXITCODE"`. Windows needs
PowerShell 7 installed; on Linux `pwsh` runs the same files. Paths inside scripts use
`Join-Path` / `[IO.Path]`, never a hard-coded `\`.

**C1: protect-tests (global, Q5).**
- Registered in `home/settings.json`: PreToolUse on `Edit|Write|NotebookEdit`.
- Blocks edits to `*Tests*/**`, `*.Tests.cs`, `*Test.cs`, `*Tests.cs` unless `CLAUDE_ALLOW_TEST_EDITS=1`
  is set in the environment of the session. The user sets it when launching the session; an agent
  cannot flip it mid-session. No marker file.
- Approval path in stderr: "restart the session with CLAUDE_ALLOW_TEST_EDITS=1, or ask the user".

**C2: block-secrets.**
- Trigger: PreToolUse on `Edit|Write`.
- Scans `tool_input.content`, `new_string` and `edits[].new_string` for:
  - connection strings with `Password=`/`AccountKey=`;
  - `-----BEGIN .* PRIVATE KEY-----`;
  - AWS/Azure SAS/GitHub/ADO PAT patterns;
  - `"ClientSecret": "<non-placeholder>"`.
- Placeholders are allowed: `<...>`, `${...}`, `#{...}#`.
- Approval path: "use user-secrets / Key Vault / variable group".

**C3: protected-paths.** PreToolUse on `Edit|Write|NotebookEdit`. Reads the globs from `.claude/protected-paths.txt` in the repo root of `cwd`. The default list: `**/obj/**`, `**/bin/**`, `*.Designer.cs`, `**/Migrations/*.cs`, `*.g.cs`, `packages.lock.json`. Bash redirects are not covered; that is a known limitation, documented.

**C4: production-gate.**
- Trigger: PreToolUse on `Bash|PowerShell`.
- Blocks deploy-like commands that name a production target when `RELEASE_APPROVAL` is empty:
  - `az pipelines run|release`, `az webapp deploy|deployment`, `az functionapp deploy`, `az containerapp update`, `kubectl apply|rollout`, `helm upgrade`, `dotnet ef database update`;
  - production target: `prod|production|prd`.
- Patterns can be overridden in `.claude/production-gate.txt`.

**C5 / C6.**
- C5 formats only the changed `.cs` file.
- C6 runs `dotnet build` + `dotnet test` only when `.cs` files changed.
- C6 is skipped when `stop_hook_active`, when `SDLC_SKIP_VERIFY=1`, and in a subagent (`agent_id` present).
- C6 prints the failing lines to stderr and exits 2.

**Every blocking hook's stderr** carries the same three parts, in order:
- `BLOCKED by <hook>: <reason>`;
- `To proceed: <approval path>`;
- `Policy: <file>`.

**Skills.**
- `/feature [id]` (**done**, `home/skills/feature`): ADO work item via `az boards` -> branch per git-guard -> `superpowers:brainstorming` -> `writing-plans` -> execution -> draft PR via `commit-push-pr`. Replaces intent-capture, spec-from-intent and plan-from-spec.
- `bugfix-tdd`:
  - reproduce as a test and run it (it must fail for the expected reason);
  - commit the test;
  - fix without touching tests (protect-tests enforces this unless the session was started with `CLAUDE_ALLOW_TEST_EDITS=1`) and show the green run.
- `dotnet-api-security`: an example policy (auth on every endpoint except health, validation, audit, no PII in logs), linked to `rules/validation-authorization.md`, plus a read-only `check-endpoints.ps1` that greps for `AllowAnonymous` / unauthenticated `Map*` calls.

**REVIEW.md (Q3).** Lives in the project root. `review-pr` reads `REVIEW.md` first and falls back to
`docs/sdlc/review.md` for projects bootstrapped before this change.

**Agents (Q4).**
- `verifier`: `tools: Bash, Read`, `color: green`, report only; the playbook example adapted to `dotnet run` / `dotnet test`.
- `researcher`: `tools: Read, Grep, Glob, WebFetch`, `permissionMode: plan`.
- No `simplifier`: the dotnet template already enables pr-review-toolkit (its code-simplifier) and ships `refactoring-expert`.

**CI.** Pipelines are ADO YAML for `ubuntu-latest` (pwsh is preinstalled there).
- Claude CLI is installed with `npm install -g @anthropic-ai/claude-code`.
- `ANTHROPIC_API_KEY` comes from a variable group linked to Key Vault. The pipeline has no literal secrets.
- `triage-failed-build.yml`:
  - a job with `condition: failed()` runs `claude -p` over the build log;
  - it posts a PR thread through `POST {collectionUri}{project}/_apis/git/repositories/{repoId}/pullRequests/{prId}/threads` with `$(System.AccessToken)`;
  - the build service needs "Contribute to pull requests". I will state this in the README and verify the api-version against the ADO docs during stage E.
- `agent-evals.yml`: a schedule plus a PR trigger on `CLAUDE.md` and `.claude/**`. In ADO, path filters for PRs come from a branch policy, not YAML; this will be documented. It fails when the pass rate is under the threshold.

**Bootstrap (Q6, Q9).**
- `bootstrap.ps1 -Project <path> [-Template dotnet,sdlc] [-Apply] [-Force]`, plus `-User`.
- Dry-run unless `-Apply`; never overwrites a file without `-Force`.
- `.claude/settings.json` is **merged** into the existing one:
  - a timestamped backup (`settings.json.bak-<yyyyMMddHHmmss>`) is written before any change;
  - idempotent: a second `-Apply` produces no diff;
  - existing keys are never removed or overwritten;
  - `permissions.allow|deny|ask` and hook entries are unioned and de-duplicated;
  - dry-run prints the diff.
- `-User` wraps the existing `install.*` logic behind the same dry-run default; `install.*` stays untouched.

## 5. Rollout and stage order

Stages run C -> A -> B -> D -> F -> E -> G. I stop after each stage with a summary.

Verification after the stages:
- `tests/hooks/run-hook-tests.ps1`, including a proof that each hook blocks, with the real output;
- PSScriptAnalyzer (`Invoke-ScriptAnalyzer`) on every `.ps1`, plus the parse check and the ASCII check;
- JSON check with `ConvertFrom-Json`;
- YAML check with `npx js-yaml`;
- `bootstrap.ps1 -Project <scratchpad>/sdlc-smoke` in dry-run;
- a real `-Apply` into a scratch `dotnet new webapi` + `dotnet new xunit` solution, then a second `-Apply` to prove idempotence.

Until PowerShell 7 is installed here, scripts are tested under Windows PowerShell 5.1 for syntax
and behaviour; a pwsh run is repeated once `pwsh` is available.

## 6. Decisions (answered 2026-09-28)

- **Q1** 1a, fully on pwsh 7: scripts and `settings.json` hooks call `pwsh`, not `powershell.exe`. ASCII-only stays. Open: where the systemd workflow runs (plain Linux or WSL).
- **Q2** Layout of section 3 (`templates/sdlc/`, `tests/hooks/`, `docs/`).
- **Q3** Templates reworked to the playbook shape. `docs/sdlc/review.md` removed from the template; `REVIEW.md` in the project root; `review-pr` keeps the fallback.
- **Q4** 4a: no simplifier. `verifier` and `researcher` are created.
- **Q5** protect-tests registered globally, unlocked by `CLAUDE_ALLOW_TEST_EDITS=1` set at session launch. No marker file (an agent could create it). If a marker is ever added, deny Edit/Write on its path in `settings.json`.
- **Q6** Merge into the existing `.claude/settings.json`: backup, idempotent, never delete keys, union permission arrays, diff in dry-run.
- **Q7** Moot: plan-from-spec dropped; superpowers drives design and planning.
- **Q8** Moot: `/feature` reads work items with `az boards`, no MCP name needed.
- **Q9** 9a: new `bootstrap.ps1`; `install.*` untouched.
- **Q10** No jq/shellcheck. PSScriptAnalyzer for `.ps1`; `npx js-yaml` for YAML.
- **Q11** Knowledge-base additions are out of scope; separate task later.
- **Q12** Fix the 4 invalid agent colors.

## 7. Plugin + marketplace vs install script

The recommendation is to use the **install script (bootstrap) for the project payload now**, and to publish a **plugin later** for the portable parts.

Reasons for the script:
- Project hooks, `permissions` and `protected-paths.txt` must live in the project repo's `.claude/`. Only then are they reviewed like code and applied to everyone, including CI and the autonomous worktrees.
- The eval pipeline triggers on `.claude/**` changes, which only works when the config lives in the repo.
- CI YAML, REVIEW.md, bands.yaml and evals are repo files by nature. A plugin cannot place them.

What a plugin could carry later:
- A plugin fits the parts that are the same everywhere: `bugfix-tdd`, `verifier`, `researcher`.
- Updates flow through `claude plugin marketplace add` / `install`. Skills get a `plugin:` prefix.
- A private marketplace can be the Claude-Kit repo itself: `.claude-plugin/marketplace.json` + `plugins/sdlc/`.
- Do this after the skills have stabilised for a few weeks.

## 8. Risks

- **Worktrees:** `$CLAUDE_PROJECT_DIR` is the main checkout, so hook *scripts* run from main's `.claude/hooks`, not the worktree's. Every hook resolves data files from `cwd` instead.
- **Stop-hook cost:** C6 runs a full build+test on each stop with changed `.cs` files. Mitigations: the `stop_hook_active` guard, a skip in subagents, `SDLC_SKIP_VERIFY=1` for autonomous batch runs that verify in CI instead.
- **Secret regex:** there will be false positives and negatives. The hook is a guard rail. CI secret scanning (e.g. ADO Advanced Security) stays the control.
- **pwsh start-up** costs a few hundred ms per hook call. Several PreToolUse hooks on Edit add up, so I will consider one combined dispatcher.
- **pwsh missing:** after the switch, every hook fails on a machine without PowerShell 7. The README lists it as a prerequisite; `bootstrap.ps1` warns when `pwsh` is not on PATH.
- **protect-tests is global:** it also blocks test edits in normal feature work. Writing new tests needs `CLAUDE_ALLOW_TEST_EDITS=1` at launch. This is the chosen trade-off (Q5).
- **ADO REST:** api-version and permissions are to be verified in stage E against the ADO docs, not from memory.
