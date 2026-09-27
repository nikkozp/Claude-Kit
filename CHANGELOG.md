# Changelog

All notable changes to this kit are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the kit uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html):

- **MAJOR**: breaking change to install layout, template paths or skill names that other files call.
- **MINOR**: new skill, agent, rule, template or script.
- **PATCH**: wording fixes and tweaks inside existing files.

## [Unreleased]

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
