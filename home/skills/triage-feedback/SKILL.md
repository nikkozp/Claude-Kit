---
name: triage-feedback
description: Turn Azure Boards work items tagged claude-ready into draft PRs.
disable-model-invocation: true
allowed-tools: Bash(az boards *) Bash(az repos *) Bash(git *) Bash(dotnet build *) Bash(dotnet test *) Read Edit Write Grep Glob
---
Run only in a dedicated worktree session (`claude --worktree`).

## Ready items
!`az boards query --wiql "SELECT [System.Id], [System.Title] FROM workitems WHERE [System.Tags] CONTAINS 'claude-ready' AND [System.State] <> 'Closed' AND [System.State] <> 'Done' ORDER BY [System.ChangedDate] DESC" -o table`

Take at most 2 items per run. For each:
1. Read `~/.claude/skills/fix-workitem/SKILL.md` and follow it for this item.
2. On success: `az boards work-item update --id <id> --discussion "Draft PR: <url>"` and replace
   tag `claude-ready` with `claude-pr` (read the current System.Tags and rewrite the list).
3. If the item is unclear or too large: add a discussion comment with what is missing, replace
   the tag with `claude-needs-info` and move on.
No ready items -> answer "Queue empty" and stop.
End with a table: item | result | PR.
