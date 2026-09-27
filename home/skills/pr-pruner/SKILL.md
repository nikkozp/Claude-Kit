---
name: pr-pruner
description: Find my stale Azure DevOps PRs, abandon stale drafts and report the rest.
disable-model-invocation: true
allowed-tools: Bash(az repos pr *) Bash(az devops invoke *) Bash(git fetch *) Bash(git log *)
---
## My active PRs
!`az repos pr list --creator "$(git config user.email)" --status active --query "[].{id:pullRequestId,draft:isDraft,created:creationDate,src:sourceRefName,title:title}" -o table`

For each PR, last activity = latest of: creation date, last commit on the source branch
(`git fetch` then `git log -1 --format=%cI origin/<branch>`), latest thread update.
- Draft with no activity for 30+ days -> `az repos pr update --id <id> --status abandoned`.
- Non-draft with no activity for 14+ days -> do NOT touch, add to the report with a suggestion.
- Otherwise skip.
Rules: at most 5 abandons per run.
End with a table: PR | last activity | action.
