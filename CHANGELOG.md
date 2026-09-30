# Changelog

All notable changes to this kit are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the kit uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html):

- **MAJOR**: breaking change to install layout, template paths or skill names that other files call.
- **MINOR**: new skill, agent, rule, template or script.
- **PATCH**: wording fixes and tweaks inside existing files.

## [Unreleased]

### Added
- `home/hooks/git-guard.ps1`, a global PreToolUse hook for `Bash`/`PowerShell`. It blocks pushes to
  protected branches, force of any kind, branches not created from the freshly pulled local main,
  `--track`/`origin/*` start points, and upstreams pointing at a protected branch.
  Extra protected branches can be listed in `CLAUDE_GIT_PROTECTED`.
- `git-guard` enforces branch names `<feature|fix|chore>/<task>_<short-description>`, where the
  task is a work item id, a Jira key or `NO-TASK`, on create and `branch -m`, and blocks `branch -M`.
  `CLAUDE_GIT_BRANCH_PATTERN` overrides the regex.
- Loop commands for Azure DevOps: `post-merge-sweeper`, `pr-pruner`, `fix-workitem`,
  `triage-feedback`, `test-and-fix`, `flaky`, `review-pr`, `weekly-sync`, and a "Loops" README section.
- `feature` command: Azure Boards work item (or a description) -> branch -> superpowers
  brainstorming, plan and execution -> draft PR.

### Changed
- Git policy: Claude may now commit and push feature branches. `git-operations` rule, `workflow`
  rule, all agents, `home/CLAUDE.md` and the README describe the enforced flow.
- `home/settings.json` and the dotnet template allow git add/commit/fetch/pull/switch/merge/push
  without a prompt; the hook does the policing.
- `babysit` catches up with `git merge origin/<target>` and a normal push instead of rebase plus
  `--force-with-lease`.
- `commit-push-pr` pulls main as a separate step before creating the feature branch.

### Removed
- `templates/sdlc` intent / spec / plan templates. The superpowers plugin owns design and planning
  (`docs/superpowers/specs`, `docs/superpowers/plans`); `templates/sdlc` keeps only the review policy.

## [1.0.0] - 2026-09-27

### Added
- `home/`: global Claude Code config, linked into `~/.claude` by `install.ps1` / `install.sh`.
  - `settings.json`: model, permissions (secrets deny list, ask-before-push), hooks, plugins, env.
  - `CLAUDE.md`: global accuracy and code-comment rules.
  - Skills: `ship`, `commit-push-pr`, `babysit`, `grill`, `techdebt`, `decomment`, `wrap-up`, `skill-map`.
  - Agent: `security-reviewer`.
  - Hooks: `guard-secrets.ps1` (enabled), `comment-guard.ps1` (optional).
  - Script: `skill-map.ps1`.
- `templates/dotnet`: project settings, format and tests-gate hooks, `CLAUDE.md` skeleton, plus a
  reusable library:
  - Rules: `architecture`, `code-style`, `docker`, `git-operations`, `migrations`, `testing`,
    `validation-authorization`, `workflow`.
  - Skills: `azure-pipelines`, `code-reviewer`, `csharp-pro`, `database-optimizer`,
    `ddd-strategic-design`, `logging`, `plan-writing`, `sql-server-best-practices`.
  - Agents: `ba`, `dba`, `ddd-architect`, `debugger`, `developer`, `devil`, `devops`, `docs-writer`,
    `integration-architect`, `qa`, `refactoring-expert`, `reviewer`, `security-scanner`, `tester`.
- `templates/blazor`: an add-on for Blazor UI projects.
  - Rule: `blazor`.
  - Skills: `blazor-server-gotchas`, `playwright-dotnet`, `uiux-design-system`.
  - Agents: `blazor-expert`, `uiux-designer`, `radzen-expert`.
- `templates/sdlc`: intent / spec / plan templates and the review policy.
- `templates/knowledge`: skeleton for a `raw/` + `wiki/` knowledge base.
- `new-project.ps1`: applies one or more templates in one call (`-Template dotnet,blazor`).
- `mcp.ps1`: commented examples of user-scope MCP servers.
- `VERSION` file and this changelog.
