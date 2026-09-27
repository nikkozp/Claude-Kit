---
name: commit-push-pr
description: Commit current changes, push the branch and open an Azure DevOps PR.
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(az repos pr create *) Bash(dotnet build *) Bash(dotnet test *)
arguments: [workitem]
---
## Current state
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Diff stat: !`git diff HEAD --stat`
- Recent commits: !`git log --oneline -5`

1. If on main/master: `git pull --ff-only` as its own command (stash first if the tree is dirty,
   `git stash pop` after), then `git switch -c feature/<short-name>` with no start point.
   Never branch from `origin/main` or with `--track`; git-guard blocks both.
2. Run `dotnet build -warnaserror` and the tests related to the change. If red, stop and report.
3. Stage only files related to this change. Never `git add .`.
4. Commit using Conventional Commits.
5. `git push -u origin HEAD`.
6. `az repos pr create --source-branch <branch> --target-branch main --title "<title>"
   --description "<summary + test plan>" --work-items $workitem` and return the PR URL.
   If no work item was given, omit `--work-items`.
