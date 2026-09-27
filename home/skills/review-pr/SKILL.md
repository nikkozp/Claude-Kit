---
name: review-pr
description: Review a teammate's Azure DevOps PR against the project review policy.
disable-model-invocation: true
context: fork
allowed-tools: Bash(az repos pr show *) Bash(git fetch *) Bash(git diff *) Bash(git log *) Read Grep Glob
arguments: [id]
---
1. `az repos pr show --id $id` to get source and target branches; fetch both.
2. Review `git diff origin/<target>...origin/<source>`.
3. If `REVIEW.md` exists in the repo root, follow it; else if `docs/sdlc/review.md` exists,
   follow that; otherwise flag only correctness, security, data safety and missing tests.
4. Do not post anything to the PR.
When run in a loop: if the source branch has no new commits since the previous run,
answer "No new commits" and stop.
End with a table | Severity | File:line | Issue | Suggested fix | and a one-line verdict:
approve or request changes.
