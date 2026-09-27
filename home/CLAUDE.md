# Global instructions

## Accuracy
- Never invent APIs, methods, packages or config keys. If unsure, look it up in the code
  (Grep, LSP) or in library docs via Context7 first, then write.
- Before using a NuGet package, check it is referenced in the *.csproj; add new packages
  only after my confirmation.
- Never claim something works without evidence: show `dotnet build` / `dotnet test`
  output, or the command you ran and its result.
- When referring to a file or symbol, cite the path and line you actually read.
- If a requirement is ambiguous, ask one clarifying question instead of assuming.
- If a fix fails twice, stop and summarize what is known and what is not.

## Code comments
Comments rot and duplicate the code, so the default is NO comment.
- Write a comment only for the non-obvious WHY: a constraint, a workaround,
  a business rule, a link to an issue. Never for WHAT the code does.
- Never narrate your edits ("Added", "Changed", "Now", "Updated", "Fixed")
  and never reference the task, the plan or this conversation.
- No commented-out code. Git keeps history.
- XML docs (///) only on public API of library projects, one line if enough.
  No XML docs on private/internal members or in test projects.
- Keep existing comments unless they became wrong.

Bad:  // Added null check to prevent exception
      if (order is null) return;
Good: // SAP sends empty orders on retries; they must be ignored, not rejected (BIL-412)
      if (order is null) return;

## Git
Commit and push are allowed; `~/.claude/hooks/git-guard.ps1` enforces the rules below.
- New work: `git switch main`, then `git pull --ff-only` as a separate command, then
  `git switch -c <type>/<task>_<short-description>` (no start point, never `origin/main`,
  never `--track`). `<type>` is `feature`, `fix` or `chore`; `<task>` is the work item id
  (`12345`), the Jira key (`ABC-123`) or `NO-TASK`; the description is lower-case kebab-case.
  Example: `feature/12345_order-export`.
- First push `git push -u origin HEAD`. Never push to main/master/the default branch.
- No force of any kind (push -f/--force-with-lease, switch -C, checkout -B, branch -f).
  To catch up with main: `git fetch origin` + `git merge origin/main`, not rebase.
- Review `git diff --staged` before committing; stage explicit paths.

## Compact Instructions
When compacting, keep the task goal, changed files, decisions made and open questions.
Drop test and log output.
