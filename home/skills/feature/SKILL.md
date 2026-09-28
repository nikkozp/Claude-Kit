---
name: feature
description: Start a feature from an Azure Boards work item (or a short description) - branch, then the superpowers design, plan and execution flow, then a draft PR.
disable-model-invocation: true
arguments: [id]
argument-hint: [ADO work item id]
---
1. If $id is given, run `az boards work-item show --id $id -o json` and read title, description
   and acceptance criteria. Without an id, ask the user for a one-paragraph description and use
   `NO-TASK` as the task.
2. Create the branch from the freshly pulled local main: `git switch main`, then
   `git pull --ff-only` as a separate command, then `git switch -c <type>/<task>_<short-description>`
   (no start point, never `origin/main`, never `--track`). `<type>` is `fix` for a Bug and
   `feature` otherwise; `<task>` is $id or `NO-TASK`; e.g. `feature/12345_order-export`.
3. Invoke the `superpowers:brainstorming` skill with the work item text as the starting intent.
   The branch already exists: do not create another branch or a worktree.
4. Follow the superpowers flow: brainstorming -> `superpowers:writing-plans` -> execution.
   The work item's acceptance criteria are the plan's definition of done.
5. When superpowers offers to finish the branch, do not merge locally. Read
   `~/.claude/skills/commit-push-pr/SKILL.md` and follow it with work item $id (no work item for
   `NO-TASK`), creating the PR as a draft (`--draft true`).
End with: design doc path, plan path, PR URL.
