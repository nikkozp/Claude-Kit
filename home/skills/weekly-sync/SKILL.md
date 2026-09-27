---
name: weekly-sync
description: Brief of my last 7 days - commits, PRs, work items - to start the week with full context.
disable-model-invocation: true
allowed-tools: Bash(git log *) Bash(az repos pr list *) Bash(az boards query *)
---
## Commits (7 days)
!`git log --since="7 days ago" --author="$(git config user.email)" --oneline --no-merges`
## My PRs
!`az repos pr list --creator "$(git config user.email)" --status all --top 20 --query "[].{id:pullRequestId,status:status,title:title}" -o table`
## Assigned work items
!`az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM workitems WHERE [System.AssignedTo] = @Me AND [System.State] <> 'Closed' ORDER BY [System.ChangedDate] DESC" -o table`

Write a brief of at most 25 lines: what shipped, what is in review or blocked, what is next
by priority, risks. Offer to save it to `docs/weekly/<yyyy>-W<ww>.md`.
