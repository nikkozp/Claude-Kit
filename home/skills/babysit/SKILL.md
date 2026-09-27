---
name: babysit
description: Keep my open Azure DevOps PRs healthy - address review comments, rebase, fix failing CI.
disable-model-invocation: true
allowed-tools: Bash(az repos pr *) Bash(az devops invoke *) Bash(git fetch *) Bash(git checkout *)
  Bash(git merge *) Bash(git commit *) Bash(git push *) Bash(dotnet build *) Bash(dotnet test *)
  Read Edit Grep Glob
---
Run this only in a dedicated worktree session (`claude --worktree`), never in my working copy.

## My active PRs
!`az repos pr list --creator "$(git config user.email)" --status active --query "[].{id:pullRequestId,src:sourceRefName,title:title}" -o table`

For each PR, in order:
1. Policies: `az repos pr policy list --id <id>`. If the build policy failed, read the failure,
   fix it on the PR branch, verify locally with dotnet build/test.
2. If the branch is behind target: `git fetch origin`, `git merge origin/<target>`, rerun tests,
   then a normal `git push`. Never rebase a pushed branch and never force push (git-guard blocks it).
3. Active review threads (REST via `az devops invoke --area git --resource pullRequestThreads`):
   - clear change request -> implement it and reply in the thread with what changed;
   - question or disagreement -> do NOT change code, add it to the report for me.

Rules: never push to the target branch; at most 3 PRs per run; if tests stay red after
one fix attempt, stop on that PR and report.
End with a table: PR | action taken | needs my attention.
