---
name: post-merge-sweeper
description: Collect review comments left on my recently merged Azure DevOps PRs and address them in one follow-up PR.
disable-model-invocation: true
allowed-tools: Bash(az repos *) Bash(az devops invoke *) Bash(git *) Bash(dotnet build *) Bash(dotnet test *) Read Edit Grep Glob
---
Run only in a dedicated worktree session (`claude --worktree`).

## My PRs merged in the last 7 days
!`az repos pr list --creator "$(git config user.email)" --status completed --top 20 --query "[?closedDate >= '$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)'].{id:pullRequestId,title:title,closed:closedDate}" -o table`

1. Resolve project and repository id once from `git remote get-url origin` and `az repos show`.
2. For each PR fetch threads: `az devops invoke --area git --resource pullRequestThreads
   --route-parameters project=<p> repositoryId=<r> pullRequestId=<id>`. Keep threads that are
   still active or were created after the PR was closed.
3. Classify each: actionable change / question / already handled. Questions and anything that
   needs a design decision go to the report, not to code.
4. No actionable items -> answer "Nothing to sweep" and stop.
5. Create the branch from the freshly pulled local main: `git switch main`, then
   `git pull --ff-only` as a separate command, then `git switch -c chore/post-merge-sweep-<yyyymmdd>`
   (no start point, never `origin/main`, never `--track`). Implement the items;
   `dotnet build -warnaserror` and related tests must be green.
6. Read `~/.claude/skills/commit-push-pr/SKILL.md` and follow it. PR title
   "chore: post-merge review follow-ups"; the description links every source thread.
Rules: at most 10 items per run; never push to main.
End with a table: PR | thread | action | needs my attention.
