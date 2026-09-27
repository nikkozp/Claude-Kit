---
name: fix-workitem
description: Implement an Azure Boards work item end to end - plan, tests first, fix, verify, draft PR.
disable-model-invocation: true
arguments: [id]
---
1. Run `az boards work-item show --id $id -o json` and read title, description and acceptance
   criteria. If acceptance criteria are missing or ambiguous, stop and list the questions.
2. Create the branch from the freshly pulled local main: `git switch main`, then
   `git pull --ff-only` as a separate command, then `git switch -c <type>/<task>_<short-description>`
   (no start point, never `origin/main`, never `--track`). `<type>` is `fix` for a Bug and
   `feature` otherwise; `<task>` is $id; e.g. `fix/12345_null-customer-name`.
3. Explore the relevant code (use an Explore subagent for broad search) and write a short plan:
   files, steps, how each step is verified.
4. Write failing tests for the acceptance criteria first and run them to see them red.
5. Implement until `dotnet build -warnaserror` and the tests are green. At most 3 fix
   iterations; then stop and report what is still red.
6. Read `~/.claude/skills/commit-push-pr/SKILL.md` and follow it with work item `$id`,
   but create the PR as a draft (`--draft true`).
End with: plan summary, tests added, PR URL.
